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
  cloud_id  = "b1gqsdr166533mquj5gp"
  folder_id = "b1gphoihhtvjcfi2ulp9"
  zone      = "ru-central1-a"
  token     = "t1.9euelZrOzJLNlZKVkcmNksyLjpecz-3rnpWanJuJyZbMzYrJk87Kj86bl8bl9PciFQM_-e9NRCnF3fT3YkMAP_nvTUQpxc3n9euelZqai5WZlombi86clY2Jx5Odle_8xeuelZqai5WZlombi86clY2Jx5OdlQ.5nO-h-25vA1fqBvCvdj5mFuf5aTMV0y8_9laThac3-ja_xp1nwN2buKbsIx3IeYyUb0X5AoT9BswfvYstv6qAQ"
}

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
