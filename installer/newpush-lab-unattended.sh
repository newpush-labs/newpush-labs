#!/bin/bash

# Set the default installation directory
if [ -z "$LAB_HOME" ]; then
  LAB_HOME="/opt/newpush-lab"
fi

function install_packages() {
  # Determine OS based on package manager
  if [ -x "$(command -v apt)" ]; then
    OS="debian"
  elif [ -x "$(command -v yum)" ]; then
    OS="centos"
  else
    echo "Unsupported OS"
    exit 1
  fi

  # Based on OS, install packages, select the package manager
  if [ "$OS" == "debian" ]; then
    sudo dpkg --configure -a
    
    sudo apt update
    sudo apt install git python3-pip python3-venv -y
  elif [ "$OS" == "centos" ]; then
    echo "CentOS not supported yet"
    exit 1
  fi

  # Check if the installation was successful
  if [ $? -ne 0 ]; then
    echo "Failed to install packages"
    exit 1
  fi

  echo "Packages installed"
}

function pull_repo() {
    # Pull the repo from GitHub, remove existing directory if it exists
    rm -rf $LAB_HOME
    git clone https://github.com/newpush-labs/newpush-labs $LAB_HOME

    if [ $? -ne 0 ]; then
      echo "Failed to clone repository"
      exit 1
    fi

    echo "Repository cloned"
}

function initialize_ansible_environment() {
    # Navigate to the provisioning directory
    cd $LAB_HOME

    # Initialize Python3 virtual environment
    python3 -m venv provisioning/ansible/
    source provisioning/ansible/bin/activate

    # Install Ansible
    pip3 install -r provisioning/ansible/requirements.txt
    ansible-galaxy install -r provisioning/ansible/requirements.yaml

    echo "Ansible environment initialized"
}

function configure_ansible() {
    # Navigate to the provisioning directory
    cd $LAB_HOME

    cp provisioning/ansible/group_vars/lab.yaml.example provisioning/ansible/group_vars/lab.yaml

    # Set the lab_external_ip variable by ifconfig.me or already existing EXTERNAL_IP environment variable in the group_vars/lab.yaml file
    if [ -z "$EXTERNAL_IP" ]; then
        EXTERNAL_IP=$(curl ifconfig.me -4 --silent)
    fi
    sed -i "s/^lab_external_ip:.*/lab_external_ip: $EXTERNAL_IP/" provisioning/ansible/group_vars/lab.yaml

    # Uncomment and set the lab_domain variable in the group_vars/lab.yaml file if DOMAIN environment variable is set
    if [ -n "$DOMAIN" ]; then
        sed -i "s/^# lab_domain:.*/lab_domain: $DOMAIN/" provisioning/ansible/group_vars/lab.yaml
    fi

    # Set the acme_zerossl_hmac_encoded and acme_zerossl_kid variables in the group_vars/lab.yaml file
    if [ -n "$ACME_ZEROSSL_HMAC_ENCODED" ]; then
        sed -i "s/^acme_zerossl_hmac_encoded:.*/acme_zerossl_hmac_encoded: $ACME_ZEROSSL_HMAC_ENCODED/" provisioning/ansible/group_vars/lab.yaml
    else
        echo "ACME_ZEROSSL_HMAC_ENCODED is not set, exiting"
        exit 1
    fi

    if [ -n "$ACME_ZEROSSL_KID" ]; then
        sed -i "s/^acme_zerossl_kid:.*/acme_zerossl_kid: $ACME_ZEROSSL_KID/" provisioning/ansible/group_vars/lab.yaml
    else
        echo "ACME_ZEROSSL_KID is not set, exiting"
        exit 1
    fi

    # Add local host to the inventory to a new line
    echo -e "\n127.0.0.1 ansible_connection=local" >> provisioning/ansible/inventory/hosts

    echo "Ansible configured"
}

function run_ansible() {
    # Navigate to the provisioning directory
    cd $LAB_HOME

    # Run Ansible playbook
    make setup HOSTS_FILE=./provisioning/ansible/inventory/hosts

    echo "Ansible playbook executed"
}

install_packages
pull_repo
initialize_ansible_environment
configure_ansible
run_ansible

echo "Newpush Lab installed"