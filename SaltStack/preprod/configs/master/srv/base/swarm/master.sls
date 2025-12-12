init_swarm:
  cmd.run:
    - name: docker swarm init --advertise-addr {{ pillar['swarm']['advertise_addr'] }}
    - unless: "docker info | grep -q 'Swarm: active'"
