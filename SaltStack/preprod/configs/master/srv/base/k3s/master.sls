# /srv/salt/base/k3s/master.sls
# Ensure init ran
include:
  - k3s.init

# Создание директории ~/.kube
.kube_dir:
  file.directory:
    - name: /root/.kube
    - user: root
    - group: root
    - mode: 700

install_k3s_master:
  cmd.run:
    - name: >
        sh -c "INSTALL_K3S_EXEC='--write-kubeconfig-mode 644' INSTALL_K3S_SKIP_ENABLE=false curl -sfL https://get.k3s.io | sh -"
    - require:
      - pkg: install_dependencies
      - service: var-lib-rancher-k3s.mount

# reload systemd (installer writes unit files)
systemd-daemon-reload-k3s:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - cmd: install_k3s_master

dump_k3s_token:
  cmd.run:
    - name: |
        if [ -f /var/lib/rancher/k3s/server/node-token ]; then
          cat /var/lib/rancher/k3s/server/node-token > /tmp/k3s_token
        fi
    - require:
      - cmd: install_k3s_master

copy_k3s_yaml:
  cmd.run:
    - name: cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
    - unless: test -f /root/.kube/config
    - require:
      - file: .kube_dir

fix_k3s_yaml_ip:
  cmd.run:
    - name: sed -i 's/127.0.0.1/10.70.8.30/' /root/.kube/config
    - require:
      - cmd: copy_k3s_yaml

get_token:
  cmd.run:
    - name: cat /var/lib/rancher/k3s/server/token
    - require:
      - cmd: fix_k3s_yaml_ip
