# Установка docker

remove_old_docker:
  pkg.removed:
    - pkgs:
      - docker
      - docker-engine
      - docker.io
      - containerd
      - runc

install_prerequisites:
  pkg.installed:
    - pkgs:
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg
      - lsb-release

add_docker_gpg_key:
  cmd.run:
    - name: curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    - unless: test -f /usr/share/keyrings/docker-archive-keyring.gpg
    - require:
      - pkg: install_prerequisites

add_docker_repo:
  cmd.run:
    - name: |
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    - unless: test -f /etc/apt/sources.list.d/docker.list
    - require:
      - cmd: add_docker_gpg_key

update_apt:
  cmd.run:
    - name: apt-get update
    - require:
      - cmd: add_docker_repo

install_docker:
  pkg.installed:
    - pkgs:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-buildx-plugin
      - docker-compose-plugin
    - require:
      - cmd: update_apt

docker_service:
  service.running:
    - name: docker
    - enable: True
    - require:
      - pkg: install_docker

add_user_to_docker:
  group.present:
    - name: docker
    - addusers:
      - root
    - require:
      - pkg: install_docker
