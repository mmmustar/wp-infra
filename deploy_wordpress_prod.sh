#!/bin/bash

EC2_IP="35.181.234.232"
EC2_USER="ubuntu"
SSH_KEY_PATH="/home/gnou/.ssh/test-aws-key-pair-new.pem"
DOMAIN="mmustar.fr"

ssh -o StrictHostKeyChecking=accept-new     -i ""     "@" << 'EOF'

# Créer le fichier de configuration Helm
cat << EOV > values.yaml
wordpressUsername: admin
wordpressPassword: admin
wordpressEmail: contact@
wordpressFirstName: Admin
wordpressLastName: User
wordpressBlogName: My Blog

service:
  type: ClusterIP
  ports:
    http: 80

ingress:
  enabled: true
  hostname: ""
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
    traefik.ingress.kubernetes.io/router.middlewares: default-redirect-https@kubernetescrd

mariadb:
  enabled: true
  auth:
    rootPassword: "db-root-pass"
    password: "db-user-pass"

extraEnvVars:
  - name: WORDPRESS_CONFIG_EXTRA
    value: |
      define('WP_HOME','https://');
      define('WP_SITEURL','https://');
EOV

# Déployer WordPress avec Helm
helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade --install my-wordpress bitnami/wordpress -f values.yaml

