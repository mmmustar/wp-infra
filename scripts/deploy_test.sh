#!/bin/bash

set -e  # Arrêter le script en cas d'erreur

# 🔹 Variables
EC2_IP="35.180.222.29"  # IP de l'EC2
SSH_KEY="~/.ssh/test-aws-key-pair-new.pem"  # Remplace par ta clé AWS
REMOTE_USER="ubuntu"
SCRIPT_PATH="./scripts/deploy_wordpress.sh"
SECRETS_PATH="./environments/test/secrets.json"

# 🔹 Vérifier que le fichier secrets.json existe
if [ ! -f "$SECRETS_PATH" ]; then
    echo "❌ Erreur : Le fichier $SECRETS_PATH n'existe pas !"
    exit 1
fi

# 🔹 Copier le script et le fichier de secrets sur l'EC2
echo "🚀 Copie des fichiers sur l'EC2..."
scp -i $SSH_KEY $SCRIPT_PATH $SECRETS_PATH $REMOTE_USER@$EC2_IP:/home/ubuntu/

# 🔹 Exécuter le script sur l'EC2
echo "🚀 Exécution du script sur l'EC2..."
ssh -i $SSH_KEY $REMOTE_USER@$EC2_IP "chmod +x /home/ubuntu/deploy_wordpress.sh && sudo /home/ubuntu/deploy_wordpress.sh"

echo "✅ Déploiement terminé sur http://test.mmustar.fr"
