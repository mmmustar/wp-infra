#!/bin/bash

set -e  # Arrêt en cas d'erreur

# Configuration
SSH_KEY_PATH="/home/gnou/.ssh/test-aws-key-pair-new.pem"
EC2_USER="ubuntu"
EC2_IP="35.180.33.10"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VALUES_FILE="$SCRIPT_DIR/values.yaml"
NAMESPACE="wordpress"
RELEASE_NAME="wordpress"
AWS_SECRET_NAME="book"
AWS_REGION="eu-west-3"
KNOWN_HOSTS="/home/gnou/.ssh/known_hosts"
TEMP_VARS_FILE="/tmp/wordpress_vars.sh"

# Vérification du fichier values.yaml
if [ ! -f "$VALUES_FILE" ]; then
    echo "❌ Erreur : values.yaml non trouvé dans $VALUES_FILE"
    exit 1
fi

# Désactivation de la configuration SSL conflictuelle sur l'EC2 (si présente)
echo "🚫 Désactivation de la configuration SSL conflictuelle sur l'EC2..."
ssh -i "$SSH_KEY_PATH" "$EC2_USER@$EC2_IP" "sudo mv /etc/nginx/conf.d/ssl.conf /etc/nginx/conf.d/ssl.conf.bak || true"

# Récupération des secrets depuis AWS Secrets Manager
echo "🔑 Récupération des secrets depuis AWS Secrets Manager..."
SECRETS_JSON=$(aws secretsmanager get-secret-value --secret-id "$AWS_SECRET_NAME" --region "$AWS_REGION" --query SecretString --output text)

# Extraction des valeurs des secrets
MYSQL_HOST=$(echo $SECRETS_JSON | jq -r .MYSQL_HOST)
MYSQL_DATABASE=$(echo $SECRETS_JSON | jq -r .MYSQL_DATABASE)
MYSQL_USER=$(echo $SECRETS_JSON | jq -r .MYSQL_USER)
MYSQL_PASSWORD=$(echo $SECRETS_JSON | jq -r .MYSQL_PASSWORD)
MYSQL_PORT=3306  # Port déf
