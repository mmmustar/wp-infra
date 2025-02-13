#!/bin/bash

set -e  # Arrêter en cas d'erreur

# Configuration
EC2_USER="ubuntu"
EC2_IP="35.180.222.29"
SSH_KEY="/home/gnou/.ssh/test-aws-key-pair-new.pem"

echo "🚀 Connexion à l'EC2 ($EC2_IP) et déploiement de WordPress..."

# Copier les certificats Cloudflare sur l'EC2
echo "🔹 Copie des certificats Cloudflare..."
scp -i "$SSH_KEY" ./scripts/cloudflare_origin.* "$EC2_USER@$EC2_IP:/home/ubuntu/"

# Vérifier la connexion SSH
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_IP" "echo '✅ Connexion SSH réussie'"

# Exécuter les commandes sur l'EC2
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_IP" << 'EOF'
set -e  # Arrêter en cas d'erreur

echo "🔹 Mise à jour des paquets"
sudo apt update -y

echo "🔹 Installation des dépendances"
sudo apt install -y curl jq

# Installer K3s avec permissions correctes
if ! command -v k3s &> /dev/null; then
    echo "🔹 Installation de K3s..."
    curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode=644
    sudo systemctl enable --now k3s
fi

# Correction des permissions du répertoire et du fichier
sudo chmod 755 /etc/rancher/k3s
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
sudo chown ubuntu:ubuntu /etc/rancher/k3s/k3s.yaml

# Configuration de K3s
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc
source ~/.bashrc

# Installer kubectl si nécessaire
if ! command -v kubectl &> /dev/null; then
    echo "🔹 Installation de kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
fi

# Installer Helm si nécessaire
if ! command -v helm &> /dev/null; then
    echo "🔹 Installation de Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Créer le namespace
namespace="wordpress-test"
kubectl get namespace $namespace || kubectl create namespace $namespace

# Nettoyer les ressources existantes
echo "🧹 Nettoyage des installations précédentes..."
kubectl delete secret cloudflare-tls -n $namespace || true
kubectl delete ingress wordpress -n $namespace || true
kubectl delete configmap nginx-configuration -n $namespace || true

# Créer le secret TLS avec les certificats Cloudflare
echo "🔐 Configuration des certificats Cloudflare..."
kubectl create secret tls cloudflare-tls -n $namespace \
    --cert=/home/ubuntu/cloudflare_origin.crt \
    --key=/home/ubuntu/cloudflare_origin.key

# Installer l'Ingress NGINX Controller
echo "📦 Installation de l'Ingress NGINX Controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace $namespace \
    --set controller.publishService.enabled=true \
    --set controller.service.type=NodePort \
    --set controller.service.nodePorts.http=30080 \
    --set controller.service.nodePorts.https=30443 \
    --set controller.config.ssl-protocols="TLSv1.2 TLSv1.3" \
    --set controller.config.proxy-buffer-size="128k" \
    --set controller.config.large-client-header-buffers="4 64k" \
    --set controller.extraArgs.default-ssl-certificate="wordpress-test/cloudflare-tls"

# Attendre que l'Ingress Controller soit prêt
echo "⏳ Attente du démarrage de l'Ingress Controller..."
kubectl rollout status deployment ingress-nginx-controller -n $namespace

# Déployer WordPress avec Helm
echo "🚀 Déploiement de WordPress..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

cat > wordpress-values.yaml << 'EOL'
wordpressScheme: https
wordpressExtraConfigContent: |
  define('FORCE_SSL_ADMIN', true);
  $_SERVER['HTTPS'] = 'on';

ingress:
  enabled: true
  pathType: Prefix
  hostname: test.mmustar.fr
  extraHosts:
    - name: www.test.mmustar.fr
      path: /
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    nginx.ingress.kubernetes.io/proxy-buffer-size: "128k"
  tls: true
  extraTls:
    - hosts:
        - test.mmustar.fr
        - www.test.mmustar.fr
      secretName: cloudflare-tls

service:
  type: ClusterIP
  ports:
    http: 80

persistence:
  enabled: true
  size: 10Gi
  storageClass: local-path

mariadb:
  primary:
    persistence:
      enabled: true
      size: 8Gi
      storageClass: local-path

resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
EOL

helm upgrade --install wordpress bitnami/wordpress \
    --namespace "$namespace" \
    --values wordpress-values.yaml

# Configuration finale de l'ingress
echo "🔧 Configuration de l'ingress..."
cat <<'YAML' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wordpress
  namespace: wordpress-test
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    nginx.ingress.kubernetes.io/proxy-buffer-size: "128k"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - test.mmustar.fr
    - www.test.mmustar.fr
    secretName: cloudflare-tls
  rules:
  - host: test.mmustar.fr
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: wordpress
            port:
              number: 80
  - host: www.test.mmustar.fr
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: wordpress
            port:
              number: 80
YAML

echo "✅ Déploiement terminé. WordPress devrait être accessible sur https://test.mmustar.fr"

# Récupération des credentials
echo "🔑 Credentials WordPress :"
echo "Username: user"
echo "Password: $(kubectl get secret --namespace wordpress-test wordpress -o jsonpath="{.data.wordpress-password}" | base64 -d)"

# Vérification finale
echo "🔍 Vérification de la configuration..."
echo "Secret TLS :"
kubectl get secret cloudflare-tls -n $namespace
echo "Ingress :"
kubectl get ingress -n $namespace
echo "Services :"
kubectl get services -n $namespace
echo "Pods :"
kubectl get pods -n $namespace

# Afficher les logs de l'ingress controller
echo "📝 Logs de l'ingress controller :"
kubectl logs -n $namespace -l app.kubernetes.io/component=controller --tail=50 || true

EOF