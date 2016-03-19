#!/bin/bash

# First argument is the ZooKeeper cluster that can be used for Docker Swarm coordination. It can either be a single IP address such as
#    1.2.3.4
# or a comma-separated list of IP addresses (no white spaces!) such as
#    1.2.3.4,5.6.7.8
ZOOKEEPER_SERVERS=$1

# find the IP address of the machine that is executing this code:
export PRIVATE_IP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')

#if ZooKeeper servers are not provided, use IP of this node and store in config file
if [ $# -eq 0 ] || [ -z "$ZOOKEEPER_SERVERS" ]
then
    # If no arguments are supplied, just assume this server to be the only ZooKeeper server
    read -p "Please provide ZooKeeper server IPs like \"1.2.3.4\" or \"1.2.3.4,5.6.7.8\" or leave empty to use only this server!\n" ZOOKEEPER_SERVERS
    # use $PRIVATE_IP
    if [ -z "$ZOOKEEPER_SERVERS" ]
    then
        ZOOKEEPER_SERVERS=$PRIVATE_IP
    fi
    echo -e "ZOOKEEPER_SERVERS=\e[1;32m$ZOOKEEPER_SERVERS\e[0m"
fi

export ZOOKEEPER_SERVERS=$ZOOKEEPER_SERVERS

# All ZooKeeper server IPs in an array
IFS=', ' read -r -a ZOOKEEPER_SERVERS_ARRAY <<< "$ZOOKEEPER_SERVERS"
export ZOOKEEPER_SERVERS_ARRAY=$ZOOKEEPER_SERVERS_ARRAY

# The ZooKeeper ID of this machine: if this machine is part of the ZooKeeper ensemble, it is an integer >=0. If this machine is not part of the ZooKeeper all sample, it is the empty string
ZOOKEEPER_ID=""
ZOOKEEPER_CLUSTERSIZE=0
for index in "${!ZOOKEEPER_SERVERS_ARRAY[@]}"
do
    echo "$index ${ZOOKEEPER_SERVERS_ARRAY[index]}"
    if [ "${ZOOKEEPER_SERVERS_ARRAY[index]}" == "$PRIVATE_IP" ]
    then
        ZOOKEEPER_ID=$index
    fi
    ZOOKEEPER_CLUSTERSIZE=$(($ZOOKEEPER_CLUSTERSIZE + 1))
done
export ZOOKEEPER_ID=$ZOOKEEPER_ID
export ZOOKEEPER_CLUSTERSIZE=$ZOOKEEPER_CLUSTERSIZE

echo "PRIVATE_IP: $PRIVATE_IP"
echo "ZOOKEEPER_SERVERS: $ZOOKEEPER_SERVERS"
echo "ZOOKEEPER_SERVERS_ARRAY: $ZOOKEEPER_SERVERS_ARRAY"
echo "ZOOKEEPER_ID: $ZOOKEEPER_ID"
echo "ZOOKEEPER_CLUSTERSIZE: $ZOOKEEPER_CLUSTERSIZE"

if [ -z $ZOOKEEPER_ID ]
then
    echo "Not part of the ZooKeeper ensemble!"
else
     echo "Will spawn ZooKeeper server with IP $PRIVATE_IP and ID $ZOOKEEPER_ID. The entire ensemble will have $ZOOKEEPER_CLUSTERSIZE members."
fi