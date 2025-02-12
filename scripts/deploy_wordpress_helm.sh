#!/bin/bash

set -e  # Arrêter en cas d'erreur

# Configuration : remplace par ton chemin de clé SSH
EC2_USER="ubuntu"
EC2_IP="35.180.222.29"
SSH_KEY="/home/gnou/.ssh/test-aws-key-pair-new.pem"

echo "🚀 Connexion à l'EC2 ($EC2_IP) et déploiement de WordPress avec Let's Encrypt..."

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

# ✅ Correction des permissions du répertoire et du fichier
sudo chmod 755 /etc/rancher/k3s
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
sudo chown ubuntu:ubuntu /etc/rancher/k3s/k3s.yaml

# S'assurer que l'utilisateur a bien accès à K3s
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc
source ~/.bashrc

# Installer kubectl
if ! command -v kubectl &> /dev/null; then
    echo "🔹 Installation de kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
fi

# Installer Helm
if ! command -v helm &> /dev/null; then
    echo "🔹 Installation de Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Déployer WordPress avec Helm
namespace="wordpress-test"
kubectl get namespace $namespace || kubectl create namespace $namespace

# Installer Cert-Manager pour gérer les certificats Let's Encrypt
if ! kubectl get namespace cert-manager &> /dev/null; then
    echo "🔹 Installation de Cert-Manager..."
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
    sleep 30  # Attendre que Cert-Manager soit opérationnel
fi

# Vérifier que Cert-Manager fonctionne bien
echo "🔹 Vérification de l'état de Cert-Manager..."
kubectl get pods -n cert-manager

# Créer un ClusterIssuer pour Let's Encrypt
cat <<EOF_CERT | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: admin@mmustar.fr
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF_CERT

echo "✅ ClusterIssuer Let's Encrypt créé."

# Déployer WordPress avec TLS Let's Encrypt
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm upgrade --install wordpress bitnami/wordpress \
  --namespace "$namespace" \
  --set global.storageClass=standard \
  --set service.type=ClusterIP \
  --set ingress.enabled=true \
  --set ingress.hostname=test.mmustar.fr \
  --set ingress.annotations."kubernetes\\.io/ingress\\.class"="nginx" \
  --set ingress.annotations."cert-manager\\.io/cluster-issuer"="letsencrypt-prod" \
  --set ingress.tls=true \
  --set ingress.extraTls[0].hosts[0]=test.mmustar.fr \
  --set ingress.extraTls[0].secretName=letsencrypt-cert

echo "🔹 Attente de l'émission du certificat..."
sleep 60  # Attendre la génération du certificat

# Vérifier l'état des certificats
kubectl get certificate -n "$namespace"

# Attendre jusqu'à ce que le certificat devienne "Ready"
while [[ $(kubectl get certificate -n "$namespace" letsencrypt-cert -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    echo "🔄 En attente que le certificat Let's Encrypt soit validé..."
    sleep 10
done

echo "✅ Certificat Let's Encrypt validé avec succès."

# Redémarrer l'ingress pour prendre en compte le certificat Let's Encrypt
kubectl rollout restart deployment wordpress -n "$namespace"

echo "✅ Déploiement terminé. WordPress devrait être accessible sur https://test.mmustar.fr 🚀"

EOF
