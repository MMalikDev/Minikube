#!/bin/bash

set -e

# Local Env
program=Minikubes
API=https://storage.googleapis.com/minikube/releases/latest

# Icons
start_icon="\xF0\x9F\x9B\xA0 " # Hammer and Wrench (U+1F6E0)

# Summary
display_usage(){
        cat << EOF

Usage: $0 [OPTIONS]

Template script for $(basename "$0" | cut -d. -f1)

    OPTIONs
        -i      Install Binary (x86-64)
        -b      Install Binary (arm64)
        -d      Install Deb (x86-64)
        -a      Install Deb (arm64)
        -h      Show this page

EOF
    
    exit 0
}

# OPTIONS
install_binary(){
    printf "\n$start_icon Installing $program using binary\n"
    
    curl -LO $API/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
}

install_binary_arm64(){
    printf "\n$start_icon Installing $program using binary for arm64\n"
    
    curl -LO $API/minikube-linux-arm64
    sudo install minikube-linux-arm64 /usr/local/bin/minikube
}

install_deb(){
    printf "\n$start_icon Installing $program using deb\n"
    
    curl -LO $API/minikube_latest_amd64.deb
    sudo dpkg -i minikube_latest_amd64.deb
}

install_deb_arm64(){
    printf "\n$start_icon Installing $program using deb for arm64\n"
    
    curl -LO $API/minikube_latest_arm64.deb
    sudo dpkg -i minikube_latest_arm64.deb
}

# ---------------------------------------------------------------------- #
# Main Function
# ---------------------------------------------------------------------- #
main(){
    while getopts "ibdah" OPTION; do
        case $OPTION in
            i) install_binary       ;;
            b) install_binary_arm64 ;;
            d) install_deb          ;;
            a) install_deb_arm64    ;;
            h) display_usage        ;;
            ?) display_usage        ;;
        esac
    done
    shift $((OPTIND -1))
    minikube version
}

main $@
