#!/bin/bash

set -e  # Arrêter le script en cas d'erreur

namespace="wordpress-test"
echo "🚀 Automatisation du déploiement WordPress sur K3s avec Helm..."

# 🔹 Mettre à jour les repositories Helm
helm repo update

# 🔹 Vérifier si le namespace existe, sinon le créer
kubectl get namespace $namespace || kubectl create namespace $namespace

# 🔹 Récupération des secrets AWS (sans certificats)
SECRETS_JSON=$(aws secretsmanager get-secret-value --secret-id book --query SecretString --output text)

MYSQL_DATABASE=$(echo "$SECRETS_JSON" | jq -r '.MYSQL_DATABASE')
MYSQL_USER=$(echo "$SECRETS_JSON" | jq -r '.MYSQL_USER')
MYSQL_PASSWORD=$(echo "$SECRETS_JSON" | jq -r '.MYSQL_PASSWORD')
MYSQL_ROOT_PASSWORD=$(echo "$SECRETS_JSON" | jq -r '.MYSQL_ROOT_PASSWORD')

# 🔹 Utilisation des certificats locaux
CLOUDFLARE_ORIGIN_CRT="cloudflare_origin.crt"
CLOUDFLARE_ORIGIN_KEY="cloudflare_origin.key"

echo "🔹 Utilisation des certificats locaux depuis $CLOUDFLARE_ORIGIN_CRT et $CLOUDFLARE_ORIGIN_KEY."

# 🔹 Vérification que les certificats existent
if [[ ! -f "$CLOUDFLARE_ORIGIN_CRT" || ! -f "$CLOUDFLARE_ORIGIN_KEY" ]]; then
    echo "❌ Erreur : Les certificats Cloudflare ne sont pas trouvés dans $CLOUDFLARE_ORIGIN_CRT et $CLOUDFLARE_ORIGIN_KEY"
    exit 1
fi

# 🔹 Supprimer et recréer le secret TLS Kubernetes
kubectl delete secret cloudflare-cert --namespace $namespace --ignore-not-found

kubectl create secret tls cloudflare-cert --namespace $namespace \
  --cert="$CLOUDFLARE_ORIGIN_CRT" \
  --key="$CLOUDFLARE_ORIGIN_KEY"

echo "✅ Secret TLS Kubernetes créé avec succès."

# 🔹 Déploiement de WordPress avec Helm
helm upgrade --install wordpress bitnami/wordpress \
  --namespace $namespace \
  --set global.storageClass=standard \
  --set service.type=ClusterIP \
  --set mariadb.auth.database=$MYSQL_DATABASE \
  --set mariadb.auth.username=$MYSQL_USER \
  --set mariadb.auth.password=$MYSQL_PASSWORD \
  --set mariadb.auth.rootPassword=$MYSQL_ROOT_PASSWORD \
  --set ingress.enabled=true \
  --set ingress.hostname=test.mmustar.fr \
  --set ingress.annotations."kubernetes\\.io/ingress\\.class"="nginx" \
  --set ingress.tls=true \
  --set ingress.extraTls[0].hosts[0]=test.mmustar.fr \
  --set ingress.extraTls[0].secretName=cloudflare-cert


echo "✅ Déploiement Helm terminé avec succès. WordPress devrait être accessible via test.mmustar.fr 🚀"
