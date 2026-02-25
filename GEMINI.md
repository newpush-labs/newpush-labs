# Gemini Context for NewPush Labs (`newpush-labs`)

Welcome to the `newpush-labs` repository. This project provisions and manages containerized, self-hosted lab environments for students and professionals using a combination of Ansible, Terraform, Packer, and Docker Compose.

As an AI assistant working in this repository, you must adhere to the following architectural guidelines, coding standards, and operational rules.

## Architectural Philosophy & Direction

1. **Normalization & Centralization**:
    * **Versions**: All Docker image versions MUST be defined in `services/.env` and referenced in compose files (e.g., `image: myapp:${MYAPP_VERSION}`). Do not hardcode versions in `docker-compose.yaml` files.
    * **Secrets/Config**: Keep configuration centralized. Use Ansible `group_vars` for deployment configurations and `.env` files for runtime container environments.
2. **Container Management (Dockge > Portainer)**:
    * We are migrating away from Portainer application templates due to label parsing issues.
    * **New Standard**: Define lab applications as native Docker Compose stacks in `services/dockge/stacks/<stack-name>/compose.yaml`. Manage them via Dockge.
3. **Authentication & Proxying**:
    * All external access is routed through **Traefik**.
    * Authentication is handled by **Casdoor** via `traefik-forward-auth`.
    * Casdoor initialization is strictly declarative using `services/casdoor/init_data.json`. Ensure OAuth credentials in this JSON match what Ansible expects/generates.
4. **Resource Management**:
    * **Disk Space**: These are lab environments with limited disk space. **ALWAYS** ensure Docker containers use log rotation. Rely on the global `/etc/docker/daemon.json` configuration provisioned by Ansible, and if defining custom logging in a compose file, always set `max-size` (e.g., `10m`) and `max-file` (e.g., `3`).

## Directory Structure Guide

* `provisioning/`: Infrastructure as Code.
  * `ansible/`: Core configuration management. Roles are modular (e.g., `lab-install-docker`, `lab-configure-casdoor`).
  * `terraform/` & `packer/`: VM and cloud infrastructure provisioning.
* `services/`: Core infrastructure containers (Traefik, Casdoor, Monitoring, Portainer/Dockge).
  * `docker-compose.yaml`: The main entry point for core services.
  * `dockge/stacks/`: The repository for all individual, modular lab applications (LLMs, Security tools, etc.).
* `installer/`: Helper and setup scripts.
  * `newpush-lab.sh`: The primary CLI tool for managing the lab state (`start`, `stop`, `recreate`, `migrate`).
* `utils/`: Helper Python/Bash scripts for credential generation and maintenance.

## Coding Standards & Agent Rules

1. **Ansible Roles**:
    * Keep tasks idempotent.
    * When adding configuration files, use `ansible.builtin.template` or `ansible.builtin.copy` and trigger restart handlers (e.g., `notify: Restart Docker`).
    * Do not put secrets in plaintext in the repository.
2. **Docker Compose**:
    * Use relative paths for volumes where appropriate, scoped to the service directory.
    * Network: Ensure services that need web access are attached to the external `web` network to communicate with Traefik.
    * Use labels to configure Traefik routing and Sablier (for scale-to-zero capabilities).
3. **Bash Scripts**:
    * Ensure robust error handling (check exit codes).
    * When updating `installer/newpush-lab.sh`, ensure you respect the distinction between the "core" stack and the modular "dockge" stacks.

## Common Operations

* **Manage Core Services**: `docker compose -f services/docker-compose.yaml up -d`
* **Manage a Lab Stack**: Use the helper script: `installer/newpush-lab.sh start lab-security-wazuh`
* **Validate JSON**: Always run `python3 -m json.tool <file>` before committing changes to complex JSON files like `casdoor/init_data.json` or Grafana dashboards.
