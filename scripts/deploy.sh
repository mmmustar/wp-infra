#!/bin/bash

set -e  # Stoppe le script en cas d'erreur

BASE_DIR=$(dirname "$(realpath "$0")")/..
ANSIBLE_DIR="$BASE_DIR/ansible"
SSH_UPDATE_SCRIPT="$BASE_DIR/scripts/ssh-update.sh"

# Récupérer l'IP de l'instance EC2 depuis l’inventaire Ansible
EC2_IP=$(grep ansible_host "$ANSIBLE_DIR/inventory/hosts.yml" | awk '{print $2}')

echo "🚀 Mise à jour de la clé SSH pour l'EC2 ($EC2_IP)..."
bash "$SSH_UPDATE_SCRIPT" "$EC2_IP"

echo "🚀 1️⃣ Lancement d'Ansible pour installer K3s et Helm..."
ansible-playbook -i "$ANSIBLE_DIR/inventory/hosts.yml" "$ANSIBLE_DIR/site.yml"
