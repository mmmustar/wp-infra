
# run.sh
#!/bin/bash
set -euo pipefail

# Vérification des variables d'environnement requises
if [[ -z "${AWS_ACCESS_KEY_ID:-}" ]] || [[ -z "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
    echo "Erreur: Les credentials AWS doivent être définis"
    exit 1
fi

# Vérification de la présence des fichiers nécessaires
required_files=("site.yml" "ansible.cfg" "inventory/hosts.yml")
for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "Erreur: Fichier requis manquant: $file"
        exit 1
    fi
done

# Vérification de la syntaxe
echo "Vérification de la syntaxe du playbook..."
if ! ansible-playbook --syntax-check site.yml; then
    echo "Erreur: Le playbook contient des erreurs de syntaxe"
    exit 1
fi

# Exécution du playbook
echo "Exécution du playbook..."
ansible-playbook site.yml -v

# Vérification du statut de sortie
if [[ $? -eq 0 ]]; then
    echo "Le playbook s'est exécuté avec succès"
else
    echo "Erreur lors de l'exécution du playbook"
    exit 1
fi