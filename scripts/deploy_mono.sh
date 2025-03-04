#!/bin/bash
# Script de déploiement de la stack de monitoring
# Usage: ./deploy_mono.sh [DOMAIN_NAME]

set -e  # Arrêter le script en cas d'erreur

# Variables d'environnement
DOMAIN_NAME=${1:-"test.mmustar.fr"}
EC2_USER="ubuntu"

# Fonction pour exécuter des commandes avec affichage
run_cmd() {
    echo "Exécution: $1"
    eval "$1"
}

# Vérifier/installer K3s
check_install_k3s() {
    echo "Vérification de l'installation de K3s..."
    
    if ! command -v k3s &> /dev/null; then
        echo "K3s n'est pas installé. Installation en cours..."
        run_cmd 'curl -sfL https://get.k3s.io | sh -'
        echo "Attente du démarrage de K3s (30s)..."
        sleep 30
    else
        echo "K3s est déjà installé."
    fi

    # Vérifier que le service K3s est en cours d'exécution
    if ! systemctl is-active --quiet k3s; then
        echo "Démarrage du service K3s..."
        run_cmd 'systemctl start k3s'
        echo "Attente du démarrage de K3s (30s)..."
        sleep 30
    fi
    
    # Créer un lien symbolique pour kubectl si nécessaire
    if ! command -v kubectl &> /dev/null; then
        echo "Configuration de kubectl..."
        run_cmd 'ln -sf $(which k3s) /usr/local/bin/kubectl'
    fi
}

# Installer/mettre à jour Helm
setup_helm() {
    echo "Configuration de Helm..."
    
    if ! command -v helm &> /dev/null; then
        echo "Installation de Helm..."
        run_cmd 'curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3'
        run_cmd 'chmod +x get_helm.sh'
        run_cmd './get_helm.sh'
        run_cmd 'rm get_helm.sh'
    else
        echo "Helm est déjà installé."
    fi
}

# Préparer l'environnement Kubernetes
prepare_k8s_env() {
    echo "Préparation de l'environnement Kubernetes..."
    
    # Configurer kubectl pour K3s
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    
    # Vérifier que les nœuds sont disponibles
    echo "Vérification des nœuds K3s..."
    MAX_RETRIES=10
    COUNT=0
    until kubectl get nodes &> /dev/null || [ $COUNT -eq $MAX_RETRIES ]; do
        echo "Attente de K3s... (tentative $((COUNT+1))/$MAX_RETRIES)"
        sleep 15
        ((COUNT++))
    done

    if [ $COUNT -eq $MAX_RETRIES ]; then
        echo "Erreur: K3s n'est pas accessible après plusieurs tentatives"
        exit 1
    fi
    
    # Créer le namespace monitoring
    echo "Création du namespace monitoring..."
    run_cmd 'kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -'
}

# Déployer les secrets TLS
deploy_tls_secrets() {
    echo "Déploiement des secrets TLS..."
    
    # Vérifier que les fichiers de certificat sont présents
    if [ ! -f "/home/$EC2_USER/cloudflare_test.crt" ] || [ ! -f "/home/$EC2_USER/cloudflare_test.key" ]; then
        echo "Erreur: Fichiers de certificat non trouvés"
        exit 1
    fi
    
    # Créer les secrets TLS
    run_cmd 'kubectl create secret tls grafana-tls --cert=/home/'$EC2_USER'/cloudflare_test.crt --key=/home/'$EC2_USER'/cloudflare_test.key -n monitoring --dry-run=client -o yaml | kubectl apply -f -'
    run_cmd 'kubectl create secret tls prometheus-tls --cert=/home/'$EC2_USER'/cloudflare_test.crt --key=/home/'$EC2_USER'/cloudflare_test.key -n monitoring --dry-run=client -o yaml | kubectl apply -f -'
    run_cmd 'kubectl create secret tls alertmanager-tls --cert=/home/'$EC2_USER'/cloudflare_test.crt --key=/home/'$EC2_USER'/cloudflare_test.key -n monitoring --dry-run=client -o yaml | kubectl apply -f -'
}

# Installer Traefik s'il n'est pas déjà installé
install_traefik() {
    echo "Vérification de l'installation de Traefik..."
    
    if ! kubectl get deployment -n kube-system traefik &> /dev/null; then
        echo "Installation de Traefik..."
        run_cmd 'helm repo add traefik https://helm.traefik.io/traefik'
        run_cmd 'helm repo update'
        run_cmd 'helm install traefik traefik/traefik \
            --namespace kube-system \
            --set ingressClass.enabled=true \
            --set ingressClass.isDefaultClass=true'
    else
        echo "Traefik est déjà installé."
    fi
}

# Installer la stack Prometheus
install_prometheus_stack() {
    echo "Installation de la stack Prometheus..."
    
    # Vérifier que le fichier values est présent
    if [ ! -f "/home/$EC2_USER/prometheus-values.yaml" ]; then
        echo "Erreur: Fichier prometheus-values.yaml non trouvé"
        exit 1
    fi
    
    # Ajouter le repo Helm et installer
    run_cmd 'helm repo add prometheus-community https://prometheus-community.github.io/helm-charts'
    run_cmd 'helm repo update'
    run_cmd 'helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        -f /home/'$EC2_USER'/prometheus-values.yaml \
        --version 45.27.2 \
        --timeout 10m'
}

# Fonction principale
main() {
    echo "========================================================="
    echo "Déploiement de la stack de monitoring pour $DOMAIN_NAME"
    echo "========================================================="
    
    # Vérifier/installer les prérequis
    check_install_k3s
    setup_helm
    
    # Déployer la stack
    prepare_k8s_env
    deploy_tls_secrets
    install_traefik
    install_prometheus_stack
    
    echo "========================================================="
    echo "Déploiement terminé! URLs d'accès:"
    echo "---------------------------------------------------------"
    echo "Grafana:      https://grafana.monitoring.$DOMAIN_NAME"
    echo "Prometheus:   https://prometheus.monitoring.$DOMAIN_NAME"
    echo "AlertManager: https://alertmanager.monitoring.$DOMAIN_NAME"
    echo "========================================================="
}

# Exécution du script
main