#!/bin/bash
set -e

# Variables\DOMAIN_NAME=${1:-"mmustar.fr"}
EC2_USER="ubuntu"

# Fonctions
run_cmd() {
    echo "→ $1"
    eval "$1"
}

reset_environment() {
    echo "🔄 Réinitialisation de l'environnement K3s..."
    
    if ! command -v k3s >/dev/null; then
        echo "📥 Installation de K3s..."
        curl -sfL https://get.k3s.io | sh -
    else
        echo "♻️ Redémarrage de K3s..."
        sudo systemctl restart k3s
    fi

    sudo chmod 644 /etc/rancher/k3s/k3s.yaml
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    sleep 30

    if ! kubectl get nodes; then
        echo "❌ Échec de la connexion à K3s"
        exit 1
    fi
}

setup_helm() {
    echo "⎈ Installation de Helm..."
    if ! command -v helm; then
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
        chmod +x get_helm.sh && ./get_helm.sh && rm get_helm.sh
    fi
}

install_traefik() {
    echo "🚦 Mise à jour de Traefik..."
    helm upgrade --install traefik traefik/traefik \
        --namespace kube-system \
        --set ingressClass.enabled=true \
        --set ingressClass.isDefaultClass=true \
        --set metrics.prometheus.enabled=true \
        --atomic --timeout 5m
}

install_metrics_server() {
    echo "📊 Installation de Metrics Server..."
    helm upgrade --install metrics-server metrics-server/metrics-server \
        --namespace kube-system \
        --set args={--kubelet-insecure-tls} \
        --atomic --timeout 3m
}

install_prometheus_stack() {
    echo "📡 Déploiement de la stack Prometheus..."
    
    # Création du namespace monitoring
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
EOF
    
    # Installation de la stack
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --values /home/${EC2_USER}/prometheus-values.yaml \
        --atomic --timeout 15m
}

main() {
    reset_environment
    setup_helm
    helm repo add traefik https://helm.traefik.io/traefik
    helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    install_traefik
    install_metrics_server
    install_prometheus_stack
    
    echo "✅ Déploiement terminé !"
    kubectl get pods -n monitoring
}

main