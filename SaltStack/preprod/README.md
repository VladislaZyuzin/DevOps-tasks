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

После чего - применяем конфигурцаии одну за одной

```bash
salt 'salt-swarm' state.apply swarm.init

# Проверим, всё ли ок

salt 'salt-swarm' state.apply swarm.master
```

При положительном выводе - проверяем ноды на сворме: 

```bash
salt 'salt-swarm' cmd.run 'docker node ls'
```

