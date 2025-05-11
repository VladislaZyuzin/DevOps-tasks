![image](https://github.com/user-attachments/assets/5ed3295e-4021-4f2d-af52-dc4f9e799c20)# Лабораторная работа по терраформу

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
## ОСновная часть
После разрешения проблемы переходим в директорию `yc-terraform`, если ещё не перешли. Теперь следует создать 3 пустых файла, которые в дальнейшем будут заполняться: 
```bash
touch {main.tf,outputs.tf,variables.tf}
```
В `main.tf` внесём следующий код: 
```hcl
# main.tf
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  cloud_id  = "<ваш cloud-id>"     # Получить: yc config get cloud-id
  folder_id = "<ваш folder-id>"    # Получить: yc config get folder-id
  zone      = "ru-central1-a"
  token     = "<ваш_oauth_токен>"  # Его можно взять введя команду: yc iam create-token

# Создаем сеть
resource "yandex_vpc_network" "network" {
  name = "my-network"
}

# Создаем подсеть
resource "yandex_vpc_subnet" "subnet" {
  name           = "my-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# Создаем ВМ
resource "yandex_compute_instance" "vm" {
  name        = "my-first-vm"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2  # ГБ
  }

  boot_disk {
    initialize_params {
      image_id = "fd8kdq6d0p8sij7h5qe3"  # Ubuntu 20.04 LTS
      size     = 10  # ГБ
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true  # Публичный IP
  }

  metadata = {
  ssh-keys = "ubuntu:${file("/home/vladislav/.ssh/id_rsa.pub")}"
  }
}
```
Так же расписываем файл с выводои IP-адреса (`outputs.tf`)
```hcl
output "external_ip" {
  value = yandex_compute_instance.vm.network_interface.0.nat_ip_address
}
```
И ещё, необходимо заполнить файл для ssh, который мы указываем в `main.tf`. Для этого проверяем наличие SSH - ключа: 
```bash
ls ~/.ssh/id_rsa.pub
```
Если его нет, то вводим данную команду: 
```bash
ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""
```
Команда создаст и сгенерирует ключ и при создании инфроструктуры код в `main.tf` будет обращаться к SSH ключу. 

## Запуск процесса

Для запуска процесса требуется, чтобы тф на локальном компа видел облако. Для этого введём команду:
```bash
terraform init
```
Так будет выглядеть успешный вывод: 
![image](https://github.com/user-attachments/assets/aa99cdf7-e0bd-4b82-be8a-e65edfd091fe)

Далее нам следует понять - что создастся в результате нашей работы. Для этого введём команду: 

```bash
terraform plan
```
![image](https://github.com/user-attachments/assets/bacad391-7c58-47f9-8b1b-51480c2c145f)

Если вы захотите повторить всё ещё раз, то вы увидете то, что появилось у меня, главное - поменять токен, если проделываете операции через час и более времени, у него маленькое время жизни.

После - необходимо применить конфигурацию. Для этого введите команду: 
```bash
terraform apply
```
Конфигурация будет применена и нужная инфроструктура будет создана в облаке. В моём случае команда вводится не в первый раз, так что скрин будет отличаться от вашего. В первый раз соглашайтесь со всеми требованиями и вас будет ждать успех.
![image](https://github.com/user-attachments/assets/09055255-81e7-4e50-9f8a-0072057c90b8)
