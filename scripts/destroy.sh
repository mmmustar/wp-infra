#!/bin/bash

# Configuration
SSH_KEY_PATH="/home/gnou/.ssh/test-aws-key-pair-new.pem"
EC2_USER="ubuntu"
KNOWN_HOSTS="/home/gnou/.ssh/known_hosts"
EC2_IP="${1:-35.180.222.29}"  # Utiliser le premier argument ou l'IP par défaut

# Vérification des paramètres
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "Erreur: Clé SSH non trouvée: $SSH_KEY_PATH"
    exit 1
fi

# Fonction pour exécuter des commandes SSH
run_ssh() {
    ssh -o StrictHostKeyChecking=accept-new \
        -o ConnectTimeout=10 \
        -i "$SSH_KEY_PATH" \
        "$EC2_USER@$EC2_IP" "$1"
}

echo "🧹 Nettoyage de l'installation WordPress sur $EC2_IP..."

# Création du script de désinstallation sur l'EC2
cat > /tmp/uninstall.sh << 'EOFUNINSTALL'
#!/bin/bash
set -e

echo "🔄 Début de la désinstallation..."

# Arrêter et supprimer Nginx et PHP
echo "🛑 Arrêt des services web..."
systemctl stop nginx || true
systemctl disable nginx || true

# Supprimer les services web
echo "🗑️ Suppression des paquets web..."
apt remove --purge -y nginx nginx-common nginx-full || true
apt remove --purge -y php* || true
apt autoremove -y

# Supprimer les répertoires de WordPress
echo "🗑️ Suppression des fichiers WordPress..."
rm -rf /var/www/html/* || true
rm -rf /etc/nginx/sites-available/wordpress || true
rm -rf /etc/nginx/sites-enabled/wordpress || true
rm -rf /home/ubuntu/secrets.json || true
rm -rf /home/ubuntu/install_wp.sh || true

# Nettoyer les fichiers de configuration
echo "🧹 Nettoyage des configurations..."
rm -rf /etc/nginx || true
apt clean

# Vérifier si K3s est installé et le supprimer si c'est le cas
if command -v k3s &> /dev/null; then
    echo "🗑️ Suppression de K3s..."
    /usr/local/bin/k3s-uninstall.sh || true
fi

# Vérifier si Helm est installé et le supprimer si c'est le cas
if command -v helm &> /dev/null; then
    echo "🗑️ Suppression de Helm..."
    rm -rf /usr/local/bin/helm || true
    rm -rf ~/.helm || true
    rm -rf ~/.config/helm || true
fi

echo "✅ Désinstallation terminée avec succès!"
EOFUNINSTALL

echo "📤 Transfert du script de désinstallation vers l'EC2..."
scp -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=10 \
    -i "$SSH_KEY_PATH" \
    /tmp/uninstall.sh "$EC2_USER@$EC2_IP:/home/$EC2_USER/uninstall.sh"

echo "🔄 Exécution du script de désinstallation sur l'EC2..."
run_ssh "chmod +x /home/$EC2_USER/uninstall.sh && sudo /home/$EC2_USER/uninstall.sh"

echo "🧹 Suppression du script de désinstallation..."
run_ssh "rm -f /home/$EC2_USER/uninstall.sh"

echo "✅ Nettoyage terminé! Le serveur est prêt pour une nouvelle installation."