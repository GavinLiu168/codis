#!/bin/bash

set -o xtrace
#hostip=`ifconfig eth0 | grep "inet " | awk -F " " '{print $2}'`
hostip=`ifconfig | grep '14:7d:da:1c:6c:47' -C2 | grep 10.12 | awk '{print $2}'`
path=`pwd`

if [ "x$hostip" == "x" ]; then
    echo "cann't resolve host ip address"
    exit 1
fi

mkdir -p log

case "$1" in
# zookeeper)
#     docker rm -f      "Codis-Z2181" &> /dev/null
#     docker run --name "Codis-Z2181" -d \
#             --read-only \
#             -p 2181:2181 \
#             jplock/zookeeper
#     ;;

zookeeper)
    docker rm -f      "Codis-Z2181" &> /dev/null
    docker run --name "Codis-Z2181" -d \
            -p 2181:2181 \
            jplock/zookeeper
    ;;


# dashboard)
#     docker rm -f      "Codis-D28080" &> /dev/null
#     docker run --name "Codis-D28080" -d \
#         --privileged=true \
#         --read-only -v $path/config/dashboard.toml:/codis/dashboard.toml \
#                     -v $path/log:/codis/log \
#         -p 28080:18080 \
#         codis-image \
#         codis-dashboard -l log/dashboard.log -c dashboard.toml --host-admin ${hostip}:28080
#     ;;

dashboard)
    docker rm -f      "Codis-D28080" &> /dev/null
    docker run --name "Codis-D28080" -d \
        -v $path/config/dashboard.toml:/codis/dashboard.toml \
        -v $path/log:/codis/log \
        -p 28080:18080 \
        codis-image \
        codis-dashboard -l log/dashboard.log -c dashboard.toml --host-admin ${hostip}:28080 --zookeeper ${hostip}:2181
    ;;



# proxy)
#     docker rm -f      "Codis-P29000" &> /dev/null
#     docker run --name "Codis-P29000" -d \
#         --read-only -v $path/config/proxy.toml:/codis/proxy.toml \
#                     -v $path/log:/codis/log \
#         -p 29000:19000 -p 21080:11080 \
#         codis-image \
#         codis-proxy -l log/proxy.log -c proxy.toml --host-admin ${hostip}:21080 --host-proxy ${hostip}:29000
#     ;;



proxy)
    docker rm -f      "Codis-P29000" &> /dev/null
    docker run --name "Codis-P29000" -d \
        --read-only -v $path/config/proxy.toml:/codis/proxy.toml \
                    -v $path/log:/codis/log \
        -p 29000:19000 -p 21080:11080 \
        codis-image \
        codis-proxy -l log/proxy.log -c proxy.toml --host-admin ${hostip}:21080 --host-proxy ${hostip}:29000 --dashboard=${hostip}:28080
    ;;



# server)
#     for ((i=0;i<4;i++)); do
#         let port="26379 + i"
#         docker rm -f      "Codis-S${port}" &> /dev/null
#         docker run --name "Codis-S${port}" -d \
#             -v $path/log:/codis/log \
#             -p $port:6379 \
#             codis-image \
#             codis-server --logfile log/${port}.log
#     done
#     ;;

server)
    for ((i=0;i<4;i++)); do
        let port="26379 + i"
        docker rm -f      "Codis-S${port}" &> /dev/null
        docker run --name "Codis-S${port}" -d \
            -v $path/log:/codis/log \
            -p $port:6379 \
            codis-image \
            codis-server --protected-mode no --logfile log/${port}.log
    done
    ;;



fe)
    docker rm -f      "Codis-F8080" &> /dev/null
    docker run --name "Codis-F8080" -d \
         -v $path/log:/codis/log \
         -p 8080:8080 \
     codis-image \
     codis-fe -l log/fe.log --zookeeper ${hostip}:2181 --listen=0.0.0.0:8080 --assets=/gopath/src/github.com/CodisLabs/codis/bin/assets
    ;;

cleanup)
    docker rm -f      "Codis-F8080" &> /dev/null
    docker rm -f      "Codis-D28080" &> /dev/null
    docker rm -f      "Codis-P29000" &> /dev/null
    for ((i=0;i<4;i++)); do
        let port="26379 + i"
        docker rm -f      "Codis-S${port}" &> /dev/null
    done
    docker rm -f      "Codis-Z2181" &> /dev/null
    ;;

standalone)
    chmod -R 777 $path/log 
    $path/scripts/docker.sh zookeeper 
    $path/scripts/docker.sh dashboard 
    $path/scripts/docker.sh proxy 
    $path/scripts/docker.sh server 
    $path/scripts/docker.sh fe 
    ;;
*)
    echo "wrong argument(s)"
    ;;

esac
