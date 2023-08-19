#!/bin/bash

set -e

# Local Env
program=Kubernetes

# Icons
start_icon="\xF0\x9F\x9B\xA0 " # Hammer and Wrench (U+1F6E0)

# Summary
display_usage(){
        cat << EOF

Usage: $0 [OPTIONS]

Template script for $(basename "$0" | cut -d. -f1)

    OPTIONs
        -i                  Install Kubernetes using apt
        -p                  Handle all Prerequisites
        -g                  Get Kubectl binary
        -s                  Disable Swap
        -d                  Get Docker
        -c                  Create New Cluster
        -a [CLUSTER_IDS]    Add Worker Node
        -h                  Show this page

EOF
    
    exit 0
}

# Prequisites:
disable_swap(){
    printf "\n$start_icon Disabling Swap\n"
    sudo swapoff -a
    sudo sed -i '/ swap / s/^/#/' /etc/fstab
}

get_docker(){
    printf "\n$start_icon Getting Docker dependencies\n"
    sudo apt install -y docker.io
}

handle_prerequisites(){
    printf "\n$start_icon Handling all Prerequisites\n"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y apt-transport-https ca-certificates curl gpg
    disable_swap
    get_docker
}

# Install options
get_kubectl_bin(){
    local version=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    local arch="amd64"
    curl -LO "https://dl.k8s.io/release/$version/bin/linux/$arch/kubectl"
    curl -LO "https://dl.k8s.io/release/$version/bin/linux/$arch/kubectl.sha256"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    kubectl version --client
}

install_kubernetes_apt(){
    local keyrings=/etc/apt/keyrings/kubernetes-apt-keyring.gpg
    local sources=/etc/apt/sources.list.d/kubernetes.list
    local api=https://pkgs.k8s.io/core:/stable:
    local version=v1.29
    
    local repo=$api/$version/deb
    local key=$repo/Release.key
    
    printf "\n$start_icon Setting up apt Repo for $program\n"
    curl -fsSL $key | sudo gpg --dearmor -o $keyrings
    echo "deb [signed-by=$keyrings] $repo/ /" | sudo tee $sources
    
    printf "\n$start_icon Installing $program using apt\n"
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
}

# Manage Cluster
create_cluster(){
    printf "\n$start_icon Creating new master cluster\n"
    sudo kubeadm init
}

add_worker(){
    if [[ $# -lt 1 ]]; then
        echo "Usage: $(basename "$0") -a cluster_ids" >&2
        return 1
    fi
    printf "\n$start_icon Adding workder to master node\n"
    kubeadm join $@
}

use_calico_configs(){
    local configurations=https://docs.projectcalico.org/manifests/calico.yaml
    
    # Get Kubectl Configs File
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/admin.conf
    sudo chown $(id -u):$(id -g) $HOME/.kube/admin.conf
    
    # Configure Pod Network
    kubectl apply -f $configurations
}

# ---------------------------------------------------------------------- #
# Main Function
# ---------------------------------------------------------------------- #
main(){
    while getopts "ipgsdca:h" OPTION; do
        case $OPTION in
            i) install_kubernetes_apt   ;;
            p) handle_prerequisites     ;;
            g) get_kubectl_bin          ;;
            s) disable_swap             ;;
            d) get_docker               ;;
            c) create_cluster           ;;
            a) add_worker $OPTARG       ;;
            h) display_usage            ;;
            ?) display_usage            ;;
        esac
    done
    shift $((OPTIND -1))
}

main $@
