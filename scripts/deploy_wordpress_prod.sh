#!/bin/bash

set -e  # Arrêt en cas d'erreur

# Configuration
SSH_KEY_PATH="/home/gnou/.ssh/test-aws-key-pair-new.pem"
EC2_USER="ubuntu"
EC2_IP="35.181.234.232"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VALUES_FILE="$SCRIPT_DIR/values.yaml"
NAMESPACE="wordpress"
RELEASE_NAME="wordpress"
AWS_SECRET_NAME="book"
AWS_REGION="eu-west-3"
KNOWN_HOSTS="/home/gnou/.ssh/known_hosts"
TEMP_VARS_FILE="/tmp/wordpress_vars.sh"

# Vérification du fichier values.yaml
if [ ! -f "$VALUES_FILE" ]; then
    echo "❌ Erreur : values.yaml non trouvé dans $VALUES_FILE"
    exit 1
fi

# Récupération des secrets depuis AWS Secrets Manager
echo "🔑 Récupération des secrets depuis AWS Secrets Manager..."
SECRETS_JSON=$(aws secretsmanager get-secret-value --secret-id "$AWS_SECRET_NAME" --region "$AWS_REGION" --query SecretString --output text)

# Extraction des valeurs des secrets
MYSQL_HOST=$(echo $SECRETS_JSON | jq -r .MYSQL_HOST)
MYSQL_DATABASE=$(echo $SECRETS_JSON | jq -r .MYSQL_DATABASE)
MYSQL_USER=$(echo $SECRETS_JSON | jq -r .MYSQL_USER)
MYSQL_PASSWORD=$(echo $SECRETS_JSON | jq -r .MYSQL_PASSWORD)
MYSQL_PORT=3306  # Port défini en dur

# Affichage des valeurs pour le débogage
echo "🔍 Valeurs extraites :"
echo "  MYSQL_HOST = $MYSQL_HOST"
echo "  MYSQL_DATABASE = $MYSQL_DATABASE"
echo "  MYSQL_USER = $MYSQL_USER"
echo "  MYSQL_PASSWORD = $MYSQL_PASSWORD"
echo "  MYSQL_PORT = $MYSQL_PORT (Type: $(echo $MYSQL_PORT | jq type))"

# Nettoyage de l'installation précédente
echo "🧹 Nettoyage de l'installation précédente..."
helm uninstall "$RELEASE_NAME" --namespace "$NAMESPACE" || true
kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
kubectl wait --for=delete namespace/"$NAMESPACE" --timeout=60s || true

# Création du namespace
echo "🔧 Création du namespace Kubernetes..."
kubectl create namespace "$NAMESPACE"

# Création du secret Kubernetes pour la base de données
echo "🔧 Création du secret Kubernetes pour la base de données..."
kubectl create secret generic wordpress-db-secret \
  --from-literal=database="$MYSQL_DATABASE" \
  --from-literal=host="$MYSQL_HOST" \
  --from-literal=user="$MYSQL_USER" \
  --from-literal=password="$MYSQL_PASSWORD" \
  --from-literal=port="$MYSQL_PORT" \
  --namespace "$NAMESPACE"

# Vérification des secrets Kubernetes
echo "🔍 Vérification des secrets Kubernetes..."
kubectl get secrets -n "$NAMESPACE"

# Copie du fichier values.yaml sur l'EC2
echo "📤 Copie du fichier values.yaml sur l'EC2..."
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "❌ Erreur : clé SSH non trouvée dans $SSH_KEY_PATH"
    exit 1
fi

# Suppression de l'ancienne clé host si elle existe
if ssh-keygen -F $EC2_IP >/dev/null 2>&1; then
    echo "Suppression de l'ancienne clé host..."
    ssh-keygen -f "$KNOWN_HOSTS" -R "$EC2_IP" >/dev/null 2>&1
fi

scp -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=10 \
    -i "$SSH_KEY_PATH" \
    "$VALUES_FILE" "$EC2_USER@$EC2_IP:/home/$EC2_USER/values.yaml"

# Copie des certificats Cloudflare si présents
if [ -f "$SCRIPT_DIR/cloudflare_origin.crt" ] && [ -f "$SCRIPT_DIR/cloudflare_origin.key" ]; then
    scp -o StrictHostKeyChecking=accept-new \
        -o ConnectTimeout=10 \
        -i "$SSH_KEY_PATH" \
        "$SCRIPT_DIR/cloudflare_origin.crt" "$SCRIPT_DIR/cloudflare_origin.key" "$EC2_USER@$EC2_IP:/home/$EC2_USER/"
fi

# Création du fichier temporaire contenant les variables
echo "MYSQL_HOST=\"$MYSQL_HOST\"" > $TEMP_VARS_FILE
echo "MYSQL_DATABASE=\"$MYSQL_DATABASE\"" >> $TEMP_VARS_FILE
echo "MYSQL_USER=\"$MYSQL_USER\"" >> $TEMP_VARS_FILE
echo "MYSQL_PASSWORD=\"$MYSQL_PASSWORD\"" >> $TEMP_VARS_FILE
echo "MYSQL_PORT=$MYSQL_PORT" >> $TEMP_VARS_FILE

# Copie du fichier temporaire contenant les variables sur l'EC2
scp -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=10 \
    -i "$SSH_KEY_PATH" \
    "$TEMP_VARS_FILE" "$EC2_USER@$EC2_IP:/home/$EC2_USER/wordpress_vars.sh"

# Connexion SSH à l'EC2 pour le déploiement
echo "🚀 Déploiement sur l'EC2..."
ssh -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=10 \
    -i "$SSH_KEY_PATH" \
    "$EC2_USER@$EC2_IP" << 'ENDSSH'
set -e

# Chargement des variables
source /home/ubuntu/wordpress_vars.sh

# Variables
NAMESPACE="wordpress"
RELEASE_NAME="wordpress"
VALUES_FILE="/home/ubuntu/values.yaml"

# Installation des dépendances
echo "📦 Installation des dépendances..."
sudo apt update
sudo apt install -y curl apt-transport-https ca-certificates jq

# Configuration de K3s
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
sudo chmod 644 /etc/rancher/k3s/k3s.yaml

# Installation de Helm si nécessaire
if ! command -v helm &> /dev/null; then
    echo "🔧 Installation de Helm..."
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
fi

# Configuration des repositories Helm
echo "📦 Configuration des repositories Helm..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Affichage des valeurs pour le débogage
echo "🔍 Valeurs utilisées pour Helm :"
echo "  MYSQL_HOST = $MYSQL_HOST"
echo "  MYSQL_DATABASE = $MYSQL_DATABASE"
echo "  MYSQL_USER = $MYSQL_USER"
echo "  MYSQL_PASSWORD = $MYSQL_PASSWORD"
echo "  MYSQL_PORT = $MYSQL_PORT"

# Déploiement ou mise à jour de WordPress avec une base de données externe
echo "🚀 Déploiement de WordPress..."
helm upgrade --install $RELEASE_NAME bitnami/wordpress \
    --namespace $NAMESPACE \
    --values $VALUES_FILE \
    --set externalDatabase.host="$MYSQL_HOST" \
    --set externalDatabase.user="$MYSQL_USER" \
    --set externalDatabase.password="$MYSQL_PASSWORD" \
    --set externalDatabase.database="$MYSQL_DATABASE" \
    --set externalDatabase.port=$MYSQL_PORT \
    --set ingress.ingressClassName=nginx

# Vérification du déploiement
echo "✅ Vérification du déploiement..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=wordpress -n $NAMESPACE --timeout=300s

# Affichage des ressources
echo "📊 État des ressources :"
kubectl get pods,svc,ingress -n $NAMESPACE

# Affichage des logs du pod
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=wordpress -o jsonpath="{.items[0].metadata.name}")
echo "📄 Logs du pod : $POD_NAME"
kubectl logs -f $POD_NAME -n $NAMESPACE
ENDSSH

# Suppression du fichier temporaire local
rm $TEMP_VARS_FILE

echo "✅ Déploiement terminé!"
echo "🌍 Accédez à votre site via: https://mmustar.fr"
echo "⏳ Note: La propagation DNS peut prendre quelques minutes"