#!/bin/bash
# Script de déploiement de la stack de monitoring avec réinitialisation
# Usage: ./deploy_mono.sh [DOMAIN_NAME]

set -e  # Arrêter le script en cas d'erreur

# Variables d'environnement
DOMAIN_NAME=${1:-"mmustar.fr"}
EC2_USER="ubuntu"

# Fonction pour exécuter des commandes avec affichage
run_cmd() {
    echo "Exécution: $1"
    eval "$1"
}

# Reset de l'environnement K3s
reset_environment() {
    echo "Réinitialisation de l'environnement..."
    
    if command -v k3s &> /dev/null; then
        echo "K3s est installé, vérification du service..."
        
        if systemctl status k3s &> /dev/null; then
            echo "Le service K3s est en cours d'exécution."
            
            if ! k3s kubectl get nodes &> /dev/null; then
                echo "Impossible d'accéder aux nœuds K3s. Redémarrage..."
                systemctl restart k3s
                sleep 30
            fi
        else
            echo "Le service K3s n'est pas en cours d'exécution. Démarrage..."
            systemctl start k3s
            sleep 30
        fi
    else
        echo "Installation de K3s..."
        curl -sfL https://get.k3s.io | sh -
        sleep 30
    fi
    
    sudo chmod 644 /etc/rancher/k3s/k3s.yaml
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    if ! kubectl get nodes &> /dev/null; then
        echo "Erreur: L'API Kubernetes n'est pas accessible."
        exit 1
    fi
    echo "K3s fonctionne correctement."
}

# Installer/mettre à jour Helm
setup_helm() {
    echo "Configuration de Helm..."
    if ! command -v helm &> /dev/null; then
        echo "Installation de Helm..."
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
        chmod +x get_helm.sh
        ./get_helm.sh
        rm -f get_helm.sh
    fi
    helm version
}

# Installer Traefik
install_traefik() {
    echo "Suppression forcée de Traefik..."
    helm uninstall traefik -n kube-system || true

    # Vérifier si Traefik est encore présent
    if k3s kubectl get all -n kube-system | grep -q traefik; then
        echo "Attente de 30 secondes pour suppression complète..."
        sleep 30
        k3s kubectl delete all --all -n kube-system --force --grace-period=0
        sleep 10
    fi

    # Vérification finale avant réinstallation
    if k3s kubectl get all -n kube-system | grep -q traefik; then
        echo "Erreur : Traefik est toujours présent, abandon de l'installation."
        exit 1
    fi

    # Maintenant on peut réinstaller proprement
    echo "Installation de Traefik..."
    helm repo remove traefik || true
    helm repo add traefik https://helm.traefik.io/traefik
    helm repo update
    
    if helm list -n kube-system | grep -q traefik || k3s kubectl get all -n kube-system | grep -q traefik; then
        echo "Traefik déjà installé, suppression..."
        k3s kubectl delete all --all -n kube-system --force --grace-period=0
        sleep 15
    fi
    
    helm install traefik traefik/traefik --namespace kube-system --timeout 5m \
        --set ingressClass.enabled=true --set ingressClass.isDefaultClass=true
    sleep 30
}

# Installer Prometheus
install_prometheus_stack() {
    echo "Installation de la stack Prometheus..."
    if [ ! -f "/home/$EC2_USER/prometheus-values.yaml" ]; then
        echo "Erreur: Fichier prometheus-values.yaml non trouvé"
        exit 1
    fi
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    helm install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring -f /home/$EC2_USER/prometheus-values.yaml --timeout 10m
    sleep 30
}

# Fonction principale
main() {
    echo "Déploiement de la stack de monitoring pour $DOMAIN_NAME"
    reset_environment
    setup_helm
    install_traefik
    install_prometheus_stack
    
    echo "Vérification de l'état des pods..."
    kubectl get pods -n monitoring
    kubectl get svc -n monitoring
    kubectl get ingress -n monitoring
    echo "Déploiement terminé !"
}

main
