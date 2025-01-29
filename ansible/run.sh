#!/bin/bash

# Exporter les variables d'environnement AWS
export AWS_ACCESS_KEY_ID="votre_access_key_id"
export AWS_SECRET_ACCESS_KEY="votre_secret_access_key"

# Exécuter le playbook Ansible
ansible-playbook -i site.yml