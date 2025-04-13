#!/bin/bash

# Icons
icon_log="\xF0\x9F\x93\x91" # Bookmark Tabs (U+1F4D1)
icon_start="\xF0\x9F\x9B\xA0 " # Hammer and Wrench (U+1F6E0)

display_usage() {
    cat << EOF

Usage: $0 [OPTIONS] [ARGS]

Run Project in specified environment

    OPTIONS
     -b [SECRETS]   Get Base64 Encoding of Secret

     -g [OBJECTS]   Get Cluster Objects
     -c             Create Minikube Cluster
     -d             Delete Minikube Cluster

     -v             Setup Volumes (Default Local)
     -i             Setup Ingress and Controller
     -a             Setup All Demo Configs
     -r             Restart All Deployments

     -n             Setup noSQL Database Configs
     -s             Setup SQL Database Configs
     -p             Setup Monitoring Apps Configs
     -m             Setup Management Apps Configs
     -b             Setup Security Apps Configs

     -z             Start Minikube Tunnel
     -t             Tunnel to Ingress Controller Proxy
     -h             Display this help

    OBJECTS
        v* -> pv
        c* -> pvc
        p* -> pods
        h* -> nodes
        s* -> services
        d* -> deployment
        n* -> namespaces

EOF
    exit 1
}

# Generic
load_env(){
    set -a
    source .env
}
get_env(){
    echo $(grep -i "$@" .env | cut -d "=" -f 2)
}
get_bool(){
    local variable=$(get_env "$@" | tr '[A-Z]' '[a-z]')
    
    if [[ $variable =~ (1|true) ]]; then
        echo true
    else
        echo false
    fi
}

# Error Handlers
handle_errors(){
    if [[ $(get_bool KEEP_LOGS) == "true" ]]; then
        printf "\n$icon_log Keeping logs...\n\n"
        return
    fi
    if [[ $@ != 0 ]]; then
        printf "\n$icon_start Error encountered!\n\n"
        exit 1
    fi
    
    clear
    printf "\n$icon_log Cleared logs...\n\n"
}
log_error() {
    echo "$1" 2>&1;
    exit 1;
}

# Docker
reload_services(){
    local services=$@
    if [[ -n $services ]]; then
        printf "\n$icon_start Reloading the following service(s): "
        printf "$services\n\n"
    else
        printf "\n$icon_start Reloading all services\n\n"
    fi
    
    docker compose up -d
    echo "$services" | xargs docker compose kill
    echo "$services" | xargs docker compose up --force-recreate --build -d
}
follow_logs(){
    local services=$@
    if [[ -n $services ]]; then
        printf "\n$icon_log Getting logs from the following service(s): "
        printf "$services\n\n"
    else
        printf "\n$icon_log Getting logs from all services\n\n"
    fi
    
    echo "$services" | xargs docker compose logs -f
}
cp_docker(){
    local container=$1
    local source=$2
    local target=$3
    
    local containerID=$(docker-compose ps -qa $container)
    docker cp $containerID:$source $target
}

# Reverse Proxy
start_proxy(){
    cd proxy
    reload_services
    handle_errors $?
    
    docker image prune -f
    cd ..
}
