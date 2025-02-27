#!/bin/bash

# Configuration
SSH_KEY_PATH="/home/gnou/.ssh/test-aws-key-pair-new.pem"
EC2_USER="ubuntu"
EC2_IP="${1:-51.44.170.64}"  # Utiliser le premier argument ou l'IP par défaut

# Fonction pour exécuter des commandes SSH
run_ssh() {
    ssh -o StrictHostKeyChecking=accept-new \
        -o ConnectTimeout=10 \
        -i "$SSH_KEY_PATH" \
        "$EC2_USER@$EC2_IP" "$1"
}

echo "🔍 Diagnostic de l'installation WordPress sur $EC2_IP..."

# Vérification de l'état de K3s
echo "🔍 Vérification de l'état de K3s..."
run_ssh "sudo systemctl status k3s | grep Active"

# Vérification des pods
echo "🔍 Vérification des pods dans tous les namespaces..."
run_ssh "sudo kubectl get pods -A"

# Vérification des services
echo "🔍 Vérification des services WordPress..."
run_ssh "sudo kubectl get svc -n wordpress"

# Vérification des ingress
echo "🔍 Vérification des ingress..."
run_ssh "sudo kubectl get ingress -A"

# Vérification des ports ouverts sur l'EC2
echo "🔍 Vérification des ports ouverts sur l'EC2..."
run_ssh "sudo netstat -tulpn | grep LISTEN"

# Vérification du groupe de sécurité dans AWS
echo "🔍 Vérification des règles de groupe de sécurité..."
run_ssh "curl -s http://169.254.169.254/latest/meta-data/security-groups"

# Création d'un script d'installation simplifié
cat > /tmp/fix-wordpress.sh << 'EOFFIX'
#!/bin/bash
set -e

echo "🔧 Application de correctifs pour WordPress..."

# Configurez kubectl
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Vérifiez l'état actuel
kubectl get pods -n wordpress
kubectl get svc -n wordpress
kubectl get ingress -n wordpress

# Supprimez les ressources existantes de WordPress
echo "🗑️ Suppression des ressources existantes..."
kubectl delete deploy,svc,ingress,pvc -n wordpress --all

# Installation de WordPress avec une configuration simplifiée
echo "🚀 Installation de WordPress simplifiée..."
cat > /tmp/minimal-wp.yaml << 'EOF'
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  namespace: wordpress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
      - name: wordpress
        image: wordpress:6.4
        ports:
        - containerPort: 80
        env:
        - name: WORDPRESS_DB_HOST
          value: "rds-wp-test.cdaookoquxxr.eu-west-3.rds.amazonaws.com"
        - name: WORDPRESS_DB_USER
          value: "wp_user"
        - name: WORDPRESS_DB_PASSWORD
          value: "StrongWpUserPass456!"
        - name: WORDPRESS_DB_NAME
          value: "wp_database"
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress
  namespace: wordpress
spec:
  type: NodePort
  ports:
  - port: 80
    nodePort: 32080
  selector:
    app: wordpress
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wordpress
  namespace: wordpress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: wordpress
            port:
              number: 80
EOF

kubectl apply -f /tmp/minimal-wp.yaml

# Assurez-vous que le trafic HTTP est bien routé
echo "🔧 Configuration de Nginx Ingress pour HTTP..."
cat > /tmp/ingress-config.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-configuration
  namespace: default
data:
  proxy-body-size: "64m"
  proxy-read-timeout: "300"
  proxy-connect-timeout: "300"
EOF

kubectl apply -f /tmp/ingress-config.yaml

# Vérifier la configuration du pare-feu
echo "🔧 Vérification des règles de pare-feu..."
ufw status
if [[ $(ufw status | grep "Status: active") ]]; then
  echo "🔧 Ouverture des ports nécessaires dans UFW..."
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw allow 32080/tcp
fi

# Vérification que les pods sont opérationnels
echo "⏳ Attente que les pods soient prêts..."
kubectl rollout status deployment/wordpress -n wordpress --timeout=120s

# Affichage des informations d'accès
echo "✅ Installation terminée!"
echo "🌐 WordPress est accessible aux adresses suivantes:"
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "   - http://${PUBLIC_IP}:32080"
echo "   - http://${PUBLIC_IP}"

# Vérifiez si l'accès fonctionne
echo "🔍 Test d'accès à WordPress..."
curl -s -I http://localhost:32080 | head -n1
EOFFIX

echo "📤 Transfert du script de correction..."
scp -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=10 \
    -i "$SSH_KEY_PATH" \
    /tmp/fix-wordpress.sh "$EC2_USER@$EC2_IP:/home/$EC2_USER/fix-wordpress.sh"

echo "🔄 Exécution du script de correction..."
run_ssh "chmod +x /home/$EC2_USER/fix-wordpress.sh && sudo /home/$EC2_USER/fix-wordpress.sh"

echo "📋 Résumé :"
echo "1. Vérification et simplification de l'installation WordPress"
echo "2. Configuration d'un NodePort sur 32080"
echo "3. Configuration de l'Ingress pour accepter tout trafic HTTP"
echo "4. Vérification des règles de pare-feu"

echo "🌐 WordPress devrait maintenant être accessible à :"
echo "  - http://$EC2_IP:32080 (directement via NodePort)"
echo "  - http://$EC2_IP (via Ingress, si configuré correctement)"
echo ""
echo "📝 Identifiants administrateur WordPress :"
echo "  - Nom d'utilisateur : admin (à définir lors de la première visite)"
echo "  - Mot de passe : (à définir lors de la première visite)"