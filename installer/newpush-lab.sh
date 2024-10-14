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
  local stack=${2:-core}
  
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

function migrate() {
  # Migrate lab to the latest version by ensuring all containers are stopped first to avoid name conflicts

  # List all docker compose projects and tear them down
  docker_compose_projects=$(docker compose ls --format json | jq -r '.[] | .Name')

  if [ -z "$docker_compose_projects" ]; then
    echo "No docker compose projects found."
  else
    for project in $docker_compose_projects; do
      echo "Tearing down docker compose project: $project"
      docker compose -p $project down
    done
  fi
  
  # Make sure we have the latest version of the docker images just in case
  
  # remove all lab related images
  remove_docker_images=$(docker images --filter=reference="lracz/*" --format "{{.ID}}")
  for image in $remove_docker_images; do
    docker image rm $image
  done

  docker_images=(
    "lracz/traefik-forward-auth:latest"
    "lracz/mafl-service-discovery:latest"
  )

  for image in "${docker_images[@]}"; do
    docker image rm $image
    docker image pull $image
  done
}

function info() {
  source $LAB_HOME/services/.env
  echo "Your lab can be accessed at: https://www.${DOMAIN}"
}

function free_up_disk_space() {
  apt-get clean
  journalctl --vacuum-size=100M
  docker container stop kali
  docker container rm kali
  docker image rm newpush/kali-linux-ssh
  docker system prune

  wazuh_manager_container=$(docker ps --filter "name=wazuh.manager" --filter "status=running" --format "{{.ID}}")

  if [ -n "$wazuh_manager_container" ]; then
    echo "Wazuh manager docker container is running with ID: $wazuh_manager_container"
    docker exec $wazuh_manager_container sh -c 'rm -rvf /var/ossec/queue/vd_updater/tmp/contents/*'
  else
    echo "Wazuh manager docker container is not running."
  fi
  
}

case $1 in
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
  "free-up-disk-space")
    free_up_disk_space
    ;;
  "migrate")
    migrate
    ;;
  "info")
    info
    ;;
  *)
    echo "Invalid argument: $1"
    echo "Usage: $0 [recreate|update|status|start|stop|restart|remove|update]"
    ;;
esac
