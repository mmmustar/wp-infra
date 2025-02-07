#!/bin/bash

# Configuration par défaut
SSH_KEY_PATH="/home/gnou/.ssh/test-aws-key-pair-new.pem"
EC2_USER="ubuntu"
KNOWN_HOSTS="/home/gnou/.ssh/known_hosts"

show_usage() {
    echo "Usage: $0 [OPTIONS] EC2_IP_ADDRESS"
    exit 1
}

# Vérification des paramètres requis
if [ -z "$1" ]; then
    echo "Erreur: Adresse IP de l'instance EC2 manquante"
    exit 1
fi

EC2_IP="$1"

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "Erreur: Clé SSH non trouvée: $SSH_KEY_PATH"
    exit 1
fi

# Suppression de l'ancienne clé host si elle existe
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
