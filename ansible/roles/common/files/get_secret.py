#!/usr/bin/env python3
import boto3
import json
import sys

try:
    client = boto3.client('secretsmanager', region_name='eu-west-3')
    response = client.get_secret_value(SecretId='book')
    print(response['SecretString'])
except Exception as e:
    print(f"Erreur: {str(e)}", file=sys.stderr)
    sys.exit(1)