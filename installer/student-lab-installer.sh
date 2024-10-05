#!/bin/bash
LAB_HOME="/opt/student-lab"

function install_packages() {
  # Make sure apt is in good shape
  sudo dpkg --configure -a

  # Update apt package list
  echo "Updating apt package list..."
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates gnupg curl

  # Install Docker
  echo "Installing Docker..."
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo docker network create web

  # Add the repository to Apt sources:
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update

  # Install gsutil
  echo "Installing gsutil..."
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --batch --dearmor -o /usr/share/keyrings/cloud.google.gpg
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
  sudo apt-get update && sudo apt-get install -y google-cloud-sdk

  # Create directory for student lab dockerfiles
  echo "Creating directory /opt/student-lab..."
  sudo mkdir -p /opt/student-lab

  echo "Creating directory /opt/appdata..."
  sudo mkdir -p /opt/appdata

  # Download dockerfiles from S3 bucket
  echo "Downloading dockerfiles from s3://newpush-student-lab/contents/ to /opt/student-lab..."
  # gsutil cp -r gs://newpush-student-lab/contents/services /opt/student-lab/
  gsutil -m rsync -r gs://newpush-student-lab/contents/ /opt/student-lab/

  cd /opt/student-lab/services 
  IP=$(curl ifconfig.me -4 --silent); 
  DOMAIN="$IP.traefik.me"
  echo "DOMAIN=$DOMAIN" > .env

  echo "https://traefik.$IP.traefik.me" # %s"

  # Wazuh Needs this on the host
  sudo sysctl -w vm.max_map_count=262144

  echo "Installation and download complete."
}
function update_wazuh_certs() {
  cd /opt/student-lab/services
  docker compose -f generate-indexer-certs.yml run --rm generator
}


function start_stacks() {
  cd /opt/student-lab/services
  if [ -z "$1" ] || [ "$1" == "all" ]; then
    # Start all stacks if no argument or "all" is provided
    docker compose -f docker-compose.yaml -p student-lab up -d
    docker compose -f docker-compose.wazuh.yaml -p student-lab-wazuh up -d
    docker compose -f docker-compose.openvas.yaml -p student-lab-openvas up -d
    docker compose -f docker-compose.coder.yaml -p student-lab-coder up -d
  else
    # Start specific stacks based on arguments
    for stack in "$@"; do
      case "$stack" in
        "student-lab")
          docker compose -f docker-compose.yaml -p student-lab up -d
          ;;
        "wazuh")
          cd /opt/student-lab/services/dockge/stacks/lab-security-wazuh
          docker compose -f docker-compose.wazuh.yaml -p student-lab-wazuh up -d
          ;;
        "openvas")
          cd /opt/student-lab/services/dockge/stacks/lab-security-openvas
          docker compose -f docker-compose.openvas.yaml -p student-lab-openvas up -d
          ;;
        "coder")
          docker compose -f docker-compose.coder.yaml -p student-lab-coder up -d
          ;;
        *)
          echo "Invalid stack name: $stack"
          ;;
      esac
    done
  fi
}


function stop_stacks() {
  cd /opt/student-lab/services
  if [ -z "$1" ] || [ "$1" == "all" ]; then
    # Stop all stacks if no argument or "all" is provided
    docker compose -f docker-compose.yaml -p student-lab stop
    docker compose -f docker-compose.wazuh.yaml -p student-lab-wazuh stop
    docker compose -f docker-compose.openvas.yaml -p student-lab-openvas stop
    docker compose -f docker-compose.coder.yaml -p student-lab-coder stop
  else
    # Stop specific stacks based on arguments
    for stack in "$@"; do
      case "$stack" in
        "student-lab")
          docker compose -f docker-compose.yaml -p student-lab stop
          ;;
        "wazuh")
          cd /opt/student-lab/services/dockge/stacks/lab-security-wazuh
          docker compose -f docker-compose.wazuh.yaml -p student-lab-wazuh stop
          ;;
        "openvas")
          cd /opt/student-lab/services/dockge/stacks/lab-security-openvas
          docker compose -f docker-compose.openvas.yaml -p student-lab-openvas stop
          ;;
        "coder")
          docker compose -f docker-compose.coder.yaml -p student-lab-coder stop
          ;;
        *)
          echo "Invalid stack name: $stack"
          ;;
      esac
    done
  fi
}


function remove_stacks() {
  cd /opt/student-lab/services
  docker compose -f docker-compose.yaml -p student-lab down
  docker compose -f docker-compose.wazuh.yaml -p student-lab-wazuh down
  docker compose -f docker-compose.openvas.yaml -p student-lab-openvas down
  docker compose -f docker-compose.coder.yaml -p student-lab-coder down
}

function update_dockerfiles() {
  # Download dockerfiles from S3 bucket
  echo "ERROR: Dockerfile updates from S3 is currently disabled!"
  # echo "Downloading dockerfiles from s3://newpush-student-lab/contents/ to /opt/student-lab..."
  # gsutil -m rsync -r gs://newpush-student-lab/contents/ /opt/student-lab/
}

function update_env() {
  cd /opt/student-lab/services 
  IP=$(curl ifconfig.me -4 --silent); 
  DOMAIN="$IP.traefik.me"
  
  LAB_USER=$(awk -F':' '$3 == 1000 { print $1 }' /etc/passwd)
  LAB_USER_HOME=$(eval echo ~$LAB_USER)
  LAB_IP=$(curl ifconfig.me -4 --silent)
  LAB_SSH_KEY=$LAB_USER_HOME/.ssh/id_rsa

  echo "DOMAIN=$DOMAIN" > .env
  echo "CODER_ACCESS_URL=https://coder.$IP.traefik.me" >> .env
  
  echo "LAB_USER=$LAB_USER" >> .env
  echo "LAB_USER_HOME=$LAB_USER_HOME" >> .env
  echo "LAB_IP=$LAB_IP" >> .env
  echo "LAB_SSH_KEY=$LAB_SSH_KEY" >> .env

  cat .env 
  
  echo "Update complete."
}

function restart_mafl() {
    cd /opt/student-lab/services
    if [ -e ".env" ]; then
      if docker ps --filter "name=mafl" --filter "status=running" | grep -q mafl; then
        echo "MAFL docker is running. Restarting..."
        docker restart mafl
      else
        echo "MAFL docker is not running."
      fi
      
    else
      echo "No .env file found. Cannot update MAFL config."
    fi
}

function restart_traefik() {
  cd /opt/student-lab/services
  if docker ps --filter "name=traefik" --filter "status=running" | grep -q traefik; then
    echo "Traefik docker is running. Restarting..."
    docker restart traefik
  else
    echo "Traefik docker is not running."
  fi
}

function restart_casdoor() {
  cd /opt/student-lab/services
  if docker ps --filter "name=casdoor" --filter "status=running" | grep -q casdoor; then
    echo "Casdoor docker is running. Restarting..."
    # Find the container id of the casdoor container
    CASDOOR_CONTAINER_ID=$(docker ps --filter "name=casdoor" --filter "status=running" | grep -oP '^\S+' | tail -n 1)
    docker restart $CASDOOR_CONTAINER_ID
  else
    echo "Casdoor docker is not running."
  fi
}

function restart_grafana() {
  cd /opt/student-lab/services
  if docker ps --filter "name=grafana" --filter "status=running" | grep -q grafana; then
    echo "Grafana docker is running. Restarting..."
    # Find the container id of the grafana container
    GRAFANA_CONTAINER_ID=$(docker ps --filter "name=grafana" --filter "status=running" | grep -oP '^\S+' | tail -n 1)
    docker restart $GRAFANA_CONTAINER_ID
  else
    echo "Grafana docker is not running."
  fi
}

function restart_mafl_service_discovery() {
  cd /opt/student-lab/services
  if docker ps --filter "name=mafl-service-discovery" --filter "status=running" | grep -q mafl-service-discovery; then
    echo "MAFL Service Discovery docker is running. Restarting..."
    docker restart mafl-service-discovery
  else
    echo "MAFL Service Discovery docker is not running."
  fi
}

function update_sshwifty() {
  cd /opt/student-lab/services/

  if [ -e ".env" ]; then
    LAB_USER=$(grep -oP 'LAB_USER=\K[^ ]+' .env)
    LAB_SSH_KEY=$(grep -oP 'LAB_SSH_KEY=\K[^ ]+' .env)
    LAB_IP=$(grep -oP 'LAB_IP=\K[^ ]+' .env)
    LAB_USER_HOME=$(grep -oP 'LAB_USER_HOME=\K[^ ]+' .env)
    LAB_SSH_KEY=$LAB_USER_HOME/.ssh/id_rsa

    if [ ! -e "$LAB_SSH_KEY" ]; then
      echo "No SSH key found for $LAB_USER at $LAB_SSH_KEY. Generating..."
      sudo -u $LAB_USER ssh-keygen -t rsa -b 4096 -f $LAB_SSH_KEY -N "" -q
    fi

    if [ -e "$LAB_SSH_KEY" ]; then
      cp $LAB_SSH_KEY sshwifty/id_rsa
      chown $LAB_USER sshwifty/id_rsa
      chmod 600 sshwifty/id_rsa
      echo "SSHWifty config updated."
      cat $LAB_SSH_KEY.pub >> $LAB_USER_HOME/.ssh/authorized_keys
    fi

    LAB_SSH_KEY_DATA=$(cat $LAB_SSH_KEY | tr '\n' ' ')

    sed -i "s,environment://LAB_IP,$LAB_IP,g" /opt/student-lab/services/sshwifty/sshwifty.conf.json
    sed -i "s,environment://LAB_USER,$LAB_USER,g" /opt/student-lab/services/sshwifty/sshwifty.conf.json
    # sed -i "s,file:///home/sshwifty/.ssh/id_rsa,$LAB_SSH_KEY_DATA,g" /opt/student-lab/services/sshwifty/sshwifty.conf.json
  else
    echo "No .env file found. Cannot update SSHWifty config."
  fi
}

if [ "$1" == "recreate" ]; then
   start_stacks student-lab
elif [ "$1" == "update" ]; then
  update_dockerfiles
  update_env
elif [ "$1" == "start" ]; then
  start_stacks $2
elif [ "$1" == "stop" ]; then
  stop_stacks $2
elif [ "$1" == "install" ]; then
  install_packages
  update_dockerfiles
  update_env
  update_wazuh_certs
  start_stacks
elif [ "$1" == "reconfig" ]; then
  update_env
  restart_mafl_service_discovery
  restart_mafl
  restart_traefik
  restart_casdoor
  restart_grafana
  update_sshwifty
elif [ "$1" == "sshwifty" ]; then
   update_sshwifty
else
  echo "Invalid argument: $1"
  echo "Usage: $0 [update|start|stop|install|reconfig]"
fi


