#!/bin/bash

set -e  # Arrêter le script en cas d'erreur

echo "🚀 Démarrage du déploiement WordPress sur EC2..."

# 🔹 Vérifier et installer jq si nécessaire
if ! command -v jq &> /dev/null; then
    echo "🔹 Installation de jq..."
    apt update && apt install -y jq
fi

# 🔹 Vérifier et supprimer Apache s'il est installé
if systemctl list-units --type=service | grep -q apache2; then
    echo "🔹 Apache détecté. Suppression en cours..."
    systemctl stop apache2
    systemctl disable apache2
    systemctl mask apache2
    apt remove --purge -y apache2 apache2-utils apache2-bin libapache2-mod-php
    apt autoremove -y
    echo "✅ Apache a été supprimé avec succès."
fi

# 🔹 Vérifier si le port 80 est occupé et le libérer
if ss -tulnp | grep -q ':80'; then
    echo "❌ Le port 80 est occupé ! Tentative de libération..."
    fuser -k 80/tcp || true
    echo "✅ Le port 80 est maintenant libre."
fi

# 🔹 Détection automatique de la version de PHP-FPM installée
PHP_FPM_VERSION=$(ls /etc/init.d/ | grep -E '^php[0-9]+(\.[0-9]+)?-fpm' | head -n 1 | sed 's/-fpm//')

if [ -z "$PHP_FPM_VERSION" ]; then
    echo "❌ Aucune version de PHP-FPM trouvée. Installation de PHP depuis les dépôts officiels..."
    # Ajout du dépôt si nécessaire pour obtenir une version récente (ici php8.1)
    add-apt-repository -y ppa:ondrej/php
    apt update
    # Installation de PHP8.1 et des modules requis
    apt install -y php8.1-cli php8.1-common php8.1-fpm php8.1-mysql php8.1-curl php8.1-imagick php8.1-mbstring php8.1-zip php8.1-gd php8.1-intl php8.1-xml php8.1-xmlrpc php8.1-soap
    # Mise à jour de la variable
    PHP_FPM_VERSION="php8.1"
fi

PHP_FPM_SERVICE="${PHP_FPM_VERSION}-fpm"

echo "🔹 PHP-FPM détecté : $PHP_FPM_SERVICE"

# 🔹 Assurer l'activation et le démarrage de PHP-FPM
systemctl enable $PHP_FPM_SERVICE
systemctl start $PHP_FPM_SERVICE

# 🔹 Installation des paquets système et des modules PHP (version spécifiques)
apt update
apt install -y nginx mariadb-server unzip wget curl jq
# Si la version de PHP était déjà présente, on installe ses modules spécifiques
apt install -y ${PHP_FPM_VERSION}-cli ${PHP_FPM_VERSION}-common ${PHP_FPM_VERSION}-fpm ${PHP_FPM_VERSION}-mysql ${PHP_FPM_VERSION}-curl ${PHP_FPM_VERSION}-imagick ${PHP_FPM_VERSION}-mbstring ${PHP_FPM_VERSION}-zip ${PHP_FPM_VERSION}-gd ${PHP_FPM_VERSION}-intl ${PHP_FPM_VERSION}-xml ${PHP_FPM_VERSION}-xmlrpc ${PHP_FPM_VERSION}-soap

# 🔹 Vérification et création du fichier de secrets
SECRETS_FILE="/home/ubuntu/secrets.json"
if [ ! -f "$SECRETS_FILE" ]; then
    echo "❌ Erreur : Le fichier $SECRETS_FILE n'existe pas sur l'EC2 !"
    exit 1
fi

# 🔹 Lecture des secrets depuis le fichier JSON
MYSQL_DATABASE=$(jq -r '.MYSQL_DATABASE' "$SECRETS_FILE")
MYSQL_USER=$(jq -r '.MYSQL_USER' "$SECRETS_FILE")
MYSQL_PASSWORD=$(jq -r '.MYSQL_PASSWORD' "$SECRETS_FILE")
MYSQL_ROOT_PASSWORD=$(jq -r '.MYSQL_ROOT_PASSWORD' "$SECRETS_FILE")
MYSQL_HOST=$(jq -r '.MYSQL_HOST' "$SECRETS_FILE")
MYSQL_PORT=$(jq -r '.MYSQL_PORT' "$SECRETS_FILE")

# 🔹 Détection de l'environnement et définition du domaine
if [ "$DEPLOY_ENV" = "prod" ]; then
    domain_name="mmustar.fr"
else
    domain_name="test.mmustar.fr"
fi
wordpress_dir="/var/www/html"

echo "🔹 Déploiement pour le domaine : $domain_name"

# 🔹 Configuration de MariaDB
echo "🔹 Configuration de MariaDB..."
systemctl start mariadb
systemctl enable mariadb

mysql -u root -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;"
mysql -u root -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';"
mysql -u root -e "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"

# 🔹 Téléchargement et installation de WordPress
echo "🔹 Téléchargement de WordPress..."
WP_URL="https://wordpress.org/latest.tar.gz"
if ! wget --spider $WP_URL; then
    echo "❌ Impossible d'accéder à wordpress.org. Utilisation d'une URL alternative..."
    WP_URL="https://fr.wordpress.org/latest-fr_FR.tar.gz"
fi

wget $WP_URL -P /tmp/
tar -xzf /tmp/latest.tar.gz -C /var/www/
# Copie des fichiers WordPress dans le dossier cible
rsync -av --remove-source-files /var/www/wordpress/ $wordpress_dir/
rm -rf /var/www/wordpress /tmp/latest.tar.gz

# 🔹 Configuration de WordPress : copie du fichier de config
cp $wordpress_dir/wp-config-sample.php $wordpress_dir/wp-config.php
sed -i "s/database_name_here/$MYSQL_DATABASE/" $wordpress_dir/wp-config.php
sed -i "s/username_here/$MYSQL_USER/" $wordpress_dir/wp-config.php
sed -i "s/password_here/$MYSQL_PASSWORD/" $wordpress_dir/wp-config.php

# 🔹 Forcer l'utilisation du protocole HTTP pour WordPress
# Ces définitions empêchent WordPress de tenter une connexion HTTPS pour son REST API
sed -i "/^\/\* That's all, stop editing! \*\//i define('WP_HOME', 'http://$domain_name');\ndefine('WP_SITEURL', 'http://$domain_name');" $wordpress_dir/wp-config.php

# 🔹 Configuration de Nginx
echo "🔹 Configuration de Nginx..."
tee /etc/nginx/sites-available/wordpress > /dev/null <<EOF
server {
    listen 80;
    server_name $domain_name www.$domain_name;
    root /var/www/html;

    # Optimisation des performances
    client_max_body_size 64M;

    # Compression gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    index index.php index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/run/php/${PHP_FPM_VERSION}-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
    }

    # Cache statique
    location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
        expires max;
        log_not_found off;
    }
}
EOF

ln -sf /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default  # Suppression de la configuration par défaut

# 🔹 Vérification et redémarrage de Nginx
if nginx -t; then
    echo "🔹 Redémarrage de Nginx..."
    systemctl restart nginx
else
    echo "❌ Erreur dans la configuration Nginx !"
    exit 1
fi

# 🔹 Redémarrage de PHP-FPM
systemctl restart $PHP_FPM_SERVICE
if systemctl is-active --quiet $PHP_FPM_SERVICE; then
    echo "✅ PHP-FPM fonctionne correctement."
else
    echo "❌ Erreur : PHP-FPM ne fonctionne pas !"
    exit 1
fi

# 🔹 Configuration des permissions sur les fichiers WordPress
chown -R www-data:www-data $wordpress_dir
find $wordpress_dir -type d -exec chmod 755 {} \;
find $wordpress_dir -type f -exec chmod 644 {} \;

# 🔹 Vérification finale
echo "✅ WordPress est installé sur http://$domain_name"
