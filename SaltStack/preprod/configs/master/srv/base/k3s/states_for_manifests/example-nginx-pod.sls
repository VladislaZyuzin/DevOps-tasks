# Deploy Nginx example pod from manifest file
{% set manifest_file = '/root/kubemanifests/nginx-example-pod.yaml' %}

# Copy manifest file to minion
nginx_pod_manifest:
  file.managed:
    - name: {{ manifest_file }}
    - source: salt://k3s/kubemanifests/example-nginx-pod.yaml
    - makedirs: true
    - user: root
    - group: root
    - mode: 644

# Deploy pod using kubectl
deploy_nginx_pod:
  cmd.run:
    - name: kubectl apply -f {{ manifest_file }}
    - unless: kubectl get pod nginx-example-pod 2>/dev/null
    - require:
      - file: nginx_pod_manifest
    - env:
      - KUBECONFIG: /etc/rancher/k3s/k3s.yaml

# Verify pod is running
verify_nginx_pod:
  cmd.run:
    - name: |
        echo "Checking nginx-example-pod status..."
        kubectl get pod nginx-example-pod -o jsonpath='{.status.phase}' | grep -q Running
    - require:
      - cmd: deploy_nginx_pod
