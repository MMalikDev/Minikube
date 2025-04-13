#!/bin/bash

set -e

# Local Env
program=Docker

# Icons
start_icon="\xF0\x9F\x9B\xA0 " # Hammer and Wrench (U+1F6E0)

# Summary
display_usage(){
        cat << EOF

Usage: $0 [OPTIONS]

Template script for $(basename "$0" | cut -d. -f1)

    OPTIONs
        -a              Add User to new docker group
        -s              Setup APT for docker
        -i              Install Latest Version
        -v [VERSION]    Install Specific Version
        -l              List Docker Versions
        -g              Get Gnome Terminal
        -r              Remove Old Docker Version
        -p              Handle All Required Prerequisites
        -c              Show Docker Version
        -h              Show this page

EOF
    
    exit 0
}

# OPTIONS

# Prerequisites
remove_old(){
    printf "\n$start_icon remove old $program install\n"
    sudo apt remove docker-desktop
    sudo apt purge docker-desktop
    rm -r $HOME/.docker/desktop
    sudo rm /usr/local/bin/com.docker.cli
}

get_gnome(){
    printf "\n$start_icon Getting gnome dependencies\n"
    sudo apt install -y gnome-terminal
}

handle_prerequisites(){
    printf "\n$start_icon Getting All Prerequisites\n"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y apt-transport-https ca-certificates curl gpg
}

# Setup options
setup_apt(){
    local url="https://download.docker.com/linux/debian"
    local keyrings="/etc/apt/keyrings/docker.gpg"
    local official="$url/gpg"
    
    local architecture=$(dpkg --print-architecture)
    local version=$(. /etc/os-release && echo "$VERSION_CODENAME")
    
    printf "\n$start_icon Setting up apt Repo for $program\n"
    
    # Add Docker's official GPG key:
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL $official| sudo gpg --dearmor -o $keyrings
    sudo chmod a+r $keyrings
    
    # Add the repository to APT sources:
    echo "deb [arch=$architecture signed-by=$keyrings] $url $version stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
}

# Install options
install_latest(){
    printf "\n$start_icon Installing $program using apt\n"
    sudo apt install -y docker-ce docker-ce-cli
    sudo apt install -y containerd.io docker-buildx-plugin docker-compose-plugin
}

install_version(){
    local VERSION_STRING="$@"
    printf "\n$start_icon Installing $program ($VERSION_STRING) using apt\n"
    sudo apt install -y docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING
    sudo apt install -y containerd.io docker-buildx-plugin docker-compose-plugin
}

list_versions(){
    printf "\n$start_icon Listing all available $program version\n"
    apt-cache madison docker-ce | awk '{ print $3 }'
}

add_user(){
    printf "\n$start_icon Add current user ($USER) to $program group\n"
    sudo groupadd docker
    sudo usermod -aG docker $USER
    newgrp docker
}

show_current_version(){
    docker --version
    docker compose version
}

# ---------------------------------------------------------------------- #
# Main Function
# ---------------------------------------------------------------------- #
main(){
    while getopts "asiv:lgrpch" OPTION; do
        case $OPTION in
            a) add_user                 ;;
            s) setup_apt                ;;
            i) install_latest $OPTARG   ;;
            v) install_version          ;;
            l) list_versions            ;;
            g) get_gnome                ;;
            r) remove_old               ;;
            p) handle_prerequisites     ;;
            c) show_current_version     ;;
            h) display_usage            ;;
            ?) display_usage            ;;
        esac
    done
    shift $((OPTIND -1))
}

main $@
