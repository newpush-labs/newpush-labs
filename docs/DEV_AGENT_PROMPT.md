# DEV_AGENT_PROMPT — newpush-labs/newpush-labs

> **Lab provisioning platform** for NewPush training environments. Multi-tool IaC: **Terraform** (cloud VMs), **Packer** (machine images), **Vagrant** (local dev), **Ansible** (configuration). Docker Compose service catalog with **Jinja2** templates. Deployed on **Proxmox** and **AWS**.

---

## 1. Orientation — Read the Docs

Before touching any file, read and internalise:

| Document | Why |
|----------|-----|
| `README.md` | Project overview and lab architecture |
| `CONTRIBUTING.md` | Contribution guidelines |
| `Makefile` | Primary command interface — all operations go through Make |
| `GEMINI.md` | AI agent context (generated) |
| `installer/newpush-lab.sh` | Main lab installer script |
| `provisioning/terraform/main.tf` | Terraform infrastructure definition |
| `provisioning/ansible/lab.yaml` | Main Ansible playbook for lab setup |
| `services/docker-compose.yaml` | Core service stack |

### Tech Stack

- **Terraform** — cloud VM provisioning (AWS, Proxmox)
- **Packer** — machine image builds (Debian 12 for Proxmox and AWS)
- **Vagrant** — local development VMs
- **Ansible** — configuration management, lab setup/update/healthcheck
- **Docker Compose** — service catalog with Jinja2 templates (`.yaml.j2`)
- **Makefile** — task runner for all operations
- **Python** — utility scripts (`utils/casdoor/`)
- **Bash** — installer scripts

### Key Patterns

- **Service catalog**: `services/docker-compose.*.yaml.j2` — Jinja2 templates for each service (Traefik, Portainer, Grafana, Code-Server, Mafl, CrowdSec, etc.)
- **Provisioning pipeline**: Packer builds image → Terraform deploys VM → Ansible configures → Docker Compose starts services
- **Installer scripts**: `installer/` — unattended and interactive variants, cloud-init support
- **Ansible playbooks**: `provisioning/ansible/` — `lab.yaml` (full setup), `lab-update.yaml`, `lab-reconfig.yaml`, `healthcheck.yaml`, `ping.yaml`
- **Terraform vars**: `terraform.tfvars.example` — never commit actual `.tfvars`
- **Tests**: `provisioning/tests/test_lab_core.py` — Python tests for lab infrastructure

---

## 2. Plan — Write a Plan

Before writing code, create a plan in `docs/IMPLEMENTATION_PLAN.md`:

1. **What** — new service, provisioning change, or infrastructure update
2. **Layer** — which tool is affected (Terraform, Packer, Ansible, Docker, installer)
3. **Service impact** — does this add/modify a Docker Compose service template?
4. **Platform scope** — Proxmox, AWS, or both?
5. **Test plan** — how to verify on a test lab instance

---

## 3. Documentation — Write User Docs First

- `README.md` — update service inventory and setup instructions
- `CONTRIBUTING.md` — update for new tools or patterns
- Service templates need inline comments explaining configuration
- Installer scripts need usage documentation in header comments

---

## 4. Tests — Write Tests First

- **Python tests**: `pytest provisioning/tests/`
- **Ansible lint**: `ansible-lint provisioning/ansible/`
- **Terraform validate**: `cd provisioning/terraform && terraform validate`
- **Docker Compose validate**: `docker compose -f services/docker-compose.yaml config`
- **Packer validate**: `cd provisioning/packer && packer validate .`

---

## 5. Code — Write the Code

### Service Template Rules

- Jinja2 templates (`.yaml.j2`) for all Docker Compose services
- Each service in its own `docker-compose.{service}.yaml.j2` file
- Environment variables from `.env` — document all required vars
- Labels for Traefik reverse proxy integration

### Ansible Rules

- Idempotent playbooks — safe to re-run
- Use `lab.yaml` as the canonical full-setup reference
- Healthcheck playbook must cover all services
- Pin Ansible collection versions in `requirements.yaml`

### Terraform Rules

- Variables in `variables.tf` with descriptions
- Example values in `terraform.tfvars.example`
- State management — never commit state files

### Installer Rules

- Support both interactive and unattended modes
- cloud-init compatible (`cloud-init-unattended.yaml`)
- Idempotent — safe to re-run on existing installations

---

## 6. Test the Code — Verify Everything

```bash
make help                              # List available targets
pytest provisioning/tests/             # Run Python tests
ansible-lint provisioning/ansible/     # Lint Ansible
cd provisioning/terraform && terraform validate
```

---

## Branch Workflow

```
feature/* ──► main
```

- This repo uses `main` only (no develop branch)
- All work on `feature/*` branches off `main`
- PR to `main` for review
