#!/bin/bash

# set -e

source ./scripts/run.sh
# ---------------------------------------------------------------------- #
# Define Docker Variables
# ---------------------------------------------------------------------- #
declare -a reloads=(
    #
)

declare -a logs=(
    #
)

# ---------------------------------------------------------------------- #
# Helper
# ---------------------------------------------------------------------- #
get_secret(){
    echo -n "$1" | base64
}

switch_namespace(){
    local namespace="$1"
    kubectl config set-context --current --namespace=$namespace
}

# ---------------------------------------------------------------------- #
# OPTIONS
# ---------------------------------------------------------------------- #
create_cluster(){
    minikube start;
}

delete_cluster(){
    minikube delete --all
}

get_obj(){
    case ${1} in
        v*) kubectl get pv -A                 ;;
        c*) kubectl get pvc -A                ;;
        p*) kubectl get pods -A               ;;
        h*) kubectl get nodes -A              ;;
        s*) kubectl get services -A           ;;
        d*) kubectl get deployment -A         ;;
        n*) kubectl get namespaces -A         ;;
        *) log_error "Unsupported object: $1" ;;
    esac
}

tunnel_proxy(){
    minikube service proxy --url=true
}

start_ingress(){
    local repo=proxy
    
    kubectl apply -f "${repo}/controller.yaml"
    kubectl apply -f "${repo}/ingress.yaml"
}

setup_volumes(){
    local repo=data
    
    kubectl apply -f "${repo}/localClass.yaml"
    kubectl apply -f "${repo}/volumes.yaml"
}

setup_database_sql(){
    local repo=apps/database
    kubectl apply -f "${repo}/namespace.yaml"
    
    kubectl apply -f "${repo}/data/postgres-pvc.yaml"
    kubectl apply -f "${repo}/configs/postgres-config.yaml"
    kubectl apply -f "${repo}/configs/postgres-secret.yaml"
    kubectl apply -f "${repo}/configs/pgadmin-secret.yaml"
    kubectl apply -f "${repo}/services/postgres-db.yaml"
    kubectl apply -f "${repo}/services/postgres-pgadmin.yaml"
    
    kubectl apply -f "${repo}/ingress.yaml"
    switch_namespace database
}

setup_database_nosql(){
    local repo=apps/database
    kubectl apply -f "${repo}/namespace.yaml"
    
    kubectl apply -f "${repo}/data/mongo-pvc.yaml"
    kubectl apply -f "${repo}/configs/mongo-secret.yaml"
    kubectl apply -f "${repo}/configs/mongo-config.yaml"
    kubectl apply -f "${repo}/services/mongo-db.yaml"
    kubectl apply -f "${repo}/services/mongo-express.yaml"
    
    kubectl apply -f "${repo}/ingress.yaml"
    switch_namespace database
}

setup_monitoring(){
    local repo=apps/monitoring
    kubectl apply -f "${repo}/namespace.yaml"
    
    kubectl apply -f "${repo}/services/grafana-app.yaml"
    
    kubectl apply -f "${repo}/data/uptimekuma-pvc.yaml"
    kubectl apply -f "${repo}/services/uptimekuma-app.yaml"
    
    kubectl apply -f "${repo}/data/prometheus-pvc.yaml"
    kubectl apply -f "${repo}/configs/prometheus-config.yaml"
    kubectl apply -f "${repo}/services/prometheus-app.yaml"
    
    kubectl apply -f "${repo}/ingress.yaml"
    switch_namespace monitoring
}

setup_management(){
    local repo=apps/management
    kubectl apply -f "${repo}/namespace.yaml"
    
    kubectl apply -f "${repo}/configs/homepage-configmap.yaml"
    kubectl apply -f "${repo}/configs/homepage-secret.yaml"
    kubectl apply -f "${repo}/services/homepage-app.yaml"
    
    kubectl apply -f "${repo}/data/portainer-pvc.yaml"
    kubectl apply -f "${repo}/services/portainer-app.yaml"
    
    kubectl apply -f "${repo}/ingress.yaml"
    switch_namespace management
}

setup_security(){
    local repo=apps/security
    kubectl apply -f "${repo}/namespace.yaml"
    
    kubectl apply -f "${repo}/data/vaultwarden-pvc.yaml"
    kubectl apply -f "${repo}/services/vaultwarden-app.yaml"
    
    kubectl apply -f "${repo}/ingress.yaml"
    switch_namespace security
}

setup_all(){
    setup_volumes
    start_ingress
    setup_database_nosql
    setup_database_sql
    setup_monitoring
    setup_management
    setup_security
}

restart_all(){
    kubectl rollout restart deployment -n default
    kubectl rollout restart deployment -n database
    kubectl rollout restart deployment -n monitoring
    kubectl rollout restart deployment -n management
    kubectl rollout restart deployment -n security
}

# ---------------------------------------------------------------------- #
# Main Function
# ---------------------------------------------------------------------- #
main(){
    while getopts "g:cdvarnspmbith" OPTION; do
        case $OPTION in
            g) get_obj $OPTARG      ;;
            c) create_cluster       ;;
            d) delete_cluster       ;;
            v) setup_volumes        ;;
            i) start_ingress        ;;
            a) setup_all            ;;
            r) restart_all          ;;
            n) setup_database_nosql ;;
            s) setup_database_sql   ;;
            p) setup_monitoring     ;;
            m) setup_management     ;;
            b) setup_security       ;;
            t) tunnel_proxy         ;;
            h) display_usage        ;;
            ?) display_usage        ;;
        esac
    done
    shift $((OPTIND -1))
}

main $@
