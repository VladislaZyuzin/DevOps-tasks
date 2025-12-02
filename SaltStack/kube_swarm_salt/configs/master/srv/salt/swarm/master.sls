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
