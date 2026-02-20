#!/usr/bin/env python3
"""
get_client_credentials.py

Extract ClientId and/or ClientSecret from a Casdoor init_data.json file.

Usage examples:
  python get_client_credentials.py application --client-id
  python get_client_credentials.py application --client-secret
"""

import json
import argparse
import sys
from pathlib import Path


def load_init_data(path: Path):
    if not path.exists():
        print(f"❌ init_data.json not found at {path}")
        sys.exit(1)

    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def find_application(data, app_name):
    for app in data.get("applications", []):
        if app.get("name") == app_name:
            return app
    return None


def main():
    parser = argparse.ArgumentParser(description="Extract ClientId / ClientSecret from init_data.json")
    parser.add_argument("application", help="Application Name (e.g. 'application')")
    parser.add_argument(
        "--file",
        default="init_data.json",
        help="Path to init_data.json (default: ./init_data.json)"
    )
    parser.add_argument("--client-id", action="store_true", help="Output ClientId")
    parser.add_argument("--client-secret", action="store_true", help="Output ClientSecret")

    args = parser.parse_args()

    if not (args.client_id or args.client_secret):
        parser.error("You must specify --client-id or --client-secret")

    data = load_init_data(Path(args.file))
    app = find_application(data, args.application)

    if not app:
        print(f"❌ Application '{args.application}' not found")
        sys.exit(1)

    if args.client_id :
        client_id = app.get("clientId")
        if not client_id:
            print("❌ clientId not found")
            sys.exit(1)
        print(client_id)

    if args.client_secret :
        client_secret = app.get("clientSecret")
        if not client_secret:
            print("❌ clientSecret not found")
            sys.exit(1)
        print(client_secret)


if __name__ == "__main__":
    main()

