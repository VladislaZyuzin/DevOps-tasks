base:
  'roles:swarm-master':
    - match: grain
    - swarm.init
    - swarm.master
    - swarm.stack

  'roles:k3s-master':
    - match: grain
    - k3s.init
    - k3s.master

  'roles:k3s-node':
    - match: grain
    - k3s.init
    - k3s.worker

  'roles:k3s-check-master':
    - match: grain
    - k3s.init
    - k3s.master
    - k3s.states_for_manifests/nginx-example-advanced

  'roles:k3s-check-node':
    - match: grain
    - k3s.init
    - k3s.worker
