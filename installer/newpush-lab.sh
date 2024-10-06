#!/bin/bash
LAB_HOME="/opt/student-lab"

SERVICES_DIR="$LAB_HOME/services"
STACKS_DIR="$SERVICES_DIR/dockge/stacks"

# Manage lab function which takes two arguments:
#  Action: Status, Start, Stop, Remove, Update
#  Stack: core, lab-security-wazuh, lab-security-openvas, etc..

# Example:
#  newpush-lab start core
#  newpush-lab stop lab-security-wazuh
#  newpush-lab remove lab-security-openvasd
#  newpush-lab update lab-tools-jupyter

# For core stack the dockerfile is at LAB_HOME/services/docker-compose.yaml
# For lab-* stacks the dockerfile is at STACKS_DIR/lab-*

# The docker compose project name is the stack name
function manage_lab() {
  local action=$1
  local stack=$2

  local project_name=${stack}
  if [ "$stack" == "core" ]; then
    local project_name="lab-core"
    local compose_file=$LAB_HOME/services/docker-compose.yaml
  else
    # Check if the stack directory exists
    if [ -d "$STACKS_DIR/$stack" ]; then
      local compose_file=$STACKS_DIR/$stack/compose.yaml
    else
      echo "Stack directory not found: $STACKS_DIR/$stack"
      return 1
    fi
  fi

  case "$action" in
    "status")
      docker compose -f $compose_file -p $project_name ps
      ;;
    "start")
      docker compose -f $LAB_HOME/services/docker-compose.yaml -p $project_name up -d
      ;;
    "stop")
      docker compose -f $LAB_HOME/services/docker-compose.yaml -p $project_name stop
      ;;
    "restart")
      docker compose -f $LAB_HOME/services/docker-compose.yaml -p $project_name restart
      ;;
    "remove")
      docker compose -f $LAB_HOME/services/docker-compose.yaml -p $project_name down
      ;;
    "recreate")
      docker compose -f $compose_file -p $project_name up -d --force-recreate
      ;;
    *)
      echo "Invalid action: $action"
      return 1
      ;;
  esac
}

function update_env() {
  cd $LAB_HOME
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

function restart_container() {
  local container_name=$1

  if [ -z "$container_name" ]; then
    echo "Container name is required."
    return 1
  fi

  if docker ps --filter "name=$container_name" --filter "status=running" | grep -q $container_name; then
    local container_id=$(docker ps --filter "name=$container_name" --filter "status=running" | grep -oP '^\S+' | tail -n 1)

    echo "$container_name docker is running as $container_id. Restarting..."
    docker restart $container_id
  else
    echo "$container_name docker is not running."
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


case $1 in
  "update_env")
    update_env
    update_sshwifty
    ;;
  "status")
    manage_lab status $2
    ;;
  "start")
    manage_lab start $2
    ;;
  "stop")
    manage_lab stop $2
    ;;
  "restart")
    manage_lab restart $2
    ;;
  "remove")
    manage_lab remove $2
    ;;
  "recreate")
    manage_lab recreate $2
    ;;
  "restart-container")
    restart_container $2
    ;;
  *)
    echo "Invalid argument: $1"
    echo "Usage: $0 [recreate|update|status|start|stop|restart|remove|update]"
    ;;
esac
