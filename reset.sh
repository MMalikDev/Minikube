#!/bin/bash

# set -e

source ./scripts/reset.sh
# ---------------------------------------------------------------------- #
# Main Function
# ---------------------------------------------------------------------- #
main(){
    # Delete Cluster
    minikube delete --all
    prune_docker
}

main $@
