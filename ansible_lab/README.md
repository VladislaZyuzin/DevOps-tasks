# Лабораторная работа по Ansible

![image](https://github.com/user-attachments/assets/25302d08-be5b-4d43-9c22-5c1664335047)

![image](https://github.com/user-attachments/assets/4433c333-234a-4ba9-91e8-78d714860711)

![image](https://github.com/user-attachments/assets/315b9779-4af8-4348-b204-6e3c308e7da1)

![image](https://github.com/user-attachments/assets/791ff094-1650-4135-a245-13a351a9fc3a)

![image](https://github.com/user-attachments/assets/f2ad365f-48c6-4fe8-94e9-ffb3c3b452d7)

![image](https://github.com/user-attachments/assets/12502ea5-70a7-4ce6-bf01-dba79d6d2a8b)

![image](https://github.com/user-attachments/assets/deb2f3ed-3d76-4753-bb5f-71b54b7c2616)

Создадим кастомную страницу (веб страничка):

nginx.yml
```yml
---
- name: Install and configure Nginx
  hosts: webservers
  become: yes  # Выполнять команды с правами root
  tasks:
    - name: Install sudo
      apt:
        name: sudo
        state: present

    - name: Update apt cache
      apt:
        update_cache: yes

    - name: Install Nginx
      apt:
        name: nginx
        state: present

    - name: Start Nginx service
      command: service nginx start

    - name: Create custom index.html
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>Hello from Ansible!</title>
          </head>
          <body>
              <h1>Hello from Ansible and Docker!</h1>
          </body>
          </html>
        dest: /var/www/html/index.html
        owner: www-data
        group: www-data
        mode: '0644'

    - name: Ensure Nginx is running
      uri:
        url: "http://localhost"
        return_content: yes
      register: nginx_status
      ignore_errors: yes

    - name: Show Nginx status
      debug:
        var: nginx_status.status
```
