#!/bin/bash
# Script de déploiement WordPress pour l'environnement verif
# Version automatisée pour GitHub Actions

set -e  # Arrêter le script en cas d'erreur

# Variables d'environnement (seront définies par GitHub Actions ou peuvent être passées en arguments)
EC2_USER="ubuntu"
DOMAIN_NAME="test.mmustar.fr"

# Fonction pour exécuter des commandes sur l'instance
run_cmd() {
    echo "Exécution: $1"
    eval "$1"
}

# Préparation de l'environnement Kubernetes
prepare_k8s_env() {
    # Création du namespace WordPress s'il n'existe pas
    run_cmd 'kubectl create namespace wordpress --dry-run=client -o yaml | kubectl apply -f -'
}

# Déploiement du certificat SSL
deploy_ssl_secret() {
    echo "Déploiement du certificat SSL..."
    # Vérifier que les fichiers de certificat existent
    if [ ! -f "/home/$EC2_USER/cloudflare_test.crt" ] || [ ! -f "/home/$EC2_USER/cloudflare_test.key" ]; then
        echo "Erreur: Fichiers de certificat non trouvés"
        exit 1
    fi

    # Créer le secret TLS
    run_cmd 'kubectl create secret tls wordpress-tls \
        --cert=/home/'$EC2_USER'/cloudflare_test.crt \
        --key=/home/'$EC2_USER'/cloudflare_test.key \
        -n wordpress --dry-run=client -o yaml | kubectl apply -f -'
}

# Déploiement de WordPress via Helm
deploy_wordpress() {
    echo "Déploiement de WordPress..."
    # Vérifier que le fichier values.yaml existe
    if [ ! -f "/home/$EC2_USER/wordpress-values.yaml" ]; then
        echo "Erreur: Fichier wordpress-values.yaml non trouvé"
        exit 1
    fi

    # Ajout du repo Bitnami et mise à jour
    run_cmd 'helm repo add bitnami https://charts.bitnami.com/bitnami'
    run_cmd 'helm repo update'

    # Déploiement ou mise à jour de WordPress
    run_cmd 'helm upgrade --install wordpress bitnami/wordpress \
        -n wordpress \
        -f /home/'$EC2_USER'/wordpress-values.yaml \
        --timeout 10m'
}

# Patch de l'Ingress pour forcer la section TLS
patch_ingress_tls() {
    echo "Application du patch TLS pour l'Ingress..."
    run_cmd 'kubectl patch ingress wordpress -n wordpress --type merge -p '\''{"spec": {"tls": [{"hosts": ["'$DOMAIN_NAME'"], "secretName": "wordpress-tls"}]}}'\'''
}

# Installation de Traefik s'il n'est pas déjà installé
install_traefik_if_needed() {
    if ! kubectl get deployment -n kube-system traefik >/dev/null 2>&1; then
        echo "Installation de Traefik..."
        run_cmd 'helm repo add traefik https://helm.traefik.io/traefik'
        run_cmd 'helm repo update'
        run_cmd 'helm install traefik traefik/traefik \
            --namespace kube-system \
            --set ingressClass.enabled=true \
            --set ingressClass.isDefaultClass=true'
    else
        echo "Traefik est déjà installé, omission de cette étape."
    fi
}

# Fonction principale
main() {
    # Configurer kubectl pour K3s
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

    # Étapes de déploiement
    prepare_k8s_env
    install_traefik_if_needed
    deploy_ssl_secret
    deploy_wordpress
    patch_ingress_tls

    echo "WordPress est déployé et accessible via : https://$DOMAIN_NAME"
    echo "Pour obtenir le mot de passe admin, exécutez:"
    echo "kubectl get secret wordpress -n wordpress -o jsonpath=\"{.data.wordpress-password}\" | base64 -d"
    
    # Afficher le mot de passe
    PASSWORD=$(kubectl get secret wordpress -n wordpress -o jsonpath="{.data.wordpress-password}" | base64 -d)
    echo "Mot de passe admin: $PASSWORD"
}

# Exécution du script
main