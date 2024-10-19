import sqlite3
import argparse
import os
import random
import string

# Set up argument parser
parser = argparse.ArgumentParser(description='Rotate secrets in the Casdoor database.')
parser.add_argument('--db', required=True, help='Path to the SQLite database file')
parser.add_argument('--application', default='application', help='Name of the application to rotate secrets for')
parser.add_argument('--rotate', action='store_true', help='Rotate the secrets')
args = parser.parse_args()
print(args.db)
# Connect to the SQLite database using the provided argument

# Check if the database file exists
if not os.path.isfile(args.db):
    print(f"Error: The database file '{args.db}' does not exist.")
    exit(1)

conn = sqlite3.connect(args.db)
c = conn.cursor()


def generate_random_secret(length=40):
    """Generate a random client secret."""
    characters = string.ascii_letters + string.digits
    return ''.join(random.choice(characters) for i in range(length))

if args.rotate:
    new_client_secret = generate_random_secret()
    c.execute("UPDATE application SET client_secret = ? WHERE name = ?", (new_client_secret, args.application))
    conn.commit()
    print(f"Client secret for application '{args.application}' has been rotated.")

# Query the application table
c.execute("SELECT name, client_id, client_secret FROM application WHERE name = ?", (args.application,))

# Fetch and print the results
results = c.fetchall()
for row in results:
    name, client_id, client_secret = row
    print(f"Name: {name}")
    print(f"Client ID: {client_id}")
    print(f"Client Secret: {client_secret}")
    print()

# Close the database connection
conn.close()