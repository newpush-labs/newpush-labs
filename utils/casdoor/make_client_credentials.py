#!/usr/bin/env python3
"""
make_client_credentials.py

Generate ClientId and/or ClientSecret for a Casdoor init_data.json file.

Usage examples:
  python make_client_credentials.py --client-id
  python make_client_credentials.py --client-secret
"""

import secrets
import argparse

def main():
    parser = argparse.ArgumentParser(description="Generate ClientId / ClientSecret for init_data.json")
    parser.add_argument("--client-id", action="store_true", help="Output ClientId")
    parser.add_argument("--client-secret", action="store_true", help="Output ClientSecret")

    args = parser.parse_args()

    if not (args.client_id or args.client_secret):
        parser.error("You must specify --client-id or --client-secret")

    if args.client_id :
        client_id = secrets.token_hex(10)
        print(client_id)

    if args.client_secret :
        client_secret = secrets.token_urlsafe(32)
        print(client_secret)


if __name__ == "__main__":
    main()

