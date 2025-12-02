# Docker Swarm Worker (salt-cats-blue)

# Получить токен с мастера
get_swarm_token:
  cmd.run:
    - name: scp -P 226 -o StrictHostKeyChecking=no root@192.168.184.178:/tmp/swarm-worker-token /tmp/
    - creates: /tmp/swarm-worker-token
    - require:
      - service: docker_service

# Присоединиться к Swarm
join_swarm:
  cmd.run:
    - name: docker swarm join --token $(cat /tmp/swarm-worker-token) 192.168.184.178:2377
    - unless: docker info | grep -q 'Swarm: active'
    - require:
      - cmd: get_swarm_token

# Проверить статус
check_swarm_status:
  cmd.run:
    - name: docker info | grep Swarm
    - require:
      - cmd: join_swarmroot@lartech-18612:/srv/salt/swarm#cat master.sls
# Docker Swarm Master (salt-cats-red)

include:
  - docker.init

init_swarm:
  cmd.run:
    - name: "docker swarm init --advertise-addr {{ grains['fqdn_ip4'][0] }}"
    - unless: "docker info | grep -q 'Swarm: active'"
    - require:
      - service: docker_service

get_worker_token:
  cmd.run:
    - name: "docker swarm join-token -q worker > /tmp/swarm-worker-token"
    - onchanges:
      - cmd: init_swarm

get_manager_token:
  cmd.run:
    - name: "docker swarm join-token -q manager > /tmp/swarm-manager-token"
    - onchanges:
      - cmd: init_swarm

swarm_info:
  cmd.run:
    - name: "docker node ls"
    - require:
      - cmd: init_swarm
root@lartech-18612:/srv/salt/swarm# cat worker.sls
# Docker Swarm Worker (salt-cats-blue)

# Получить токен с мастера
get_swarm_token:
  cmd.run:
    - name: scp -P 226 -o StrictHostKeyChecking=no root@192.168.184.178:/tmp/swarm-worker-token /tmp/
    - creates: /tmp/swarm-worker-token
    - require:
      - service: docker_service

# Присоединиться к Swarm
join_swarm:
  cmd.run:
    - name: docker swarm join --token $(cat /tmp/swarm-worker-token) 192.168.184.178:2377
    - unless: docker info | grep -q 'Swarm: active'
    - require:
      - cmd: get_swarm_token

# Проверить статус
check_swarm_status:
  cmd.run:
    - name: docker info | grep Swarm
    - require:
      - cmd: join_swarm
