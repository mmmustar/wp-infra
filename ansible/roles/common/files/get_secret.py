#!/usr/bin/env python3
import boto3
import json

client = boto3.client('secretsmanager', region_name='eu-west-3')
response = client.get_secret_value(SecretId='book')
print(response['SecretString'])