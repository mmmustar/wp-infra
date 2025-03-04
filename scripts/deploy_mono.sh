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

setup_helm_repos() {
  declare -A REPOS=(
    ["traefik"]="https://helm.traefik.io/traefik"
    ["prometheus-community"]="https://prometheus-community.github.io/helm-charts"
  )
  
  for repo in "${!REPOS[@]}"; do
    if ! helm repo list | grep -q "$repo"; then
      echo "➕ Ajout repository $repo"
      helm repo add "$repo" "${REPOS[$repo]}"
    fi
  done
  helm repo update
}

deploy_traefik() {
  echo "🚦 Déploiement de Traefik..."
  helm upgrade --install traefik traefik/traefik \
    --namespace kube-system \
    --set ingressClass.enabled=true \
    --set ingressClass.isDefaultClass=true \
    --atomic \
    --wait --timeout 5m
}

deploy_prometheus_stack() {
  echo "📡 Déploiement de la stack..."
  helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    -f "/home/${EC2_USER}/prometheus-values.yaml" \
    --atomic \
    --timeout 20m
}

main() {
  install_k3s
  install_helm
  setup_helm_repos
  deploy_traefik
  deploy_prometheus_stack
  
  echo -e "\n✅ Déploiement réussi !"
  kubectl get pods -A
}

main