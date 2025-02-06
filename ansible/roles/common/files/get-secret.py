#!/usr/bin/env python3
import boto3
import json
import sys
import os
from botocore.exceptions import ClientError

def get_aws_secret(secret_name):
    """
    Récupère un secret depuis AWS Secrets Manager.
    Les credentials AWS doivent être configurés via:
    - Variables d'environnement (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
    - Fichier ~/.aws/credentials
    - Rôle IAM si exécuté sur une instance EC2
    """
    try:
        # Utilise les credentials depuis l'environnement/fichier de config
        session = boto3.session.Session()
        client = session.client(
            service_name='secretsmanager',
            region_name='eu-west-3'
        )
        
        response = client.get_secret_value(SecretId=secret_name)
        return response['SecretString']
        
    except ClientError as e:
        error_message = f"Erreur lors de la récupération du secret: {str(e)}"
        print(error_message, file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        error_message = f"Erreur inattendue: {str(e)}"
        print(error_message, file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    # Vous pouvez aussi passer le nom du secret en argument
    secret_name = 'book'  # ou utilisez sys.argv[1] pour le passer en paramètre
    print(get_aws_secret(secret_name))