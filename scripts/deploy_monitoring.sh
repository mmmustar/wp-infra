#!/bin/bash

set -euo pipefail

# Configuration
ec2_user="ubuntu"
ec2_ip="35.181.234.232"
ssh_key="/home/gnou/.ssh/test-aws-key-pair-new.pem"

ssh -o StrictHostKeyChecking=accept-new \
   -o ConnectTimeout=10 \
   -i "$ssh_key" \
   "$ec2_user@$ec2_ip" << 'REMOTESCRIPT'
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

cat > /home/ubuntu/deploy_monitoring.sh << 'EOF'
#!/bin/bash
set -euo pipefail

# Variables
SSH_KEY="/home/gnou/.ssh/test-aws-key-pair-new.pem"
EC2_USER="ubuntu"
EC2_IP="35.181.234.232"

kubectl get namespace monitoring >/dev/null 2>&1 || kubectl create namespace monitoring

cat > monitoring-values.yaml << 'VALUES'
grafana:
  adminPassword: admin
  service:
    type: NodePort
    nodePort: 32000
prometheus:
  service:
    type: NodePort
    nodePort: 32090
VALUES

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values monitoring-values.yaml \
  --atomic --timeout 5m

cat > wordpress-monitor.yaml << 'MONITOR'
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: wordpress
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: wordpress
  namespaceSelector:
    matchNames:
      - wordpress-prod
  endpoints:
    - port: http
MONITOR
kubectl apply -f wordpress-monitor.yaml

echo "✅ Monitoring déployé avec succès !"
echo "➡️ SSH Tunnel : ssh -L 3000:localhost:32000 -i \"$SSH_KEY\" $EC2_USER@$EC2_IP"
echo "   URL Grafana : http://localhost:3000 (admin/admin)"
EOF

chmod +x /home/ubuntu/deploy_monitoring.sh 
/home/ubuntu/deploy_monitoring.sh
REMOTESCRIPT