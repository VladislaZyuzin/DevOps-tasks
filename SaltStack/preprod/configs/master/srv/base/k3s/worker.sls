# /srv/salt/base/k3s/worker.sls
include:
  - k3s.init

# Загрузка токена и URL из pillar
{% set master_url = salt['pillar.get']('k3s:master_url') %}
{% set token = salt['pillar.get']('k3s:token') %}

join_k3s_cluster:
  cmd.run:
    - name: |
        export K3S_URL="{{ pillar['k3s']['master_url'] }}"
        export K3S_TOKEN="{{ pillar['k3s']['token'] }}"
        export INSTALL_K3S_SKIP_ENABLE=true
        export INSTALL_K3S_SKIP_START=false
        curl -sfL https://get.k3s.io | sh -
    - unless: test -f /etc/systemd/system/k3s-agent.service
    - require:
      - mount: mount-k3s

systemd-daemon-reload-k3s-agent:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - cmd: join_k3s_cluster

k3s-agent-service:
  service.running:
    - name: k3s-agent
    - enable: True
    - require:
      - cmd: join_k3s_cluster
