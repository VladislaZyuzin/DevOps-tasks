# Лабораторная работа по терраформу

> Данная лабораторная работа была выполнена на ОС Ubuntu Linux

##  Подготовка
Прежде всего нам протребуется скачать terraform, для скачивания этого инструмента IaC были задействованы данные команды:

![image](https://github.com/user-attachments/assets/de31bbff-94d2-4c6c-911e-5312f2f20a72)

![image](https://github.com/user-attachments/assets/e8df126b-9e1a-4f89-abc3-5189d224a952)

![image](https://github.com/user-attachments/assets/a0466253-645a-4cb9-807d-12eca5047a90)

Так же потребуется аккаунт в Yandex Cloud и потребуется установить Yandex Cloud CLI. 
* Для создания аккаунта потребуется внести данные банковской карты, если планируется небольшая работа без долгой перспективы, то лучше внести данные пустой карты, которой Вы не пользуетесь. Для моей работы гранта хватило.
* С установкой CLI были определённые сложности, речь о которых пойдёт далее.
На данный момент введём:
```bash
mkdir yc-terraform && cd yc-terraform
```
### Установка Yandex Cloud CLI

Перед установкой обновите всё и вся: 
```bash
sudo apt update && sudo apt upgrade -y
```
После, при вводе данных команд: 
```bash
# Скачиваем и запускаем установщик
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash

# Обновляем shell
exec -l $SHELL

# Проверяем установку
yc --version
```
может возникнуть проблема с тем, что они очень долго выполняются, проблема в прокси. Для решения отключаем прокси, можно на некотоое время.
```bash
env | grep -i proxy
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
```
