#!/usr/bin/env python3
import json
import sys

SECRETS_FILE = "/home/gnou/Documents/wp-projet/wordpress-infra/environments/test/secrets.json"

def get_local_secret(secret_name):
    try:
        with open(SECRETS_FILE, "r") as f:
            secrets = json.load(f)
        return secrets.get(secret_name, "Secret not found")
    except Exception as e:
        print(f"Erreur: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: get_secret.py <SECRET_NAME>", file=sys.stderr)
        sys.exit(1)

    secret_name = sys.argv[1]
    print(get_local_secret(secret_name))
