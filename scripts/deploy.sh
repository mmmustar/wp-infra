#!/bin/bash
# deploy.sh – Script de déploiement pour forcer WordPress à utiliser l'adresse test.mmustar.fr avec Apache,
# installer le certificat SSL pour l'environnement test via un secret Kubernetes,
# mettre à jour l'Ingress pour servir le domaine en HTTPS,
# afficher les identifiants WordPress, et
# inviter à finaliser manuellement l'installation de WordPress via le navigateur.

# Configuration de base
SSH_KEY_PATH="/home/gnou/.ssh/test-aws-key-pair-new.pem"
EC2_USER="ubuntu"
# Utiliser l'IP fournie en argument ou l'IP par défaut
EC2_IP="${1:-51.44.170.64}"
# Utiliser le nom de domaine de l'environnement test
domain_name="test.mmustar.fr"

# Fonction pour exécuter une commande SSH sur l'instance EC2
run_ssh() {
    ssh -o StrictHostKeyChecking=accept-new \
        -o ConnectTimeout=10 \
        -i "$SSH_KEY_PATH" \
        "$EC2_USER@$EC2_IP" "$1"
}

echo "=== Diagnostic initial ==="
echo "État de K3s :"
run_ssh "sudo systemctl status k3s | grep Active"
echo ""
echo "Liste des pods dans tous les namespaces :"
run_ssh "sudo kubectl get pods -A"
echo ""
echo "Services dans le namespace WordPress :"
run_ssh "sudo kubectl get svc -n wordpress"
echo ""
echo "Ingress dans tous les namespaces :"
run_ssh "sudo kubectl get ingress -A"
echo ""

# ------------------------------
# Installation du certificat SSL pour l'environnement test
# ------------------------------
echo "=== Installation du certificat SSL pour l'environnement test ==="
echo "Transfert des certificats vers l'instance EC2..."
scp -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=10 \
    -i "$SSH_KEY_PATH" \
    cloudflare_test.crt "$EC2_USER@$EC2_IP:/home/$EC2_USER/"
scp -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=10 \
    -i "$SSH_KEY_PATH" \
    cloudflare_test.key "$EC2_USER@$EC2_IP:/home/$EC2_USER/"

echo "Création (ou mise à jour) du secret Kubernetes 'wordpress-tls' dans le namespace wordpress..."
# Supprimer l'ancien secret s'il existe et créer le nouveau secret TLS
run_ssh "sudo kubectl delete secret wordpress-tls -n wordpress || true"
run_ssh "sudo kubectl create secret tls wordpress-tls --cert=/home/$EC2_USER/cloudflare_test.crt --key=/home/$EC2_USER/cloudflare_test.key -n wordpress"

echo "Nettoyage des certificats temporaires sur l'instance..."
run_ssh "rm -f /home/$EC2_USER/cloudflare_test.crt /home/$EC2_USER/cloudflare_test.key"
echo "Secret 'wordpress-tls' créé et déployé."

# ------------------------------
# Mise à jour de WORDPRESS_CONFIG_EXTRA
# ------------------------------
echo "=== Mise à jour du déploiement WordPress ==="
# Ici, WP_HOME et WP_SITEURL seront définis sur https://test.mmustar.fr
run_ssh "sudo kubectl set env deployment/wordpress WORDPRESS_CONFIG_EXTRA=\"define('WP_HOME','https://${domain_name}');define('WP_SITEURL','https://${domain_name}');\" -n wordpress"
echo "Variable d'environnement WORDPRESS_CONFIG_EXTRA mise à jour."

# ------------------------------
# Mise à jour de l'Ingress pour activer TLS sur test.mmustar.fr
# ------------------------------
echo "=== Mise à jour de l'Ingress pour utiliser TLS pour ${domain_name} ==="
INGRESS_PATCH=$(cat <<EOF
{
  "spec": {
    "rules": [
      {
        "host": "${domain_name}",
        "http": {
          "paths": [
            {
              "backend": {
                "service": {
                  "name": "wordpress",
                  "port": {
                    "number": 80
                  }
                }
              },
              "path": "/",
              "pathType": "Prefix"
            }
          ]
        }
      }
    ],
    "tls": [
      {
        "hosts": [
          "${domain_name}"
        ],
        "secretName": "wordpress-tls"
      }
    ]
  }
}
EOF
)
run_ssh "sudo kubectl patch ingress wordpress -n wordpress --type merge --patch '$INGRESS_PATCH'"
echo "Ingress mis à jour pour ${domain_name}."

# ------------------------------
# Redémarrage du déploiement WordPress
# ------------------------------
echo "Redémarrage du déploiement WordPress..."
run_ssh "sudo kubectl rollout restart deployment/wordpress -n wordpress"
echo "Attente que les pods soient à nouveau prêts..."
run_ssh "sudo kubectl rollout status deployment/wordpress -n wordpress --timeout=180s"

# ------------------------------
# Redémarrage d'Apache dans le conteneur
# ------------------------------
echo "=== Redémarrage d'Apache dans le conteneur WordPress ==="
# Exécute la commande via kubectl exec dans le premier pod trouvé
run_ssh "sudo kubectl exec -n wordpress \$(sudo kubectl get pod -n wordpress -l app=wordpress -o jsonpath='{.items[0].metadata.name}') -- service apache2 restart"
echo "Apache redémarré."

# ------------------------------
# Vérification de l'accès
# ------------------------------
echo "=== Vérification locale dans le conteneur ==="
run_ssh "sudo kubectl exec -n wordpress \$(sudo kubectl get pod -n wordpress -l app=wordpress -o jsonpath='{.items[0].metadata.name}') -- curl -I http://localhost/ | head -n 1"

echo ""
echo "=== Résumé ==="
echo "WORDPRESS_CONFIG_EXTRA a été défini pour forcer WP_HOME et WP_SITEURL sur https://${domain_name}"
echo "Le secret 'wordpress-tls' a été créé avec le certificat SSL pour ${domain_name}."
echo "L'Ingress a été patché pour servir HTTPS avec le secret 'wordpress-tls'."
echo "Les pods ont été redémarrés."
echo "WordPress devrait être accessible via :"
echo "   https://${domain_name}/wp-login.php"

# ------------------------------
# Récupération et affichage des identifiants WordPress
# ------------------------------
echo ""
echo "=== Récupération des identifiants WordPress ==="
LOGIN=$(ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -i "$SSH_KEY_PATH" "$EC2_USER@$EC2_IP" "sudo kubectl get secret wordpress -n wordpress -o jsonpath='{.data.wordpress-username}' | base64 --decode" 2>/dev/null)
if [ -z "$LOGIN" ]; then
    LOGIN="user"
fi
PASSWORD=$(ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -i "$SSH_KEY_PATH" "$EC2_USER@$EC2_IP" "sudo kubectl get secret wordpress -n wordpress -o jsonpath='{.data.wordpress-password}' | base64 --decode")
echo "Login         : $LOGIN"
echo "Mot de passe  : $PASSWORD"

# ------------------------------
# Finalisation manuelle de l'installation de WordPress
# ------------------------------
echo ""
echo "=== Finalisation manuelle de l'installation de WordPress ==="
echo "Veuillez ouvrir votre navigateur et accéder à l'URL suivante pour finaliser l'installation :"
echo "   https://${domain_name}/wp-admin/install.php"
echo "Une fois l'installation terminée, appuyez sur Entrée pour clôturer le déploiement..."
read -p "Appuyez sur Entrée pour terminer..."
