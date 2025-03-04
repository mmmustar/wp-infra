#!/bin/bash
set -eo pipefail

# Configuration
DOMAIN="mmustar.fr"
EC2_USER="ubuntu"
KUBECONFIG="/etc/rancher/k3s/k3s.yaml"

# Fonctions
die() {
  echo -e "\n❌ ERREUR: $*" >&2
  exit 1
}

install_k3s() {
  if ! command -v k3s >/dev/null; then
    echo "🔄 Installation de K3s..."
    curl -sfL https://get.k3s.io | sh -
    sudo chmod 644 "$KUBECONFIG"
  fi
  export KUBECONFIG
}

install_helm() {
  if ! command -v helm >/dev/null; then
    echo "⎈ Installation de Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  fi
}

setup_namespace() {
  if ! kubectl get ns monitoring >/dev/null 2>&1; then
    echo "📦 Création du namespace monitoring..."
    kubectl create ns monitoring
    sleep 3
  fi
}

deploy_traefik() {
  echo "🚦 Déploiement de Traefik..."
  helm upgrade --install traefik traefik/traefik \
    --namespace kube-system \
    --repo https://helm.traefik.io/traefik \
    --set ingressClass.enabled=true \
    --set ingressClass.isDefaultClass=true \
    --atomic
}

deploy_prometheus_stack() {
  echo "📡 Déploiement de la stack..."
  helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    -f "/home/${EC2_USER}/prometheus-values.yaml" \
    --repo https://prometheus-community.github.io/helm-charts \
    --atomic \
    --timeout 20m
}

main() {
  install_k3s
  install_helm
  setup_namespace
  deploy_traefik
  deploy_prometheus_stack
  
  echo -e "\n✅ Déploiement réussi ! Vérifications :"
  kubectl get pods -n monitoring
  echo -e "\nAccès :"
  echo "Grafana:      https://grafana-monitoring.${DOMAIN}"
  echo "Prometheus:   https://prometheus-monitoring.${DOMAIN}"
}

main