#!/bin/bash

# Configuration par défaut
SSH_KEY_PATH="/home/gnou/.ssh/test-aws-key-pair-new.pem"
EC2_USER="ubuntu"
KNOWN_HOSTS="/home/gnou/.ssh/known_hosts"

# Fonction d'aide
show_usage() {
    echo "Usage: $0 [OPTIONS] EC2_IP_ADDRESS"
    echo "Options:"
    echo "  -k, --key PATH    Chemin vers la clé SSH (default: $SSH_KEY_PATH)"
    echo "  -u, --user USER   Utilisateur EC2 (default: $EC2_USER)"
    echo "  -h, --help        Affiche cette aide"
    exit 1
}

# Traitement des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -k|--key)
            SSH_KEY_PATH="$2"
            shift 2
            ;;
        -u|--user)
            EC2_USER="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            EC2_IP="$1"
            shift
            ;;
    esac
done

# Vérification des paramètres requis
if [ -z "$EC2_IP" ]; then
    echo "Erreur: Adresse IP de l'instance EC2 manquante"
    show_usage
fi

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "Erreur: Clé SSH non trouvée: $SSH_KEY_PATH"
    exit 1
fi

# Fonction pour vérifier si l'instance est accessible
check_instance() {
    timeout 5 nc -zv $EC2_IP 22 &>/dev/null
    return $?
}

# Attendre que l'instance soit accessible
echo "Vérification de l'accessibilité de l'instance..."
ATTEMPTS=0
MAX_ATTEMPTS=10

while ! check_instance; do
    ATTEMPTS=$((ATTEMPTS + 1))
    if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
        echo "Erreur: Impossible de se connecter à l'instance après $MAX_ATTEMPTS tentatives"
        exit 1
    fi
    echo "Instance non accessible, nouvelle tentative dans 5 secondes... ($ATTEMPTS/$MAX_ATTEMPTS)"
    sleep 5
done

# Supprimer l'ancienne clé host si elle existe
if ssh-keygen -F $EC2_IP >/dev/null 2>&1; then
    echo "Suppression de l'ancienne clé host..."
    ssh-keygen -f "$KNOWN_HOSTS" -R "$EC2_IP" >/dev/null 2>&1
fi

# Tentative de connexion
echo "Connexion à l'instance $EC2_IP..."
ssh -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=10 \
    -i "$SSH_KEY_PATH" \
    "$EC2_USER@$EC2_IP"

exit_code=$?
if [ $exit_code -ne 0 ]; then
    echo "Erreur lors de la connexion (code: $exit_code)"
    exit $exit_code
fi