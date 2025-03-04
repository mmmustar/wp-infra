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
    
    # Vérifier si K3s est installé
    if command -v k3s &> /dev/null; then
        echo "K3s est installé, vérification du service..."
        
        # Vérifier si le service K3s fonctionne
        if systemctl status k3s &> /dev/null; then
            echo "Le service K3s est en cours d'exécution."
            
            # Essayer d'accéder aux nœuds K3s
            if ! k3s kubectl get nodes &> /dev/null; then
                echo "Impossible d'accéder aux nœuds K3s. Tentative de redémarrage du service..."
                systemctl restart k3s
                sleep 30
            fi
        else
            echo "Le service K3s n'est pas en cours d'exécution. Démarrage..."
            systemctl start k3s
            sleep 30
        fi
    else
        echo "K3s n'est pas installé. Installation..."
        curl -sfL https://get.k3s.io | sh -
        sleep 30
    fi
    
    # Vérification finale
    if ! k3s kubectl get nodes &> /dev/null; then
        echo "K3s n'est toujours pas accessible. Réinstallation complète..."
        systemctl stop k3s || true
        systemctl disable k3s || true
        
        # Supprimer K3s proprement
        /usr/local/bin/k3s-uninstall.sh || true
        
        # Réinstaller K3s
        curl -sfL https://get.k3s.io | sh -
        sleep 45
        
        # Vérification finale après réinstallation
        if ! k3s kubectl get nodes &> /dev/null; then
            echo "Échec de la réinstallation de K3s. Veuillez vérifier manuellement."
            exit 1
        fi
    fi
    
    echo "K3s fonctionne correctement."
    
    # Créer un lien symbolique pour kubectl
    ln -sf $(which k3s) /usr/local/bin/kubectl || true
    
    # Désinstaller Traefik s'il est installé
    if k3s kubectl get deployment -n kube-system traefik &> /dev/null; then
        echo "Désinstallation de Traefik..."
        helm uninstall traefik -n kube-system || true
        sleep 15
    fi
    
    # Supprimer le namespace monitoring s'il existe
    if k3s kubectl get namespace monitoring &> /dev/null; then
        echo "Suppression du namespace monitoring..."
        k3s kubectl delete namespace monitoring --timeout=5m || true
        sleep 15
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
        run_cmd 'rm -f get_helm.sh'
    else
        echo "Helm est déjà installé."
    fi
}

# Préparer l'environnement Kubernetes
prepare_k8s_env() {
    echo "Préparation de l'environnement Kubernetes..."
    
    # Configurer kubectl pour K3s
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    
    # Créer le namespace monitoring
    echo "Création du namespace monitoring..."
    run_cmd 'k3s kubectl create namespace monitoring --dry-run=client -o yaml | k3s kubectl apply -f -'
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
    run_cmd 'k3s kubectl create secret tls grafana-tls --cert=/home/'$EC2_USER'/cloudflare_test.crt --key=/home/'$EC2_USER'/cloudflare_test.key -n monitoring --dry-run=client -o yaml | k3s kubectl apply -f -'
    run_cmd 'k3s kubectl create secret tls prometheus-tls --cert=/home/'$EC2_USER'/cloudflare_test.crt --key=/home/'$EC2_USER'/cloudflare_test.key -n monitoring --dry-run=client -o yaml | k3s kubectl apply -f -'
    run_cmd 'k3s kubectl create secret tls alertmanager-tls --cert=/home/'$EC2_USER'/cloudflare_test.crt --key=/home/'$EC2_USER'/cloudflare_test.key -n monitoring --dry-run=client -o yaml | k3s kubectl apply -f -'
}

# Installer Traefik
install_traefik() {
    echo "Installation de Traefik..."
    
    run_cmd 'helm repo add traefik https://helm.traefik.io/traefik'
    run_cmd 'helm repo update'
    
    run_cmd 'helm install traefik traefik/traefik \
        --namespace kube-system \
        --timeout 5m \
        --set ingressClass.enabled=true \
        --set ingressClass.isDefaultClass=true'
    
    # Attendre que Traefik soit prêt
    echo "Attente que Traefik soit prêt..."
    sleep 30
    k3s kubectl rollout status deployment traefik -n kube-system --timeout=3m || true
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
    run_cmd 'helm install prometheus prometheus-community/kube-prometheus-stack \
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
    
    # Reset de l'environnement
    reset_environment
    
    # Vérifier/installer les prérequis
    setup_helm
    
    # Déployer la stack
    prepare_k8s_env
    deploy_tls_secrets
    install_traefik
    install_prometheus_stack
    
    echo "========================================================="
    echo "Déploiement terminé! URLs d'accès:"
    echo "---------------------------------------------------------"
    echo "Grafana:      https://grafana-monitoring.mmustar.fr"
    echo "Prometheus:   https://prometheus-monitoring.mmustar.fr"
    echo "AlertManager: https://alertmanager-monitoring.mmustar.fr"
    echo "========================================================="
    echo "Vérifiez que les entrées DNS correspondantes sont configurées dans Cloudflare."
    echo "N'oubliez pas que les identifiants par défaut pour Grafana sont:"
    echo "Utilisateur: admin"
    echo "Mot de passe: celui défini dans le secret 'MONO_PASSWORD' sur GitHub"
    echo "========================================================="
}

# Exécution du script
main