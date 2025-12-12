#{% set stack_file = '/tmp/mystack.yml' %}

/root/configs:
  file.directory:
    - name: /root/configs
    - user: root
    - group: root
    - mode: 700

{% set stack_file = '/root/configs/mystack.yml' %}

mystack_yaml:
  file.managed:
    - name: {{ stack_file }}
    - contents: |
        version: '3.9'

        services:
          postgres:
            image: postgres:15
            environment:
              POSTGRES_USER: myuser
              POSTGRES_PASSWORD: mypassword
              POSTGRES_DB: mydb
            ports:
              - "5432:5432"
            volumes:
              - pgdata:/var/lib/postgresql/data
            deploy:
              replicas: 1
              restart_policy:
                condition: on-failure

          redis:
            image: redis:7
            ports:
              - "6379:6379"
            deploy:
              replicas: 1
              restart_policy:
                condition: on-failure

          nginx:
            image: nginx:1.25
            ports:
              - "8080:80"
            deploy:
              replicas: 1
              restart_policy:
                condition: on-failure

        volumes:
          pgdata:
    - user: root
    - group: root
    - mode: 644
#    - require:
#      - cmd: init_swarm

deploy_mystack:
  cmd.run:
    - name: docker stack deploy -c {{ stack_file }} mystack
    - unless: docker stack ls | grep -q mystack
#    - require:
#      - file: mystack_yaml
