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

# Installation de Traefik avec configuration TLS explicite
install_traefik_properly() {
    echo "Configuration de Traefik avec support TLS amélioré..."
    
    if ! kubectl get deployment -n kube-system traefik >/dev/null 2>&1; then
        echo "Installation de Traefik..."
        
        # Créer un fichier de valeurs pour Traefik avec configuration TLS explicite
        cat > /home/$EC2_USER/traefik-values.yaml << EOF
entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"
    http:
      tls:
        certResolver: default
ingressClass:
  enabled: true
  isDefaultClass: true
EOF
        
        run_cmd 'helm repo add traefik https://helm.traefik.io/traefik'
        run_cmd 'helm repo update'
        run_cmd 'helm upgrade --install traefik traefik/traefik \
            --namespace kube-system \
            -f /home/'$EC2_USER'/traefik-values.yaml'
    else
        echo "Traefik est déjà installé, application de la configuration..."
        # Mettre à jour la configuration de Traefik existant
        cat > /home/$EC2_USER/traefik-values.yaml << EOF
entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"
    http:
      tls:
        certResolver: default
ingressClass:
  enabled: true
  isDefaultClass: true
EOF
        run_cmd 'helm upgrade traefik traefik/traefik \
            --namespace kube-system \
            -f /home/'$EC2_USER'/traefik-values.yaml'
    fi
}

# Déploiement de WordPress via Helm avec valeurs TLS explicites
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

# Création d'un Ingress explicite avec configuration TLS correcte
create_proper_ingress() {
    echo "Création d'un Ingress avec configuration TLS explicite..."
    
    cat > /home/$EC2_USER/wordpress-ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wordpress-secure
  namespace: wordpress
  annotations:
    kubernetes.io/ingress.class: "traefik"
    traefik.ingress.kubernetes.io/router.entrypoints: "websecure"
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  tls:
  - hosts:
    - $DOMAIN_NAME
    secretName: wordpress-tls
  rules:
  - host: $DOMAIN_NAME
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: wordpress
            port:
              number: 80
EOF

    run_cmd 'kubectl apply -f /home/'$EC2_USER'/wordpress-ingress.yaml'
}

# Fonction principale
main() {
    # Configurer kubectl pour K3s
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

    # Étapes de déploiement
    prepare_k8s_env
    deploy_ssl_secret
    install_traefik_properly
    deploy_wordpress
    
    # Au lieu d'utiliser le patch, créer un Ingress propre
    create_proper_ingress
    
    # Attendre quelques secondes pour que tout se propage
    echo "Attente de 10 secondes pour que les configurations se propagent..."
    sleep 10

    echo "WordPress est déployé et devrait être accessible via : https://$DOMAIN_NAME"
    echo "Pour obtenir le mot de passe admin, exécutez:"
    echo "kubectl get secret wordpress -n wordpress -o jsonpath=\"{.data.wordpress-password}\" | base64 -d"
    
    # Afficher le mot de passe
    PASSWORD=$(kubectl get secret wordpress -n wordpress -o jsonpath="{.data.wordpress-password}" | base64 -d)
    echo "Mot de passe admin: $PASSWORD"
    
    # Afficher l'état des ingress pour vérification
    echo "État des Ingress :"
    kubectl get ingress -n wordpress
}

# Exécution du script
main