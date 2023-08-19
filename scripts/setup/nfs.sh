#!/bin/bash

set -e

# Local Env
program=NFS

# Icons
start_icon="\xF0\x9F\x9B\xA0 " # Hammer and Wrench (U+1F6E0)

# Summary
display_usage(){
        cat << EOF

Usage: $0 [OPTIONS]

Template script for $(basename "$0" | cut -d. -f1)

    OPTIONs
        -i      Install NFS Kernel Server
        -c      Create an NFS Export Directory
        -g      Grant NFS Share Access to Client Systems in Subnet
        -a      Apply Conifgs
        -h      Show this page

EOF
    
    exit 0
}

# OPTIONS
install_nfs(){
    printf "\n$start_icon Installing $program using apt\n"
    sudo apt update
    sudo apt install nfs-kernel-server
}

create_export_directory(){
    printf "\n$start_icon Create an $program Export Directory\n"
    sudo mkdir -p /mnt/nfs
    sudo chmod -R 777 /mnt/nfs
    sudo chown -R nobody:nogroup /mnt/nfs
}

grant_subnet_access(){
    printf "\n$start_icon Grant $program Share Access to Client Systems in Subnet\n"
    touch /etc/exports
    local client='/mnt/nfs 192.168.8.0/24(rw,sync,no_subtree_check)'
    local exist=$(grep -c "^$client" /etc/exports)
    if [[ $exist == 0 ]] && echo $client >> /etc/exports
}

apply_conifgs(){
    printf "\n$start_icon Export the $program Share Directory\n"
    sudo exportfs -a
    sudo systemctl restart nfs-kernel-server
}

adjust_firewall(){
    printf "\n$start_icon Allow $program Access through the Firewall\n"
    sudo ufw allow from 192.168.43.0/24 to any port nf
    sudo ufw enable
    sudo ufw status
}
get_client(){
    printf "\n$start_icon Installing $program Client Packages\n"
    sudo apt install nfs-common
    sudo mkdir -p /mnt/nfs_clientshare
    sudo mount 192.168.43.234:/mnt/nfs_share  /mnt/nfs_clientshare
}

# ---------------------------------------------------------------------- #
# Main Function
# ---------------------------------------------------------------------- #
main(){
    while getopts "icgah" OPTION; do
        case $OPTION in
            i) install_nfs              ;;
            c) create_export_directory  ;;
            g) grant_subnet_access      ;;
            a) apply_conifgs            ;;
            h) display_usage            ;;
            ?) display_usage            ;;
        esac
    done
    shift $((OPTIND -1))
}

main $@
