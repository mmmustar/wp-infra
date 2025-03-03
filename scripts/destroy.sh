#!/bin/bash
# Script de destruction du déploiement WordPress pour test.mmustar.fr

# Configuration de base
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ENV_DIR="$PROJECT_ROOT/environments/test"

SSH_KEY_PATH="/home/gnou/.ssh/test-aws-key-pair-new.pem"
EC2_USER="ubuntu"
DOMAIN_NAME="test.mmustar.fr"

# Récupérer l'IP à partir des outputs Terraform
EC2_IP=$(cd "$TEST_ENV_DIR" && terraform output -raw instance_public_ip)

# Fonction pour exécuter des commandes SSH avec gestion d'erreurs
run_ssh() {
    ssh -o StrictHostKeyChecking=accept-new \
        -o ConnectTimeout=10 \
        -i "$SSH_KEY_PATH" \
        "$EC2_USER@$EC2_IP" "$1"
}

# Vérification des prérequis
check_prerequisites() {
    if [ ! -f "$SSH_KEY_PATH" ]; then
        echo "Erreur: Clé SSH non trouvée : $SSH_KEY_PATH"
        exit 1
    fi
    if [ -z "$EC2_IP" ]; then
        echo "Erreur: Impossible de récupérer l'IP de l'instance EC2"
        exit 1
    fi
}

main() {
    check_prerequisites

    echo "Tentative de désinstallation du release Helm 'wordpress' dans le namespace wordpress..."
    run_ssh 'helm uninstall wordpress -n wordpress || echo "Release wordpress non trouvé"'

    echo "Suppression de l'Ingress 'wordpress' (si existant)..."
    run_ssh 'kubectl delete ingress wordpress -n wordpress --ignore-not-found'

    echo "Suppression du secret TLS 'wordpress-tls' (si existant)..."
    run_ssh 'kubectl delete secret wordpress-tls -n wordpress --ignore-not-found'

    # Optionnel : supprimer le namespace wordpress s'il n'est plus utile
    # echo "Suppression du namespace 'wordpress'..."
    # run_ssh 'kubectl delete namespace wordpress --ignore-not-found'

    echo "Destruction terminée sur test.mmustar.fr"
}

main
