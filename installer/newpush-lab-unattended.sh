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
    export DEBIAN_FRONTEND=noninteractive
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

    # Set the lab_user variable in the group_vars/lab.yaml file if LAB_USER environment variable is set
    if [ -n "$LAB_USER" ]; then
        sed -i "s/^lab_user:.*/lab_user: $LAB_USER/" provisioning/ansible/group_vars/lab.yaml
    fi

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

    # Set traefik_crowdsec_bouncer to true in the group_vars/lab.yaml file if CROWDSEC_BOUNCER environment variable is set
    if [ -n "$CROWDSEC_BOUNCER" ]; then
        sed -i "s/^traefik_crowdsec_bouncer:.*/traefik_crowdsec_bouncer: true/" provisioning/ansible/group_vars/lab.yaml

        # Set hcaptcha_site_key if it is set and return error if it is not set
        if [ -n "$HCAPTCHA_SITE_KEY" ]; then
            sed -i "s/^hcaptcha_site_key:.*/hcaptcha_site_key: $HCAPTCHA_SITE_KEY/" provisioning/ansible/group_vars/lab.yaml
        else
            echo "HCAPTCHA_SITE_KEY is not set, exiting"
            exit 1
        fi
    fi

    # Set is_vagrant to true if VAGRANT_PROVISION environment variable is set
    if [ -n "$VAGRANT_PROVISION" ]; then
        sed -i "s/^is_vagrant:.*/is_vagrant: true/" provisioning/ansible/group_vars/lab.yaml
    fi

    # Remove the default lab_active_stacks block from the example file
    sed -i '/^lab_active_stacks:/,$d' provisioning/ansible/group_vars/lab.yaml

    # Append the new lab_active_stacks block dynamically
    echo "lab_active_stacks:" >> provisioning/ansible/group_vars/lab.yaml
    
    # Check if a base64 JSON payload was provided for advanced stack config
    if [ -n "$LAB_ACTIVE_STACKS_JSON_B64" ]; then
        # Decode the JSON and convert it directly to YAML using python.
        echo "$LAB_ACTIVE_STACKS_JSON_B64" | base64 -d > /tmp/stacks.json
        python3 -c 'import sys, json, yaml; print(yaml.dump(json.load(open("/tmp/stacks.json")), default_flow_style=False))' >> provisioning/ansible/group_vars/lab.yaml
    else
        # Fallback to simple comma-separated list.
        # If absolutely nothing is set, default to n8n and workbench.
        if [ -z "$LAB_ACTIVE_STACKS" ]; then
            export LAB_ACTIVE_STACKS="lab-tools-n8n,lab-tools-workbench"
        fi

        
        IFS=',' read -ra STACKS <<< "$LAB_ACTIVE_STACKS"
        for stack in "${STACKS[@]}"; do
            # Trim leading/trailing whitespace
            stack=$(echo "$stack" | xargs)
            if [ -n "$stack" ]; then
                echo "  - name: \"$stack\"" >> provisioning/ansible/group_vars/lab.yaml
                echo "    options: {}" >> provisioning/ansible/group_vars/lab.yaml
            fi
        done
    fi

    # Create a fresh inventory with local connection under [lab] group
    echo "[lab]" > provisioning/ansible/inventory/hosts
    echo "127.0.0.1 ansible_connection=local" >> provisioning/ansible/inventory/hosts

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
