# Default target
.DEFAULT_GOAL := help

# Help target
help:
	@echo "Available commands:"
	@echo "  make dev  - Run the development Ansible playbook"

# Dev target
dev:
	ansible-playbook -i provisioning/ansible/inventory/hosts.dev provisioning/ansible/lab-reconfig.yaml

copy:
	ansible-playbook -i provisioning/ansible/inventory/hosts.dev provisioning/ansible/lab-copy-dockers.yaml

# Phony targets
.PHONY: help dev