# Remove Nginx example pod
{% set pod_name = 'nginx-example-pod' %}

remove_nginx_pod:
  cmd.run:
    - name: kubectl delete pod {{ pod_name }} --ignore-not-found=true
    - onlyif: kubectl get pod {{ pod_name }} >/dev/null 2>&1
    - env:
      - KUBECONFIG: /etc/rancher/k3s/k3s.yaml

cleanup_manifest:
  file.absent:
    - name: /opt/k8s/manifests/nginx-example-pod.yaml
