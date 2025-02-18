#!/bin/bash

set -e  # Arrêt en cas d'erreur

# Configuration
SSH_KEY_PATH="/home/gnou/.ssh/test-aws-key-pair-new.pem"
EC2_USER="ubuntu"
EC2_IP="35.180.33.10"
NAMESPACE="wordpress-test"
VALUES_FILE="values.yaml"

echo "🔄 Préparation du déploiement..."

# Fonction pour exécuter des commandes SSH avec timeout
run_ssh_command() {
    local cmd="$1"
    local timeout_seconds="${2:-60}"
    ssh -i "$SSH_KEY_PATH" "$EC2_USER@$EC2_IP" "timeout $timeout_seconds bash -c '$cmd'" || return 1
}

echo "🚀 Installation de K3s..."
run_ssh_command "curl -sfL https://get.k3s.io | sh -" 120

echo "⏳ Attente du démarrage de K3s..."
run_ssh_command "sudo systemctl enable --now k3s && \
                 sudo chmod 644 /etc/rancher/k3s/k3s.yaml && \
                 sudo chown ubuntu:ubuntu /etc/rancher/k3s/k3s.yaml"

echo "🔍 Vérification du cluster..."
run_ssh_command "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl get nodes" 30

echo "🔧 Installation de Helm..."
run_ssh_command "curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash" 60

echo "📦 Configuration des dépôts Helm..."
run_ssh_command "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && \
                 helm repo add bitnami https://charts.bitnami.com/bitnami && \
                 helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx && \
                 helm repo update"

echo "🌐 Installation de l'Ingress Controller..."
run_ssh_command "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && \
                 helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
                 --namespace kube-system --wait --timeout 5m" 300

echo "🔧 Création du namespace..."
run_ssh_command "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && \
                 kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -"

# Copie du fichier values.yaml
echo "📄 Copie du fichier values.yaml..."
scp -i "$SSH_KEY_PATH" "$VALUES_FILE" "$EC2_USER@$EC2_IP:~/"

echo "🚀 Déploiement de WordPress..."
run_ssh_command "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && \
                 helm upgrade --install wordpress-test bitnami/wordpress \
                 --namespace $NAMESPACE \
                 --values ~/values.yaml \
                 --timeout 10m \
                 --wait" 600

echo "🔍 Vérification finale..."
run_ssh_command "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && \
                 kubectl get pods -n $NAMESPACE && \
                 kubectl get ingress -n $NAMESPACE"

echo "✅ Déploiement terminé. WordPress devrait être accessible à: http://35.180.33.10.nip.io"