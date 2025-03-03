# Default target
.DEFAULT_GOAL := help

HOSTS_FILE ?= provisioning/ansible/inventory/hosts

# Uncomment to enable debug mode
# DEBUG = "-vvvv"

# Help target
help:
	@echo "Available commands:"
	@echo "  make dev  - Run the development Ansible playbook"


setup:
	ansible-playbook $(DEBUG) -i $(HOSTS_FILE) provisioning/ansible/lab.yaml --user=root --tags always,setup

# Dev target
dev:
	ansible-playbook $(DEBUG) -i $(HOSTS_FILE) provisioning/ansible/lab-reconfig.yaml --user=root

copy:
	ansible-playbook $(DEBUG) -i $(HOSTS_FILE) provisioning/ansible/lab-copy-dockers.yaml  --user=root

ping:
	ansible $(DEBUG) -i $(HOSTS_FILE) -m ping all  --user=root

test:
	py.test -q -n 15 --ansible-inventory=$(HOSTS_FILE) --hosts='ansible://all' provisioning/tests/test_lab_core.py

fix:
	ansible-playbook $(DEBUG) -i $(HOSTS_FILE) provisioning/ansible/lab-fix-existing.yaml --user=root

# Phony targets
.PHONY: help dev
