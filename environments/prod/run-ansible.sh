#!/bin/bash

PROJECT_ROOT=$(realpath "$(dirname "$0")/../..")
SECRETS_FILE="$PROJECT_ROOT/environments/prod/secrets.json"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"

echo "🔄 Initialisation de Terraform..."
terraform init -input=false

echo "🚀 Déploiement de l'infrastructure production..."
terraform apply -auto-approve -var="environment=prod"

if [ ! -f "$SECRETS_FILE" ]; then
    echo "❌ Erreur : Secrets non générés !"
    exit 1
fi

echo "🔑 Exportation des variables d'environnement..."
export WORDPRESS_DB_HOST=$(jq -r '.MYSQL_HOST' < "$SECRETS_FILE")
export WORDPRESS_DB_USER=$(jq -r '.MYSQL_USER' < "$SECRETS_FILE")
export WORDPRESS_DB_PASSWORD=$(jq -r '.MYSQL_PASSWORD' < "$SECRETS_FILE")
export WORDPRESS_DB_NAME=$(jq -r '.MYSQL_DATABASE' < "$SECRETS_FILE")
export MYSQL_PORT=$(jq -r '.MYSQL_PORT' < "$SECRETS_FILE")
export WP_ID=$(jq -r '.WP_ID' < "$SECRETS_FILE")
export AUTH_KEY=$(jq -r '.AUTH_KEY' < "$SECRETS_FILE")
export SECURE_AUTH_KEY=$(jq -r '.SECURE_AUTH_KEY' < "$SECRETS_FILE")
export LOGGED_IN_KEY=$(jq -r '.LOGGED_IN_KEY' < "$SECRETS_FILE")
export NONCE_KEY=$(jq -r '.NONCE_KEY' < "$SECRETS_FILE")
export AUTH_SALT=$(jq -r '.AUTH_SALT' < "$SECRETS_FILE")
export SECURE_AUTH_SALT=$(jq -r '.SECURE_AUTH_SALT' < "$SECRETS_FILE")
export LOGGED_IN_SALT=$(jq -r '.LOGGED_IN_SALT' < "$SECRETS_FILE")
export NONCE_SALT=$(jq -r '.NONCE_SALT' < "$SECRETS_FILE")

cd "$ANSIBLE_DIR" || exit 1
ansible-playbook -i inventory/hosts_prod.yml site.yml