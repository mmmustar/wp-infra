#!/bin/bash
# Script de déploiement WordPress pour test.mmustar.fr en utilisant Traefik
# Utilise uniquement cloudflare_test.crt et cloudflare_test.key

# Configuration de base
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ENV_DIR="$PROJECT_ROOT/environments/test"
SCRIPT_DIR="$PROJECT_ROOT/scripts"

SSH_KEY_PATH="/home/gnou/.ssh/test-aws-key-pair-new.pem"
EC2_USER="ubuntu"
DOMAIN_NAME="test.mmustar.fr"

# Récupérer l'IP à partir des outputs Terraform
EC2_IP=$(cd "$TEST_ENV_DIR" && terraform output -raw instance_public_ip)

# Fonction pour exécuter des commandes SSH sur l'instance
run_ssh() {
    ssh -o StrictHostKeyChecking=accept-new \
        -o ConnectTimeout=10 \
        -i "$SSH_KEY_PATH" \
        "$EC2_USER@$EC2_IP" "$1"
}

# Vérification des prérequis
check_prerequisites() {
    if [ ! -f "$SSH_KEY_PATH" ]; then
        echo "Erreur: Clé SSH non trouvée : $SSH_KEY_PATH"
        exit 1
    fi
    if [ -z "$EC2_IP" ]; then
        echo "Erreur: Impossible de récupérer l'IP de l'instance EC2"
        exit 1
    fi
}

# Récupération des secrets depuis AWS Secrets Manager
get_wordpress_secrets() {
    cd "$TEST_ENV_DIR" && aws secretsmanager get-secret-value \
        --secret-id "$(terraform output -raw wordpress_config_secret_arn)" \
        --query SecretString --output text > secrets.json
}

# Préparation du déploiement Kubernetes avec un fichier values.yaml personnalisé pour Traefik
prepare_k8s_deployment() {
    local db_host=$(jq -r .MYSQL_HOST secrets.json)
    local db_name=$(jq -r .MYSQL_DATABASE secrets.json)
    local db_user=$(jq -r .MYSQL_USER secrets.json)
    local db_password=$(jq -r .MYSQL_PASSWORD secrets.json)

    cat > wordpress-values.yaml <<EOF
wordpressUsername: admin
wordpressPassword: "$(openssl rand -base64 12)"
externalDatabase:
  host: $db_host
  user: $db_user
  password: "$db_password"
  database: $db_name
mariadb:
  enabled: false
service:
  type: ClusterIP
persistence:
  enabled: true
  storageClass: local-path
ingress:
  enabled: true
  hostname: $DOMAIN_NAME
  ingressClassName: traefik
  tls: true
  tlsSecret: wordpress-tls
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
EOF

    scp -o StrictHostKeyChecking=accept-new \
        -i "$SSH_KEY_PATH" \
        wordpress-values.yaml "$EC2_USER@$EC2_IP:/home/$EC2_USER/"
}

# Déploiement du certificat SSL avec cloudflare_test.crt et cloudflare_test.key
deploy_ssl_secret() {
    # Copier les fichiers de certificat et de clé sur l'instance
    scp -o StrictHostKeyChecking=accept-new \
        -i "$SSH_KEY_PATH" \
        "$SCRIPT_DIR/cloudflare_test.crt" "$EC2_USER@$EC2_IP:/home/$EC2_USER/"
    scp -o StrictHostKeyChecking=accept-new \
        -i "$SSH_KEY_PATH" \
        "$SCRIPT_DIR/cloudflare_test.key" "$EC2_USER@$EC2_IP:/home/$EC2_USER/"

    # Créer le secret TLS dans le namespace wordpress à partir des fichiers
    run_ssh '
        kubectl create secret tls wordpress-tls \
            --cert=/home/ubuntu/cloudflare_test.crt \
            --key=/home/ubuntu/cloudflare_test.key \
            -n wordpress --dry-run=client -o yaml | kubectl apply -f -
        rm /home/ubuntu/cloudflare_test.crt /home/ubuntu/cloudflare_test.key
    '
}

# Déploiement de WordPress via Helm
deploy_wordpress() {
    run_ssh '
        helm repo add bitnami https://charts.bitnami.com/bitnami
        helm repo update
        helm upgrade --install wordpress bitnami/wordpress \
            -n wordpress \
            -f /home/ubuntu/wordpress-values.yaml
    '
}

# Optionnel : Patch de l'Ingress pour forcer la section TLS (si nécessaire)
patch_ingress_tls() {
    run_ssh 'kubectl patch ingress wordpress -n wordpress --type merge -p '\''{"spec": {"tls": [{"hosts": ["test.mmustar.fr"], "secretName": "wordpress-tls"}]}}'\'''
}

# Fonction principale
main() {
    check_prerequisites
    get_wordpress_secrets
    prepare_k8s_deployment
    deploy_ssl_secret
    deploy_wordpress

    # Appliquer le patch TLS pour s'assurer que la section est présente
    patch_ingress_tls

    echo "WordPress est déployé et accessible via : https://$DOMAIN_NAME"
    echo "Identifiants (généré aléatoirement) :"
    run_ssh 'kubectl get secret wordpress -n wordpress -o jsonpath="{.data.wordpress-password}" | base64 -d'
}

main
