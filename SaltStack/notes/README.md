# Конспект по SaltStack

### Система управления конфигурациями: 

<img width="1157" height="268" alt="image" src="https://github.com/user-attachments/assets/9f41ea84-f0ef-4169-9845-0d9f5983625e" />

### Небольшой глоссарий

<img width="1144" height="632" alt="image" src="https://github.com/user-attachments/assets/8579d865-4b07-42f4-8888-be36150c2233" />

### Топология

<img width="1072" height="431" alt="image" src="https://github.com/user-attachments/assets/e5412cbb-3750-45d5-a847-b37d659d6334" />

### Данные 

`Grains` (“крупицы соли”) - отдельные переменные от клиентов
`Pillars` (“соляные столпы”) - переменные, которые указывает инженер для работы с серверами
`Salt Mine` (“соляные шахты”) - это штука, по которой одни миньоны что то знают о других миньонах, эдакий хабик информации

### Типы модулей

`salt.modules` - рабочие модели executional, т.е. модули исполнения, выполняют различные действия (запуск внешней команды, редактирование файлов, получение информации на мастер) 
`salt.states` - абстракция над модулями исполнения, суть в том, что мы хотим desired state
`salt.grains` - моли, отвечающие за наполнение фактов, добавление факторов, эдакий etcd 
`salt.pillar` - модули пилларов, задача - получать пиллары, те переменные, которые задаёт админ. У них расширение .sls 
`salt.renderer` - разборшики конфигов. Данные можно получать по определённым типам данных и через рендер их разбирать 

### Где лежат конфиги и что с ними делать: 

/etc/salt/master
/etc/salt/minion

**Пример мастера:**

```yaml
interface: 0.0.0.0

publish_port: 4505

# Для файлового сервера, аутентификации, возврата результатов и проч.
ret_port: 4506

# Корневая директория добавляется к прочим путям в конфиге
root_dir: /

# Писать статистику после выполнения команд
cli_summary: true

#event_return: mysql

auto_accept: false

state_top: top.sls

renderer: jinja|yaml

# При ошибке падать сразу
failhard: false

state_aggregate: true

# Либо указываем, что можно аггрегировать
# state_aggregate:
#   - pkg

fileserver_backend:
  - roots
  - git

file_roots:
  base:  # Это дефолтный saltenv
    - /srv/salt/  # Это дефолтный путь
  dev:
    - /srv/salt-dev/
  prod:
    - /srv/salt-prod/

# pygit2 или gitpython
gitfs_provider: pygit2

gitfs_base: master

# Ваши репозитории здесь
#gitfs_remotes:
#  - file:///srv/git/saltstack:
#    - root: 'srv/salt/'
#  - https://example.com/states.git:
#    - user: git
#    - password: mypassword

# Путь к пилларам по умолчанию
base:
  - /srv/pillar/

#reactor:
#  - salt/auth:
#    - salt://reactor/highstate.sls
#    - salt://reactor/keys.sls

nodegroups:
  rpm-hosts: 'G@os_family:RedHat'
  deb-hosts: 'G@os:Debian'
  blue: '*-blue'
  red: '*-red'

# vi: ft=yaml
```
**Пример миньона:** 
```yaml
﻿# По умолчанию salt
master: localhost
# По умолчанию берётся hostname
id: salt-cats-red

# Применять хайстейт при запуске
startup_states: highstate

# Значение local означает не синхронизироваться с мастером
file_client: remote

# Пути для локального файлового клиента
file_roots:
  base:
    - /srv/salt/
    - /root/salt/

# Для локального файлового клиента
pillar_roots:
  base:
    - /srv/pillar/

# Произвольные статические крупички
grains:
  roles:
    - storage
    - gateway

# Выключаем модули из синхронизации
extmod_blacklist:
  grains:
    - dmidecode
  modules:
    - lfn
    - registry
    - drives
    - boot_grinder
    - software
    - printers

# Уровень журналирования в терминал
log_level: info
# Уровень жунралирования в лог-файл
log_level_logfile: info

# vi: ft=yaml
```

Команды для лучшего понимания системы: 

salt-run fileserver.dir_list [saltenv=ОКРУЖЕНИЕ] - способ отладить пути для окружения. Если нужно убедится, что мастер видит папки. НА МАСТЕРЕ
salt-run.fileserver.file_list [saltenv=ОКРУЖЕНИЕ] - способ показать, какие файлы есть в дире (папке) в мастере 

Конфиг перечитывается в рантайме. Они хранятся в /var/cache/salt/

salt-master (команда и служба) - основная команда для запуска сервера 
salt-minion (команда и служба) - соответственно для миньона
Ключ –log-lavel=debug 

Есть команда salt-key -L она обрисовывает ситуацию для ключей, к каким мастерам есть подключение (accepted, denied и unaccepted). 

```
salt ЦЕЛЬ МОДУЛЬ.ФУНКЦИЯ АРГУМЕНТЫ
```
```
salt-cp ЦЕЛЬ ИСТОЧНИК1 [ИСТОЧНИК2 …] НАЗНАЧЕНИЕ
```
```
salt-call МОДУЛЬ.ФУНКЦИЯ АРГУМЕНТЫ
```
```
salt-run МОДУЛЬ.ФУНКЦИЯ АРГУМЕНТЫ
```

 Нацеливание 
По имени: 
```
salt ‘*-blue’ test.ping
```
По грейнам
```
salt -G ‘os:CentOS’ test.ping
```
По группам:
```
salt -N blue test.ping
```
По сетевым адресам:
```
salt -C ‘G@os-CentOS and *blue or S@192.168.122.122’ test.ping
```
