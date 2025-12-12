base:
  'salt-k8s-worker*':
    - k3s

  'roles:swarm-master':
    - match: grain
    - swarm

  'roles:k3s-check-node':
    - match: grain
    - k3s
