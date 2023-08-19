#!/bin/bash

set -e

# Local Env
program=Helm

# Icons
start_icon="\xF0\x9F\x9B\xA0 " # Hammer and Wrench (U+1F6E0)

# Summary
display_usage(){
        cat << EOF

Usage: $0 [OPTIONS]

Template script for $(basename "$0" | cut -d. -f1)

    OPTIONs
        -s                  Install Helm using script
        -i                  Install Helm using apt
        -g                  Install Helm from source
        -p                  Handle all Prerequisites
        -h                  Show this page

EOF
    
    exit 0
}

# Prequisites:
handle_prerequisites(){
    printf "\n$start_icon Handling all Prerequisites\n"
    sudo apt-get install -y apt-transport-https
}

# Install options
install_helm_sh(){
    local api=https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    curl -fsSL -o get_helm.sh $api
    chmod 700 get_helm.sh
    bash get_helm.sh
}

install_helm_apt(){
    local api=https://baltocdn.com/helm
    local keyrings="/usr/share/keyrings/helm.gpg "
    local sources="/etc/apt/sources.list.d/helm-stable-debian.list"
    
    local key="$api/signing.asc"
    local arch=$(dpkg --print-architecture)
    
    printf "\n$start_icon Setting up apt Repo for $program\n"
    curl $key | gpg --dearmor | sudo tee $keyrings > /dev/null
    echo "deb [arch=$arch signed-by=$keyrings] $api/stable/debian/ all main" | sudo tee $sources
    
    printf "\n$start_icon Installing $program using apt\n"
    sudo apt-get update
    sudo apt-get install helm
}

install_helm_git(){
    git clone https://github.com/helm/helm.git
    cd helm
    make
}

# ---------------------------------------------------------------------- #
# Main Function
# ---------------------------------------------------------------------- #
main(){
    while getopts "sigph" OPTION; do
        case $OPTION in
            s) install_helm_sh          ;;
            i) install_helm_apt         ;;
            g) install_helm_git         ;;
            p) handle_prerequisites     ;;
            h) display_usage            ;;
            ?) display_usage            ;;
        esac
    done
    shift $((OPTIND -1))
}

main $@
