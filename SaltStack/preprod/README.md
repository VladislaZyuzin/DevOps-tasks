# Поднятие K3S и Docker Swarm через Salt-Stack 
> Объяснение, как настраивается Salt-Stack ("соль" - по-церковнославянски) можно подчерпнуть отсюда: [Настройка Salt-Stack](https://github.com/VladislaZyuzin/DevOps-tasks/tree/main/SaltStack/kube_swarm_salt)

## ТЗ 
1. Настроить Docker-Swarm на одной ноде
2. Настроить K3S или K8S на 2 и болеее нодах
3. Задеплоить сервисы для тестирования

## Начало работы

Для того, чтобы всё корректно завелось - я воспользовался сервером компании и создал через Proxmox 7 ВМ: 

<img width="741" height="312" alt="image" src="https://github.com/user-attachments/assets/10e57994-1a50-435a-9f6d-ee3203fa6b57" />

Особое внимание стоит уделить на: 
1. Первый столбикк (VMID) - это номер ВМ в проксмоксе, чтобы можно было логически их связать
2. Предпоследний столбик - тут оперативка в мб
3. Последний - тут основная память в гб

Для работы я использовал дистрибутивы **12_ubuntu-24.04.3-live-server-amd64.iso**. На эту версию спокойно устанавливается соль, которую я настраивал в прошлой статьте через boorstrap. В ютубе есть множество видно о том, как устанавливается серверная убунта, так что дерзайте :)

Не буду долно рассказывать про сеть - основная подсеть для проектов у меня 10.70.8.0/23
* Шлюз - оканчивается на 1
* Salt-master - на 10
* salt-swarm - на 20
* salt-k8s-master - на 30
* salt-k8s-worker1 - на 31
* salt-k8s-worker2 - на 32
* salt-k3s-master - на 40
* salt-k3s-worker - на 41

Далее - я настроил salt и salt-ssh (в дальнейщем - он не пригодился :( ) на всех вм. Прописал roster. В папках с конфигами будет всё необходимое. Перейдём же к настройке остальный сервисов

## Docker-Swarm
Для настройки сворма было использовано, в целом, всё то же, что и на `wsl`, были немного изменены конфиги и команды вызова. Из хорошей практики - был настроен пиллар. Вот как всё выглядит в `/srv/pillar/swarm.sls`

```yaml 
swarm:
  advertise_addr: 10.70.8.20

  interface: eth0
  port: 2377
  data_path_addr: 10.70.8.20

  # Настройки для токенов
  token_dir: /etc/docker/swarm
```

Таким образом выглядит top.sls в этой же папке, в нему потом ещё вернёмся: 

```yaml
base:
  'salt-k8s-worker*':
    - k3s

  'roles:swarm-master':
    - match: grain
    - swarm

  'roles:k3s-check-node':
    - match: grain
    - k3s
```

Далее - обновим пиллары: 

```bash
salt 'salt-swarm' saltutil.refresh_pillar
```
Проверим, что отобразились: 

```bash
salt -G 'roles:swarm-master' pillar.items
```

Если вывод примерно такой, то всё ок: 

<img width="895" height="365" alt="image" src="https://github.com/user-attachments/assets/be7278bf-c3bf-4bef-881b-cdcc4f5cae61" />

После - пропишем конфигурации для init.sls и master.sls, так как сворм у нас однонодный, то нода одновременно будет и менеджером и воркером: 

Пример: `/srv/salt/base/swarm/init.sls`

```yaml
add_docker_gpg_key:
  cmd.run:
    - name: curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    - unless: test -f /usr/share/keyrings/docker-archive-keyring.gpg

add_docker_repo:
  cmd.run:
    - name: echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
    - unless: test -f /etc/apt/sources.list.d/docker.list

update_apt:
  cmd.run:
    - name: apt-get update

install_docker:
  pkg.installed:
    - pkgs:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-buildx-plugin
      - docker-compose-plugin

docker_service:
  service.running:
    - name: docker
    - enable: True

add_root_to_docker:
  group.present:
    - name: docker
    - addusers:
      - root
```

Пример /srv/salt/base/swarm/master.sls:

```yaml
init_swarm:
  cmd.run:
    - name: docker swarm init --advertise-addr {{ pillar['swarm']['advertise_addr'] }}
    - unless: "docker info | grep -q 'Swarm: active'"
```

Не забываем про top.sls, он для всех инсталляций `/srv/salt/base/top.sls`:

```yaml
base:
  'roles:swarm-master':
    - match: grain
    - swarm.init
    - swarm.master
    - swarm.stack

  'roles:k3s-master':
    - match: grain
    - k3s.init
    - k3s.master

  'roles:k3s-node':
    - match: grain
    - k3s.init
    - k3s.worker

  'roles:k3s-check-master':
    - match: grain
    - k3s.init
    - k3s.master

  'roles:k3s-check-node':
    - match: grain
    - k3s.init
    - k3s.worker
```

После чего - применяем конфигурцаии одну за одной

```bash
salt 'salt-swarm' state.apply swarm.init

# Проверим, всё ли ок

salt 'salt-swarm' state.apply swarm.master
```
Должно быть примерно так: 

<img width="931" height="601" alt="image" src="https://github.com/user-attachments/assets/36021a70-4362-40fa-bf00-ffea61791781" />

При положительном выводе - проверяем ноды на сворме: 

```bash
salt 'salt-swarm' cmd.run 'docker node ls'
```

### Тестирование интсалляций
После этого - я решил проверить, как будут происходить инсталляции сервисов, для этого - я прописал следующий `/srv/salt/base/swarm/stack.sls`: 

```yaml
/root/configs:
  file.directory:
    - name: /root/configs
    - user: root
    - group: root
    - mode: 700

{% set stack_file = '/root/configs/mystack.yml' %}

mystack_yaml:
  file.managed:
    - name: {{ stack_file }}
    - contents: |
        version: '3.9'

        services:
          postgres:
            image: postgres:15
            environment:
              POSTGRES_USER: user
              POSTGRES_PASSWORD: password
              POSTGRES_DB: db
            ports:
              - "5432:5432"
            volumes:
              - pgdata:/var/lib/postgresql/data
            deploy:
              replicas: 1
              restart_policy:
                condition: on-failure

          redis:
            image: redis:7
            ports:
              - "6379:6379"
            deploy:
              replicas: 1
              restart_policy:
                condition: on-failure

          nginx:
            image: nginx:1.25
            ports:
              - "8080:80"
            deploy:
              replicas: 1
              restart_policy:
                condition: on-failure

        volumes:
          pgdata:
    - user: root
    - group: root
    - mode: 644

deploy_mystack:
  cmd.run:
    - name: docker stack deploy -c {{ stack_file }} mystack
    - unless: docker stack ls | grep -q mystack
```

На будущее - правильный вариает - всё переносить в pillars. Применим конфиг: 

```bash
salt -G 'roles:swarm-master' state.apply swarm.stack
```

Для того, чтобы проверить, что всё окей: 

```bash 
salt -G 'roles:swarm-master' cmd.run 'docker service ls'
```

Такой, примерно, будет вывод: 

<img width="925" height="274" alt="image" src="https://github.com/user-attachments/assets/46fd1b06-dcda-4fe6-8ae1-24c55ce92b8c" />

Значит - swarm - рабочий, перейдём к кубу

## Настройка K3S на нодах через соль

На всякий случай - я сделал 2 кластера для проверки жизнеспособности конфигов. Рассмотрим тот, который я обозвал k3s, на нём 1 мастер и один воркер. Прежде всего прописываем `/srv/salt/base/k3s/init.sls`:

```yaml
# /srv/salt/base/k3s/init.sls
install_dependencies:
  pkg.installed:
    - pkgs:
      - curl
      - socat
      - iptables
      - conntrack
      - bash
      - ca-certificates

disable_swap:
  cmd.run:
    - name: swapoff -a
    - unless: free | awk '/Swap/ {print $2}' | grep -q '^0$'

create_k3s_lv:
  cmd.run:
    - name: lvcreate -L 15G -n k3s-lv ubuntu-vg  # ВНИМАТЕЛЬНО С ЭТОЙ СТРОКОЙ, ПОСМОТРИ ЧЕРЕЗ lsblk и df -h ПАМЯТЬ НА ТАРГЕТ СЕРВЕРЕ
    - unless: lvdisplay /dev/ubuntu-vg/k3s-lv
    - require:
      - pkg: install_dependencies

format_k3s_btrfs:
  cmd.run:
    - name: mkfs.btrfs -f /dev/ubuntu-vg/k3s-lv
    - unless: blkid /dev/ubuntu-vg/k3s-lv | grep btrfs
    - require:
      - cmd: create_k3s_lv

create_k3s_subvolume:
  cmd.run:
    - name: |
        mount /dev/ubuntu-vg/k3s-lv /mnt
        if [ ! -d /mnt/@k3s ]; then btrfs subvolume create /mnt/@k3s; fi
        umount /mnt
    - unless: btrfs subvolume list /mnt 2>/dev/null | grep -q '@k3s'
    - require:
      - cmd: format_k3s_btrfs

# ensure directories
/var/lib/rancher/k3s:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

/etc/rancher/k3s:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

# Create a systemd mount unit to ensure the storage mount happens BEFORE k3s
/etc/systemd/system/var-lib-rancher-k3s.mount:
  file.managed:
    - contents: |
        [Unit]
        Description=Mount for /var/lib/rancher/k3s
        # RequiredBy will ensure k3s waits for mount
        [Install]
        WantedBy=multi-user.target
        [Mount]
        What=/dev/ubuntu-vg/k3s-lv
        Where=/var/lib/rancher/k3s
        Type=btrfs
        Options=subvol=/@k3s
    - mode: '644'
    - user: root
    - group: root
    - require:
      - cmd: create_k3s_subvolume

# reload systemd if unit changed
systemd-daemon-reload:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: /etc/systemd/system/var-lib-rancher-k3s.mount

# Correct mount handling!
mount-k3s:
  mount.mounted:
    - name: /var/lib/rancher/k3s
    - device: /dev/ubuntu-vg/k3s-lv
    - fstype: btrfs
    - options: subvol=/@k3s
    - mkmnt: False
    - persist: True
    - require:
      - file: /etc/systemd/system/var-lib-rancher-k3s.mount
      - cmd: systemd-daemon-reload

# systemd mount unit сервис
var-lib-rancher-k3s.mount:
  service.running:
    - enable: true
    - require:
      - mount: mount-k3s
```

Тут я создаю btrfs файловую систему и монтирую в неё часть памяти, так же - прописываю во всё это systemd юнит для работы файловой системы, а так же настраиваю диру /var/lib/rancher/k3s для хранения данных состояния для нод. Так же - прописываем конфиг мастера `/srv/salt/base/k3s/master.sls`: 

```yaml
# /srv/salt/base/k3s/master.sls
# Ensure init ran
include:
  - k3s.init

# Создание директории ~/.kube
.kube_dir:
  file.directory:
    - name: /root/.kube
    - user: root
    - group: root
    - mode: 700

install_k3s_master:
  cmd.run:
    - name: >
        sh -c "INSTALL_K3S_EXEC='--write-kubeconfig-mode 644' INSTALL_K3S_SKIP_ENABLE=false curl -sfL https://get.k3s.io | sh -"
    - require:
      - pkg: install_dependencies
      - service: var-lib-rancher-k3s.mount

# reload systemd (installer writes unit files)
systemd-daemon-reload-k3s:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - cmd: install_k3s_master

dump_k3s_token:
  cmd.run:
    - name: |
        if [ -f /var/lib/rancher/k3s/server/node-token ]; then
          cat /var/lib/rancher/k3s/server/node-token > /tmp/k3s_token
        fi
    - require:
      - cmd: install_k3s_master

copy_k3s_yaml:
  cmd.run:
    - name: cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
    - unless: test -f /root/.kube/config
    - require:
      - file: .kube_dir

fix_k3s_yaml_ip:
  cmd.run:
    - name: sed -i 's/127.0.0.1/10.70.8.30/' /root/.kube/config
    - require:
      - cmd: copy_k3s_yaml

get_token:
  cmd.run:
    - name: cat /var/lib/rancher/k3s/server/token
    - require:
      - cmd: fix_k3s_yaml_ip
```

После - применяем конфиги: 

```bash
salt -G 'roles:k3s-check-master' state.apply k3s.init
```

```bash
salt -G 'roles:k3s-check-master' state.apply k3s.master
```

Смотрим на выводы, если нет красного, то вероятность косяков на физическом уровне - меньше. В выводе - мы получаем токен = он находится вот тут `/var/lib/rancher/k3s/server/token`. Копируем этот токен и прописываем его в пиллар `/srv/pillar/k3s.sls`:
# /srv/pillar/k3s.sls
k3s:
  server: salt-k3s-master     
  server_addr: 10.70.8.40     
  master_url: "https://10.70.8.40:6443"
  token: 'xxxx::server:xxx'

Далее - обновляем пиллары: 

```bash
salt -G 'roles:k3s-check-node' saltutil.refresh_pillar
```

<img width="934" height="124" alt="image" src="https://github.com/user-attachments/assets/e13b361e-0e78-4a90-a34f-b61320e35535" />

Этой командой проверим, отобразились ли пиллары на миньонах:

```bash
salt -G 'roles:k3s-check-node' pillar.items
```

Если всё хорошо - то пропишем конфиг `/srv/salt/base/k3s/worker.sls`: 

```yaml
# /srv/salt/base/k3s/worker.sls
include:
  - k3s.init

# Загрузка токена и URL из pillar
{% set master_url = salt['pillar.get']('k3s:master_url') %}
{% set token = salt['pillar.get']('k3s:token') %}

join_k3s_cluster:
  cmd.run:
    - name: |
        export K3S_URL="{{ pillar['k3s']['master_url'] }}"
        export K3S_TOKEN="{{ pillar['k3s']['token'] }}"
        export INSTALL_K3S_SKIP_ENABLE=true
        export INSTALL_K3S_SKIP_START=false
        curl -sfL https://get.k3s.io | sh -
    - unless: test -f /etc/systemd/system/k3s-agent.service
    - require:
      - mount: mount-k3s

systemd-daemon-reload-k3s-agent:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - cmd: join_k3s_cluster

k3s-agent-service:
  service.running:
    - name: k3s-agent
    - enable: True
    - require:
      - cmd: join_k3s_cluster
```

Применяем 

```bash
salt -G 'roles:k3s-check-node' state.apply k3s.init

# Если всё успешно, то:

salt -G 'roles:k3s-check-node' state.apply k3s.worker
```
По нему у нас поднимется воркер. Если всё прошло хорошо, то ещё раз проверим состояние кластера простой командой: 

```bash
salt -G 'roles:k3s-check-master' cmd.run 'kubectl get nodes'
```

<img width="921" height="168" alt="image" src="https://github.com/user-attachments/assets/59903a1e-7f30-4d39-b37b-8c3c303def6c" />

### Поднятие простейшего манифеста на K3S через соль

Поднимем простейший манифест по nginx для k3s. Для этого - я создал диры states_for_manifests и kubemanifests для стейтов и манифестов соответсвенно. Вот как у меня стала выглядеть рабочая дира для стейтов и прочего: 

```bash
root@salt-master:/srv/salt/base# tree
.
├── k3s
│   ├── init.sls
│   ├── init.sls.bak
│   ├── kubemanifests
│   │   └── example-nginx-pod.yaml
│   ├── master.sls
│   ├── master.sls.bak
│   ├── states_for_manifests
│   │   ├── example-nginx-pod.sls
│   │   ├── init.sls
│   │   └── nginx-example-remove.sls
│   ├── worker.sls
│   └── worker.sls.bak
├── swarm
│   ├── init.sls
│   ├── init.sls.bak
│   ├── master.sls
│   ├── master.sls.bak
│   ├── stack.sls
│   └── worker.sls
└── top.sls

5 directories, 17 files
```

