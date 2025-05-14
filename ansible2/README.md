# Настройка ВМ в Ansible после её создания с помощью Terraform. Автоматизация установки и настройки веб-сервера с помощью Ansible
> Работа выполнена на ОС Ubuntu Linux
В данной работе я показал возможность интегрирования знаний, полученный при работе с Terraform и Ansible. [Работа с ТФ по этой ссылке](https://github.com/VladislaZyuzin/ITMO_Cloud_Tech_Labas/tree/main/Terraform_lab).
## Подготовка к работе
По базе - обновляем систему и скачиваем Ансибл:
```bash
sudo apt install ansible
```

После - нужно создать пустные файлы для инвентарного файла, плейбука и папку с главным файлом html страницы. 

![image](https://github.com/user-attachments/assets/aba21afa-a58e-45b1-a70d-ee0fa1d5785c)

Создаём инвентарный файл, он будет будет подключатсься к ВМ, которую я создал в лабе по ТФ. Необходимо из учётной записи YC зайти в своё облако, копируем свой публичный адрес.

![image](https://github.com/user-attachments/assets/0877bbbc-8acd-47f1-b40d-5ac4ac3d2013)

Перед началом работы необходимо подключиться по SSH к своей ВМ для проверки:
```bash
ssh ubuntu@51.250.12.34
```

## Процесс работы 

Теперь заходим в `inventoty.ini` и заносим код в зависимости от вашего айпишника и папки с SSH ключом. В моём случае - это: 
```ini
[web]
84.201.157.8 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa
```
После - необходимо проверить подключение через ансибл:
```bash
ansible -i inventory.ini webservers -m ping
```
При успешном успехе всё будет выглядеть так: 

![image](https://github.com/user-attachments/assets/e7c4acd7-a30b-4cd8-aec1-84ed9d7d19cd)

После проверки подключения настроим `playbook.yml`. В него вносим следующий код: 
```yml
- name: Installing and configurating Nginx on server
  hosts: webservers
  become: true
  tasks: 
    - name: Installing Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes 
        
    - name: Copy index.html
      copy: 
        src: files/index.html
        dest: /var/www/html/index.html
        mode: '0644'
        
    - name: Checking Nginx installation
      service: 
        name: nginx
        state: started
        enabled: yes
```
Как видно - все процессы описаны в одном файле, что является преимуществом декларативного подхода, так как мы описываем то, что мы хотим получить в результате запуска. В императивном подходе мы получили бы грусть, если бы занимались большим проектом.

Далее - заполним `index.html`, это будет простая страничка, которая покажет, что работа выполнена верно:
```html
<!DOCTIPE html>
<html>
<head>
<title>Welcome to Vlad's page!</title>
</head>
<body>
<h1>I made it automaticly!</h1>
<h2>This is my step in DevOps engeniering</h2>
</html>
```
После ввода кода необходимо запустить плейбук, чтобы конфигурация прошла успешно для ВМ: 
```bash
ansible-playbook -i inventory.ini playbook.yml
```
При отсутствии ошибок в синтаксисе или неправильных настройках будем выведен результат: 

![image](https://github.com/user-attachments/assets/c02ede50-f7b9-416c-b0f3-202efd0e55d4)

После - проверим сайт, который создался с помощью нгинкса, введём публичный айпишник в строку поиска, у меня всё получилось: 

![image](https://github.com/user-attachments/assets/e0469c6e-dbe6-4868-b7f1-836a78056040)

## Итоги
В ходе работы получилось настроить ВМ с Яндекс Облака, которую я настраивал ранее, на ВМ получилось поставить нгинкс последней версии, работы веб сервера я проверил и всё успешно. 
