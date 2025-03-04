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

create_monitoring_namespace_and_secret() {
  echo "🔐 Création du namespace et du secret TLS..."
  
  # Vérifier que les fichiers de certificat existent
  if [ ! -f "/home/$EC2_USER/mono.crt" ] || [ ! -f "/home/$EC2_USER/mono.key" ]; then
    die "Fichiers de certificat mono.crt ou mono.key non trouvés"
  fi
  
  # Créer namespace monitoring
  kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
  
  # Créer le secret TLS
  kubectl create secret tls monitoring-tls \
    --cert=/home/$EC2_USER/mono.crt \
    --key=/home/$EC2_USER/mono.key \
    --namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
}

deploy_prometheus_stack() {
  echo "📡 Déploiement de la stack de monitoring..."
  
  # Vérifier que le fichier de valeurs existe
  if [ ! -f "/home/$EC2_USER/prometheus-values.yaml" ]; then
    die "Fichier prometheus-values.yaml non trouvé"
  fi
  
  helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    -f "/home/${EC2_USER}/prometheus-values.yaml" \
    --atomic \
    --timeout 20m
}

main() {
  # Configurer kubectl
  export KUBECONFIG="$KUBECONFIG"
  echo "🔧 Utilisation de KUBECONFIG: $KUBECONFIG"
  
  install_k3s
  install_helm
  setup_helm_repos
  create_monitoring_namespace_and_secret
  deploy_traefik
  deploy_prometheus_stack
  
  echo -e "\n✅ Déploiement réussi !"
  kubectl get pods -n monitoring
  
  echo -e "\n🌐 Accès URLs:"
  echo "- Grafana:      https://grafana-monitoring.mmustar.fr"
  echo "- Prometheus:   https://prometheus-monitoring.mmustar.fr"
  echo "- AlertManager: https://alertmanager-monitoring.mmustar.fr"
}

main