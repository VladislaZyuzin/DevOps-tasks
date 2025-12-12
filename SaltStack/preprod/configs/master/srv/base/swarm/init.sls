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
