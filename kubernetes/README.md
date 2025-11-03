# Кейс по переносу инфраструктуры с нескольких хостов, где сервисы работали через Docker-compose на кубер
В одной из компаний мне поступила задача по переносу приложений с серверов, на которых хостились сервисы, работающией на одной платформе. Вводные были не сильно большие, к тому же - пришлось переписывать образы для корректной работы сервисов в кластере кубернетиса 

Основным перимуществом переноса оказалась отказоустойчивость кубера в сравнениии с обычными серверами, экономия денег (теперь компания тратит на 25% меньше денег на инфру), а так же - возможность во-многом если не автоматизировать, то ускорить деплой сервисов для новых клиентов с 1 часа до 5 минут. Ниже будет представлен небольшой родмап, каким образом это было реализовано:

## Процесс работы

```bash
#!/bin/bash
set -e

### === НАСТРОЙКИ === ###
NAMESPACE="example" # Не использовать точки и нижние подчёркивания
APP_IMAGE="repo/srv:app_for_kube"
BOT_IMAGE="repo/srv:bot_app_for_kube"
FRONT_IMAGE="repo/srv:app_webserver_for_kube"
DOMAIN="example-bot.ru"
TLS_NAME="example-bot-ru" # Вводить данные без точек и нижных подчёркиваний, развделение слов - через "-"

### === Данные для env для bot_app === ###
BOT_TZ="Europe/Moscow"
BOT_db_name="name"
BOT_db_user_name="user"
BOT_db_password="pass"
BOT_db_host=x.x.x.x
BOT_db_port=5432
BOT_jwt_auth_key="key"
BOT_rmq_host=y.y.y.y
BOT_rmq_port=5672
BOT_rmq_user="user"
BOT_rmq_pass="pass"
BOT_rmq_vhost="vh"
BOT_rmq_exchanger="exchanger"
BOT_rmq_receiver_queue="bot_receiver_queue"
BOT_TOKEN="xxxx:yyy"
BOT_chatgpt_auth_data="sk-proj-xxxxxx"
BOT_ADMIN_PASS="xxx"

### === Данные для env app === ###
APP_TZ="Europe/Moscow"
APP_db_name="name"
APP_db_user_name="user"             
APP_db_password="pass"
APP_db_host=x.x.x.x
APP_db_port=5432
APP_ADMIN_PASS="xxx"
APP_jwt_auth_key="key"
APP_rmq_host=y.y.y.y
APP_rmq_port=5672
APP_rmq_user="user"
APP_rmq_pass="pass"
APP_rmq_vhost="vh"
APP_rmq_exchanger="exchanger"
APP_rmq_receiver_queue="receiver_queue"

# Данные для секретов
WORKDIR="/root/kube_manifest/$NAMESPACE"
SECRET_NAME="regcred"
DOCKER_SERVER="https://index.docker.io/v1/"
DOCKER_USERNAME="username"
DOCKER_PASSWORD="pass"
DOCKER_EMAIL="example@gmail.com"

### === СОЗДАНИЕ ДИРЕКТОРИИ === ###
echo "Проверка пути $WORKDIR..."
mkdir -p "$WORKDIR"
cd "$WORKDIR"

### === СОЗДАНИЕ NAMESPACE === ###
echo "Проверка namespace..."
if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
  cat > namespace.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
EOF
  kubectl apply -f namespace.yaml
else
  echo "Namespace $NAMESPACE уже существует"
fi

### === ПРОВЕРКА И (ПЕРЕ)СОЗДАНИЕ СЕКРЕТА === ###
if kubectl -n "$NAMESPACE" get secret "$SECRET_NAME" &>/dev/null; then
  echo "Secret $SECRET_NAME уже существует — пересоздаю..."
  kubectl -n "$NAMESPACE" delete secret "$SECRET_NAME" --ignore-not-found
fi

echo "Создание Docker Registry секрета..."
kubectl create secret docker-registry "$SECRET_NAME" \
  --namespace="$NAMESPACE" \
  --docker-server="$DOCKER_SERVER" \
  --docker-username="$DOCKER_USERNAME" \
  --docker-password="$DOCKER_PASSWORD" \
  --docker-email="$DOCKER_EMAIL"

if [ $? -eq 0 ]; then
  echo "Secret $SECRET_NAME успешно создан в namespace $NAMESPACE"
  echo
  echo "Проверка содержимого секрета:"
  kubectl -n "$NAMESPACE" get secret "$SECRET_NAME" -o yaml | grep -A2 ".dockerconfigjson"
else
  echo "Ошибка при создании секрета $SECRET_NAME"
  exit 1
fi

# ### === ГЕНЕРАЦИЯ ФАЙЛОВ === ###

# ingress.yaml

cat > ingress-app.yaml <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-ingress
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/proxy-body-size: "100m"
spec:
  tls:
  - hosts:
    - $DOMAIN
    secretName: $TLS_NAME
  rules:
  - host: $DOMAIN
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service-$NAMESPACE
            port:
              number: 80
EOF

# redis.yaml
cat > redis.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        command: ["redis-server", "--appendonly", "yes", "--replica-read-only", "no"]
        volumeMounts:
        - name: redis-data
          mountPath: /data
      volumes:
      - name: redis-data
        emptyDir: {} # можно заменить на PVC, если хочешь постоянство данных
---
apiVersion: v1
kind: Service
metadata:
  name: redis-service-$NAMESPACE
  namespace: $NAMESPACE
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
EOF

# deployment-app.yaml
cat > deployment-app.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: universal-app
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: universal-app
  template:
    metadata:
      labels:
        app: universal-app
    spec:
      imagePullSecrets:
        - name: regcred
      containers:
        - name: universal-app
          image: $APP_IMAGE
          command: ["/bin/sh", "/app/entrypoint.sh"]
          imagePullPolicy: Always
          env:
            - name: TZ
              value: "$APP_TZ"
            - name: db_name
              value: "$APP_db_name"
            - name: db_user_name
              value: "$APP_db_user_name"
            - name: db_password
              value: "$APP_db_password"
            - name: db_host
              value: "$APP_db_host"
            - name: db_port
              value: "$APP_db_port"
            - name: ADMIN_PASS
              value: "$APP_ADMIN_PASS"
            - name: jwt_auth_key
              value: "$APP_jwt_auth_key"
            - name: rmq_host
              value: "$APP_rmq_host"
            - name: rmq_port
              value: "$APP_rmq_port"
            - name: rmq_user
              value: "$APP_rmq_user"
            - name: rmq_pass
              value: "$APP_rmq_pass"
            - name: rmq_vhost
              value: "$APP_rmq_vhost"
            - name: rmq_exchanger
              value: "$APP_rmq_exchanger"
            - name: rmq_receiver_queue
              value: "$APP_rmq_receiver_queue"
            - name: REDIS_HOST
              value: "redis-service-$NAMESPACE"
            - name: REDIS_PORT
              value: "6379"
          ports:
            - containerPort: 5777
          volumeMounts:
          - name: logs-volume
            mountPath: /app/logs

      volumes:
        - name: logs-volume
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: universalapp-service-$NAMESPACE
  namespace: $NAMESPACE
spec:
  selector:
    app: universal-app
  ports:
    - port: 5777
      targetPort: 5777
EOF

# deployment-bot.yaml
cat > deployment-bot.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: universalbot-app
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: universalbot-app
  template:
    metadata:
      labels:
        app: universalbot-app
    spec:
      imagePullSecrets:
        - name: regcred
      containers:
        - name: universalbot-app
          image: $BOT_IMAGE
          imagePullPolicy: Always
          command: ["/bin/sh", "/app/entrypoint.sh"]
          env:
            - name: TZ
              value: "$BOT_TZ"
            - name: db_name
              value: "$BOT_db_name"
            - name: db_user_name
              value: "$BOT_db_user_name"
            - name: db_password
              value: "$BOT_db_password"
            - name: db_host
              value: "$BOT_db_host"
            - name: db_port
              value: "$BOT_db_port"
            - name: jwt_auth_key
              value: "$BOT_jwt_auth_key"
            - name: rmq_host
              value: "$BOT_rmq_host"
            - name: rmq_port
              value: "$BOT_rmq_port"
            - name: rmq_user
              value: "$BOT_rmq_user"
            - name: rmq_pass
              value: "$BOT_rmq_pass"
            - name: rmq_vhost
              value: "$BOT_rmq_vhost"
            - name: rmq_exchanger
              value: "$BOT_rmq_exchanger"
            - name: rmq_receiver_queue
              value: "$BOT_rmq_receiver_queue"
            - name: TOKEN
              value: "$BOT_TOKEN"
            - name: chatgpt_auth_data
              value: "$BOT_chatgpt_auth_data"
            - name: ADMIN_PASS
              value: "$BOT_ADMIN_PASS"
          ports:
            - containerPort: 7777
          #command: ["/bin/sh", "/app/entrypoint.sh"]
          volumeMounts:
            - name: logs-volume
              mountPath: /app/logs
      volumes:
        - name: logs-volume
          emptyDir: {} 
---
apiVersion: v1
kind: Service
metadata:
  name: universalbot-service-$NAMESPACE
  namespace: $NAMESPACE
spec:
  selector:
    app: universalbot-app
  ports:
    - port: 7777
      targetPort: 7777

EOF

# deployment-frontend.yaml
cat > deployment-frontend.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      imagePullSecrets:
        - name: regcred
      containers:
      - name: frontend
        image: $FRONT_IMAGE
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d
          readOnly: true
      volumes:
      - name: nginx-config
        configMap:
          name: frontend-nginx-config    
    

---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service-$NAMESPACE
  namespace: $NAMESPACE
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
EOF

# === Создание ConfigMap из шаблона ===
echo "Генерация configmap-frontend-nginx.yaml для $NAMESPACE..."

SRC_TEMPLATE="/root/kube_manifest/past-example/configmap-frontend-nginx.yaml"
TARGET_DIR="/root/kube_manifest/$NAMESPACE"
TARGET_FILE="$TARGET_DIR/configmap-frontend-nginx.yaml"

# Проверим, что исходник существует
if [[ ! -f "$SRC_TEMPLATE" ]]; then
  echo "Ошибка: шаблон $SRC_TEMPLATE не найден!"
  exit 1
fi

# Копируем и заменяем имя namespace везде внутри файла
cp "$SRC_TEMPLATE" "$TARGET_FILE"
sed -i "s/past-example/$NAMESPACE/g" "$TARGET_FILE"

# Проверим, подставился ли неймспейс
if grep -q "$NAMESPACE" "$TARGET_FILE"; then
  echo "ConfigMap успешно подготовлен: $TARGET_FILE"
else
  echo "Предупреждение: неймспейс не был заменён — проверь исходный шаблон."
fi
```
