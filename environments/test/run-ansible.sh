#!/bin/bash

# Définition des chemins
PROJECT_ROOT=$(realpath "$(dirname "$0")/../..")
SECRETS_FILE="$PROJECT_ROOT/environments/test/secrets.json"

echo "🔄 Initialisation de Terraform..."
terraform init -input=false

# Exécuter Terraform pour récupérer les secrets
echo "🚀 Exécution de Terraform apply..."
terraform apply -auto-approve

# Vérifier si secrets.json existe après Terraform
if [ ! -f "$SECRETS_FILE" ]; then
    echo "❌ Erreur : Le fichier $SECRETS_FILE est introuvable après Terraform !"
    exit 1
fi

echo "✅ Le fichier $SECRETS_FILE a été généré avec succès."

# Exporter les variables d'environnement depuis le JSON
echo "🔑 Exportation des secrets..."
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

echo "✅ Exportation des secrets terminée."

# Se rendre dans le dossier Ansible et exécuter le playbook
ANSIBLE_DIR="$PROJECT_ROOT/ansible"
echo "📂 Changement de répertoire vers Ansible : $ANSIBLE_DIR"
cd "$ANSIBLE_DIR" || exit 1

echo "🔧 Exécution d'Ansible..."
ansible-playbook -i inventory/hosts.yml site.yml
#cool