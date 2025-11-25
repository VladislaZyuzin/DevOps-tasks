# Конспект по SaltStack

## Реакторы

* **Действия по событию (как callback)** - по своей сути - как в проге. Мы хотим, чтобы по нажатию на кнопку - было действие, типо, вызови функцию при нажатии на кнопку
* **Прописываются последоватьельностю в конфиге мастера**
* **Сопостовляют действие тегу события** - синтаксис такой, что какой-то тэг евента сопоставляется с реактором
* **Бывают local, runner, wheel и caller** - local - вызов с солью (локальный клиент), runner - серверные задачи, более спец-е типы - wheel (принятие и отклонение ключей), caller - при остутсвии доступа к мастеру
* **Переменные Jinja доступны ограниченно, реквезитов нет** 

```bash
salt-run event.sent ТЭГ СЛОВАРЬ для отладки
```

### Пример работы с мастером

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

reactor:
  - salt/auth:
    - salt://reactor/highstate.sls
    - salt://reactor/keys.sls

nodegroups:
  rpm-hosts: 'G@os_family:RedHat'
  deb-hosts: 'G@os:Debian'
  blue: '*-blue'
  red: '*-red'

# vi: ft=yaml

```
