# Default target
.DEFAULT_GOAL := help

HOSTS_FILE = provisioning/ansible/inventory/hosts.dev

# Help target
help:
	@echo "Available commands:"
	@echo "  make dev  - Run the development Ansible playbook"

# Dev target
dev:
	ansible-playbook -i $(HOSTS_FILE) provisioning/ansible/lab-reconfig.yaml

copy:
	ansible-playbook -i $(HOSTS_FILE) provisioning/ansible/lab-copy-dockers.yaml

ping:
	ansible -i $(HOSTS_FILE) -m ping all

# Phony targets
.PHONY: help dev