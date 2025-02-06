#!/bin/bash

# Définir le répertoire du projet
PROJECT_ROOT=$(realpath "$(dirname "$0")/../..")
ANSIBLE_DIR="$PROJECT_ROOT/ansible"
SECRETS_FILE="$PROJECT_ROOT/environments/test/secrets.json"

echo "🔄 Initialisation de Terraform..."
terraform init -input=false

# Appliquer Terraform pour récupérer les secrets
echo "🚀 Exécution de Terraform apply..."
terraform apply -auto-approve

# Vérifier si le fichier secrets.json existe après Terraform
if [ ! -f "$SECRETS_FILE" ]; then
    echo "❌ Erreur : Le fichier $SECRETS_FILE est introuvable après Terraform !"
    exit 1
fi

echo "✅ Le fichier $SECRETS_FILE a été généré avec succès."

# Déplacer le fichier de secrets dans Ansible
cp "$SECRETS_FILE" "$ANSIBLE_DIR/secrets.json"

# Se rendre dans le dossier Ansible et exécuter le playbook
echo "📂 Changement de répertoire vers Ansible : $ANSIBLE_DIR"
cd "$ANSIBLE_DIR" || exit 1

echo "🔧 Exécution d'Ansible..."
ansible-playbook -i inventory/hosts.yml site.yml -e "secrets_file=secrets.json"
