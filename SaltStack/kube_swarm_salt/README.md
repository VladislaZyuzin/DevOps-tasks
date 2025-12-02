# Мануал по работе с SaltStack

## ТЗ
> Поднять через соль кластер кубера (3 тачки) и кластер docker-swarm (2 тачки)

## Реализация 
### Установка wsl

Для начала работы я включил Hyper-V на своём рабочек ПК. Это можно загуглить. Далее - я воспользовался командой 
```.ps1
wsl --install
```

После того, как wsl был установлен - я его обновил, чтобы работал WSL2

```.ps1
wsl --update
```

Далее - я установил 6 ВМ на убунту: 

```.ps1
wsl --install -d Ubuntu --name salt-owls-green
wsl --install -d Ubuntu --name salt-cats-blue
wsl --install -d Ubuntu --name salt-cats-red
wsl --install -d Ubuntu --name salt-owls-red
wsl --install -d Ubuntu --name salt-owls-blue
```

### Установка SaltStack для убунту

После того, как вмки были установлены - я воспользовался скриптом для установки salt-master и salt-minion на отдельно взятые вм. Мастером я назначил вм "master", остальных назначил миньонами, команды для установки я брал отсюда: [установка SaltStack на убунту](https://cloudspinx.com/install-saltstack-master-minion-on-ubuntu/)

После этого - я настроил просто связь по соли. Для этого - я внёс настройки конфига в мастер: 

```yaml
##### Primary configuration settings #####
##########################################
default_include: master.d/*.conf
interface: 0.0.0.0
ipv6: False
publish_port: 4505
user: root  # В WSL обычно root
enable_ssh_minions: True
ret_port: 4506
pidfile: /var/run/salt-master.pid
root_dir: /srv/salt
conf_file: /etc/salt/
pki_dir: /etc/salt/pki/master
cachedir: /srv/salt/master/cache
extension_modules: /srv/salt/master/cache/extmods
verify_env: True
keep_jobs_seconds: 86400
gather_job_timeout: 120
timeout: 60
output: nested
show_timeout: True
show_jid: True
color: True
strip_colors: False
cli_summary: True
sock_dir: /var/run/salt/master
enable_gpu_grains: False
job_cache: True
minion_data_cache: True
cache: localfs
memcache_expire_seconds: 0
memcache_max_items: 1024
memcache_full_cleanup: False
memcache_debug: False
ipc_mode: ipc
ping_on_rotate: True
preserve_minion_cache: False
allow_minion_key_revoke: True
batch_safe_limit: 100
batch_safe_size: 10
open_mode: False
auto_accept: False
roster: flat
roster_file: /etc/salt/roster
ssh_timeout: 120
ssh_log_file: /var/log/salt/ssh
ssh_use_home_key: True
state_top: top.sls
renderer: jinja|yaml
failhard: False
state_verbose: True
state_output: full
state_output_diff: False
state_output_profile: True
state_output_pct: False
state_compress_ids: False
state_aggregate: False
state_events: False
file_roots:
  base:
    - /srv/salt
#    - /srv/formulas/salt-formula-etcd
#    - /srv/formulas/salt-formula-kubernetes
master_roots:
  base:
    - /srv/salt/salt-master
top_file_merging_strategy: merge
env_order: ['base', 'dev', 'prod']
hash_type: sha256
file_ignore_regex:
  - '/\.git($|/)'
file_ignore_glob:
  - '*.pyc'
fileserver_backend:
  - roots
pillar_roots:
  base:
    - /srv/salt/pillar
ssh_minion_opts:
  thin_dir: /tmp
pillar_safe_render_error: True
pillar_source_merging_strategy: smart
pillarenv_from_saltenv: True
pillar_raise_on_missing: False

nodegroups:
  all-minions: 'G@os:Ubuntu'
  owls: 'L@salt-owls-blue,salt-owls-green,salt-owls-red'
  cats: 'L@salt-cats-blue,salt-cats-red'
  blue: '*-blue'
  red: '*-red'
  green: '*-green'
  owls-master: 'salt-owls-green'  # k8s master
  owls-workers: 'L@salt-owls-blue,salt-owls-red'  # k8s workers
  cats-master: 'salt-cats-red'  # swarm master
  cats-workers: 'salt-cats-blue'  # swarm workers

log_file: /var/log/salt/master
log_level: warning
log_datefmt_logfile: '%Y-%m-%d %H:%M:%S'
log_fmt_console: '[%(levelname)-8s] %(message)s'
log_fmt_logfile: '%(asctime)s,%(msecs)03d [%(name)-17s][%(levelname)-8s] %(message)s'
```

Применяем: 
```bash
systemctl restart salt-master.service
```

В миньоны я внёс конфиги, например, для salt-owls-green (будущий мастер в кубе для всех owls машин):

```yaml
master: 192.168.184.178
id: salt-owls-green
startup_states: ''
file_client: remote
grains:
  roles:
    - minion
    - owls
    - k8s-master
  group: green
  team: owls
log_level: info
log_level_logfile: info
```

Для cats машин - я внёс конфиг, например, как для salt-cats-red (мастер в сворме):

```yaml
master: 192.168.184.178
id: salt-cats-red
startup_states: ''
file_client: remote
grains:
  roles:
    - minion
    - cats
    - swarm-master
  group: red
  team: cats
log_level: info
log_level_logfile: info
```

Применяем: 
```bash
systemctl restart salt-minion.service
```

Остальные файлы можно найти в этой же папке 

Если всё хорошо - то получился пропинговать ВМки через соль: 

```bash
salt '*' test.ping
```

Будет такой вывод: 

```
salt-owls-blue:
    True
salt-owls-red:
    True
salt-cats-blue:
    True
salt-owls-green:
    True
salt-cats-red:
    True
```

### Настойка salt-ssh 

Для настройки salt-ssh прежде всего необходимо поднять ssh-сервер на вмках. В этом есть сложности, так как wsl использует единственный IP адрес для всех вм в сети, из-за чего - оптимальным решением будет использование различных портов для линка по ssh (линк должен идти от пользователя root на вм master к остальным вм с пользователем root). Для этого - вносим подобного рода конфиг в каждую вм, чтобы они не путались в своей сети: 

```bash
Port 221
PermitRootLogin yes
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
```
Далее - обязательно обновляем systemctl, чтобы конфигурация применилась

```bash
systemctl restart ssh
```

Обязательно создаём ключи для связи с вм на мастере командой: 

```bash
ssh-keygen

```

Для того, чтобы было удобнее подключаться - внесём для пользователя рут следующую конфигурацию в папку `/root/.ssh/config`: 

```
Host salt-owls-blue
    HostName 192.168.184.178
    User root
    Port 224
    IdentityFile ~/.ssh/id_ed25519

Host salt-owls-green
    HostName 192.168.184.178
    User root
    Port 222
    IdentityFile ~/.ssh/id_ed25519

Host salt-owls-red
    HostName 192.168.184.178
    User root
    Port 223
    IdentityFile ~/.ssh/id_ed2551

Host salt-cats-blue
    HostName 192.168.184.178
    User root
    Port 225
    IdentityFile ~/.ssh/id_ed25519

Host salt-cats-red
    HostName 192.168.184.178
    User root
    Port 226
    IdentityFile ~/.ssh/id_ed25519
```

Теперь на сервера можно подключаться командой по типу: 

```bash
ssh salt-owls-green
```

