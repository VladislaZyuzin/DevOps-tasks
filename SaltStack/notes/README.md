# Конспект по SaltStack

### Система управления конфигурациями: 

<img width="1157" height="268" alt="image" src="https://github.com/user-attachments/assets/9f41ea84-f0ef-4169-9845-0d9f5983625e" />

* `pull` - сервера образщаются к главному серверу за новыми фичами 
* `push` - сервер сам ходит на сервера, устанавливая новые фичи, обновы

### Небольшой глоссарий

<img width="1144" height="632" alt="image" src="https://github.com/user-attachments/assets/8579d865-4b07-42f4-8888-be36150c2233" />

### Топология

<img width="1072" height="431" alt="image" src="https://github.com/user-attachments/assets/e5412cbb-3750-45d5-a847-b37d659d6334" />

### Данные 

* `Grains` (“крупицы соли”) - отдельные переменные от клиентов
* `Pillars` (“соляные столпы”) - переменные, которые указывает инженер для работы с серверами
* `Salt Mine` (“соляные шахты”) - это штука, по которой одни миньоны что то знают о других миньонах, эдакий хабик информации

### Типы модулей

* `salt.modules` - рабочие модели executional, т.е. модули исполнения, выполняют различные действия (запуск внешней команды, редактирование файлов, получение информации на мастер)
* `salt.states` - абстракция над модулями исполнения, суть в том, что мы хотим desired state
* `salt.grains` - моли, отвечающие за наполнение фактов, добавление факторов, эдакий etcd
* `salt.pillar` - модули пилларов, задача - получать пиллары, те переменные, которые задаёт админ. У них расширение .sls
* `salt.renderer` - разборшики конфигов. Данные можно получать по определённым типам данных и через рендер их разбирать 

### Где лежат конфиги и что с ними делать: 

/etc/salt/master

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

/etc/salt/minion

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

### Команды для лучшего понимания системы: 

* `salt-run fileserver.dir_list` [saltenv=ОКРУЖЕНИЕ] - способ отладить пути для окружения. Если нужно убедится, что мастер видит папки. НА МАСТЕРЕ
* `salt-run.fileserver.file_list` [saltenv=ОКРУЖЕНИЕ] - способ показать, какие файлы есть в дире (папке) в мастере 

Конфиг перечитывается в рантайме. Они хранятся в /var/cache/salt/

* `salt-master` (команда и служба) - основная команда для запуска сервера 
* `salt-minion` (команда и служба) - соответственно для миньона
Ключ `–log-lavel=debug` 

Есть команда 
```
salt-key -L
```
она обрисовывает ситуацию для ключей, к каким мастерам есть подключение (accepted, denied и unaccepted). 

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

### Нацеливание 
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

Помним, что * без ковычек раскрывается шеллом

## Шина событий 

* Это как общий чат
* Подписываются авторизованные клиенты (клиенты, чьи ключи мы приняли)
* Миньоны берут ключи задачи, когда в они есть в адресатах
* Миньоны отвечают обратно в шину
* Шина на ZeroMQ производительна
 
```
salt-run state.event [ПАТТЕРН СОБЫТИЯ] [pretty=true]
```

### Модули сообщения 

* **test, saltutil** - к тесту обращались, салтутил нужен для кастомизации. Модуль тест может сказать, что наш сервер жив, проверить состояние
* **file, pkg, service, system, cmd...** - модуль cmd позволяет произвольные команды, но при повторном исполнении может что-нибудь сломаться, лучше пользоваться file. 
* **apache. postgres, nginx, redis...** 
* **ansiblegate, chief, puppet** - способы интегрирвать соль с другими клентами

#### Пара полезных функций

```
test.ping
```
```
saltutil.sync_all
```
```
sys.doc
```
```
state.test
```

## Формулы состояния
* Аналог playbook-ов из ансибла
* Они повторяемы (идемпотентны)
* Топ-файл и хайстейт (главное чото)

### Формулы (синтаксис)
```yaml
my_state_id1:
  states_module1.function1
  states_module2.function2:
    - name: overrided_id
    - arg1: value
    - arg2:
        - value1
        - value2
        - value3
my_state_id2:
  states_module1.function1
```

* Функции состояний принимают аргумент name (он передаётся либо явно, либо им может быть идентификатор стейта)
* name по умолчанию равен идентификатору
* В формуле может быть множество состояний
* В состоянии можно обращаться к нескольким разным модулям 
* В состоянии нельзя обращаться к одному модулю несколько раз (обратиться к states_module1.function2 мы не сможем)

### Модули состояния 

* **test, saltutil** - к тесту обращались, салтутил нужен для кастомизации. Модуль тест может сказать, что наш сервер жив, проверить состояние
* **file, pkg, service, system, cmd...** - модуль cmd позволяет произвольные команды, но при повторном исполнении может что-нибудь сломаться, лучше пользоваться file. 
* **apache, postgres_*, redismode...** 
* **ansiblegate, chief** - способы интегрирвать соль с другими клентами

#### Ещё пример
```
salt salt-owls-red state.apply kernel_update_simple
```
(kernel_update_simple, там будет исполняться kernel_update_simple.sls)

как выглядит сам kernel_update_simple.sls 
```sls
---
# Пример системного состояния для RPM-дистрибутивов.
# Обновляет ядро Linux и корректирует конфигурацию загрузчика.
kernel updated:
  pkg.uptodate:
    - pkgs:
        - kernel
    - refresh: true  # Обновление ядра 
  file.comment:
    - name: '/etc/default/grub'  
    - regex: '^GRUB_DEFAULT|^GRUB_DISABLE_SUBMENU'  # Комментирование строк 
  cmd.run:
    - name: 'grub2-mkconfig -o /boot/grub2/grub.cfg'  # Применение конфига 
  module.run:
    - name: system.reboot   # Ребут сервера/вм
```

### Порядок исполнения команд
* Лексикографический (как накидали - так и исполняется, про порядок)
```sls
---
# Пример автоматического упорядочивания состояний
state1:
  test.succeed_with_changes
state2:
  test.succeed_with_changes
state3:
  test.succeed_with_changes
state4:
  test.succeed_with_changes
```

(Если сделать дублирование по типу
```sls
state1:
  test.succeed_with_changes
  test.succeed_with_changes
```
или
```sls
state1:
  test.succeed_with_changes
  test.failed_with_changes
```

то будет вырисовываться ошибка. Если же будут использоваться другие модули в стейтах, например: 

```sls
---
# Пример автоматического упорядочивания состояний
state1:
  test.succeed_with_changes: []
  cmd.run:
    - name: 'echo Hello'
state2:
  test.succeed_with_changes
state3:
  test.succeed_with_changes
state4:
  test.succeed_with_changes
```
То тогда стейты заведутся, так как будут различные модули указаны)

* По флагу `order`
```sls

---
# Пример упорядочивания состояний ключом order
state1:
  test.succeed_with_changes:
    - order: 3
state2:
  test.succeed_with_changes:
    - order: 2
state3:
  test.succeed_with_changes:
    - order: 1
state4:
  test.succeed_with_changes:
    - order: 4
```
Как логично предположить - тут формула выполняет сейты по порядку, который указан в `order`. 
* По реквезитам

```sls
---

# Пример упорядочивания состояний реквизитами

state1:
  test.succeed_with_changes: [] # В этом стейте ничего не задано по реквизитом

state2:
  test.succeed_with_changes:
    - require:
        - state1  # Этот стейт выполняется только при изменениях в стейте 1

state3:
  test.succeed_with_changes:
    - onchanges:  # А так же watch, listen
        - state1
        - test: state2  # Тут стейт выполняется при изменении в стейте 1 или 2

state4:
  test.succeed_with_changes:
    - prereq:
        - state1  # Пререквизит для стейта 1, запустится самым первым, после стейт 1

unhappy_state:
  test.succeed_with_changes:
    - onfail:
        - state*  # Этот стейт выполнится если будет ошибка в одном из стейтов, логично его использовать как очисту после ошибки
```

После такого - всё запустится, по идее. 

Далее - поменяем модули в стейтах таким образом, чтобы отработал грамотно state4: 
```sls
---

# Пример упорядочивания состояний реквизитами

state1:
  test.succeed_without_changes: []

state2:
  test.succeed_without_changes:
    - require:
        - state1

state3:
  test.failed_with_changes:
    - onchanges:  # А так же watch, listen
        - state1
        - test: state2

state4:
  test.succeed_with_changes:
    - prereq:
        - state1

unhappy_state:
  test.succeed_with_changes:
    - onfail:
        - state*
```
запустится только 1, 2 и 4, так как первый ни от кого не зависит и он прописан как успешный, 2-й, так как запустился 1-й, а четвёртый запустится, так как поломался 3-й, 3-й не запустился, так как нет изменений в 1-м и 2-м стейтах

**Документация советует взять один способ и следовать ему**

НАПОМИНАНИЕ, примерно так выглядит исполнение стейтов по команде в терминале:
```bash
salt nameserver state.apply kernel_updated   # Тут берётся файл kernel_updated.sls
```

## Jinja 
**Jinja** - шаблонизатор. Он уменьшает дублирование кода, с ним доступны grains, pillarls, любые внешние данные. Он гибок

НО он сложный 

### Синтаксис

* `{{}}` - выводимая инструкция
* `{% $}` - блок [Jinja-кода]
* `{# #}` - комментарий

### Пример кода: 

```jinja
<ul>
{% for s in ['Мир', 'Труд', 'Май',] %}
  {# Этот текст будет удалён шаблонизатором #}
  <li>{{ s }}</li>
{% endfor %}
</ul>
```

* Минусы убирают пробельные символы при подстановке
* `{%- КОД_JINJA %}` - подрезаются символы слева
* `{% КОД_JINJA -%}` - подрезаются символы справа
* `'\n'` - это тже пробельный символ
* Плюсы отменяют подрезку, указанную в конфиге шаблонизатора

### Переменные 

* Переменные:
```jinja
{set my_list = ['Мир', 'Труд', 'Май', 1, 2, 3, 4]}  
```
Он ничего не делает, просто устанавливает в шаблонизаторе массив my_list

* Цикл for
```jinja
{% for i in range(10) %}
  <li>{{ i }}</li>
{% endfor %}
```
Позволяет прооперировать от 0 до 10
* Условный оператор
```jinja
{% if True %}  Правда взаправду правда {% else %} Неправда {% endif %}
```
Условный оператор, должен завершаться endif. Почти как на питоне

* Фильтры и конвееры
```jinja
{{['соль', 'мука'] | join(', ') | capitalize}}
```
Фильтры и конвееры - функции для манипулирования данными. capitalize - сделать заглавной первую букву строки. 

#### Поверка на питоне

```py
import jinja2
s = {{['соль', 'мука'] | join(', ') | capitalize}}
jinja2.Template(s).render()
```

Вывод: `соль, мука`

## Jinja и SaltStack 
* Jinja подключается как text renderer
* Jinja используется по умолчанию
* Доступны специфичные для SaltStack словари (grain, pillars) и специальный объект salt

### Как jinja интегрируется в sls

Допустим, у нас есть файл `jinja_sample.sls`
```sls
﻿---

# Пример использования шаблонов в формуле

power_management_timeouts:
  cmd.run:
    - names:
      {% for setting in ['standby', 'hibernate', 'monitor', 'disk'] %}
      {% for power_mode in ['ac', 'dc'] %}
      - powercfg /change /{{ setting }}-timeout-{{ power_mode }} 0
      {% endfor %}
      {% endfor %}
```
Чтобы посмотреть, как примениться команда (драйран организовать): 
```bash
salt-call slsutil.render <путь-к-файлу>   # чтобы отрендерить формулу
```

Командой применения будет: 
```bash
salt minion1 slsutill.renderer salt://jinja_sample.sls  # В случае - если мы выполняем команду на миньоне
```
```bash
salt minion1 slsutill.renderer jinja_sample  # В случае - если мы выполняем команду на мастере
```
В случае с миньоном - вывод примерно такой:

<img width="694" height="596" alt="image" src="https://github.com/user-attachments/assets/aeda9a6c-5a72-46fd-b567-8b9945c965ea" />

Ещё один пример:

```sls
﻿---

# Пример использования пилларов в формуле

{%
  set settings = pillar.get(
    'power_settings',
    ['standby', 'hibernate', 'monitor', 'disk'])
%}

power_management_timeouts:
  cmd.run:
    - names:
      {% for setting in settings %}
      {% for power_mode in pillar.get('power_modes', ['ac', 'dc']) %}
      - powercfg /change /{{ setting }}-timeout-{{ power_mode }} 0
      {% endfor %}
      {% endfor %}
```

Далее понадобится синхронизация для пилларов:
```bash
salt-call saltutil.refresh_pillar # Чтобы синхронизировать пиллары
```

Для применения конфига: 
```bash
salt minion1 slsutill.renderer salt://jinja_pillar.sls  # В случае - если мы выполняем команду на миньоне
```
Вывод будет таким же, как и раньше

