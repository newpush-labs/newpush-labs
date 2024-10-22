# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# Configuration file for JupyterHub
import os

c = get_config()  # noqa: F821

# We rely on environment variables to configure JupyterHub so that we
# avoid having to rebuild the JupyterHub container every time we change a
# configuration parameter.

# Spawn single-user servers as Docker containers
c.JupyterHub.spawner_class = "dockerspawner.DockerSpawner"

# Spawn containers from this image
c.DockerSpawner.image = os.environ["DOCKER_NOTEBOOK_IMAGE"]

# Connect containers to this Docker network
network_name = os.environ["DOCKER_NETWORK_NAME"]
c.DockerSpawner.use_internal_ip = True
c.DockerSpawner.network_name = network_name

# Explicitly set notebook directory because we'll be mounting a volume to it.
# Most `jupyter/docker-stacks` *-notebook images run the Notebook server as
# user `jovyan`, and set the notebook directory to `/home/jovyan/work`.
# We follow the same convention.
notebook_dir = os.environ.get("DOCKER_NOTEBOOK_DIR", "/home/jovyan/work")
c.DockerSpawner.notebook_dir = notebook_dir

# Mount the real user's Docker volume on the host to the notebook user's
# notebook directory in the container
c.DockerSpawner.volumes = {"jupyterhub-user-{username}": notebook_dir}

# Remove containers once they are stopped
c.DockerSpawner.remove = True

# For debugging arguments passed to spawned containers
c.DockerSpawner.debug = True

# User containers will access hub by container name on the Docker network
c.JupyterHub.hub_ip = "jupyterhub"
c.JupyterHub.hub_port = 8080

# Persist hub data on volume mounted inside container
c.JupyterHub.cookie_secret_file = "/data/jupyterhub_cookie_secret"
c.JupyterHub.db_url = "sqlite:////data/jupyterhub.sqlite"

# Allow all signed-up users to login
c.Authenticator.allow_all = True

# Authenticate users with Native Authenticator
# c.JupyterHub.authenticator_class = "nativeauthenticator.NativeAuthenticator"

# Allow anyone to sign-up without approval
# c.NativeAuthenticator.open_signup = True
# https://oauthenticator.readthedocs.io/en/latest/reference/api/gen/oauthenticator.generic.html#
from oauthenticator.generic import GenericOAuthenticator
c.JupyterHub.authenticator_class = GenericOAuthenticator


c.JupyterHub.public_url = f"https://jupyter-hub.{os.environ.get('DOMAIN')}"

c.OAuthenticator.oauth_callback_url = f"https://jupyter-hub.{os.environ.get('DOMAIN')}/hub/oauth_callback"
c.OAuthenticator.client_id = os.environ.get("LAB_OAUTH_CLIENT_ID")
c.OAuthenticator.client_secret = os.environ.get("LAB_OAUTH_CLIENT_SECRET")

c.OAuthenticator.authorize_url = f"https://auth.{os.environ.get('DOMAIN')}/login/oauth/authorize"
c.OAuthenticator.token_url = f"https://auth.{os.environ.get('DOMAIN')}/api/login/oauth/access_token"
c.OAuthenticator.userdata_url = f"https://auth.{os.environ.get('DOMAIN')}/api/userinfo"

c.OAuthenticator.scope = ["openid", "profile", "email", "name", "user_login"]
c.OAuthenticator.username_key = "preferred_username"
c.OAuthenticator.userdata_params = {"client_id": c.OAuthenticator.client_id}
c.OAuthenticator.tls_verify = False
c.OAuthenticator.auto_login = True

# Allowed admins
admin = os.environ.get("JUPYTERHUB_ADMIN")
if admin:
    c.Authenticator.admin_users = [admin]
