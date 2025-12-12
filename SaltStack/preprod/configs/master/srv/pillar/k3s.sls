# /srv/pillar/k3s.sls
k3s:
  server: salt-k8s-master     # minion id of master
  server_addr: 10.70.8.30     # IP адрес мастера для K3S_URL
  master_url: "https://10.70.8.30:6443"
  token: 'xxxx::server:xxx'
