#!/bin/bash

# Icons
icon="\xE2\x8C\x9B" # Hourglass (U+231B)

# Functions
run(){
    local name=$1
    local func=$2
    local array=${@:3}
    
    if [[ -n "$array" ]]; then
        printf "\n$icon Removing the following $name: $array\n"
        $func $array
    else
        printf "\n$icon No $name were removed\n"
    fi
}

remove_folders(){
    rm -rf $@
}
remove_volumes(){
    docker volume rm $@
}
remove_images(){
    docker rmi $@
}

prune_docker(){
    printf "\n$icon Pruning Docker\n"
    echo y | docker system prune
}

end_proxy(){
    cd proxy
    docker compose down
    cd ..
}
