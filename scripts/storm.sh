#!/bin/bash

# first script argument: the servers in the ZooKeeper ensemble:
ZOOKEEPER_SERVERS=$1

# second script argument: number of supervisors to launch
SUPERVISORS=$2
# if no valid number was given: just assume 1 as default
if ! [[ $SUPERVISORS =~ ^[0-9]+ ]] ; then
   echo "no number was provided (\"$SUPERVISORS\"). Will proceed with 1 supervisor."
   SUPERVISORS=1
fi

# launch nimbus
docker run \
    -d \
    --label cluster=storm \
    -e constraint:server==manager \
    -e STORM_ZOOKEEPER_SERVERS=$ZOOKEEPER_SERVERS \
    --net stormnet \
    --restart=always \
    --name nimbus \
    -p 6627:6627 \
    baqend/storm nimbus \
      -c nimbus.host=nimbus

# launch UI
docker run \
    -d \
    --label cluster=storm \
    -e constraint:server==manager \
    -e STORM_ZOOKEEPER_SERVERS=$ZOOKEEPER_SERVERS \
    --net stormnet \
    --restart=always \
    --name ui \
    -p 8080:8080 \
    baqend/storm ui \
      -c nimbus.host=nimbus

# launched the supervisor's
for (( i=1; i <= $SUPERVISORS; i++ )); do
      docker run \
          -d \
          --label cluster=storm \
          --label container=supervisor \
          -e affinity:container!=supervisor \
          -e STORM_ZOOKEEPER_SERVERS=$ZOOKEEPER_SERVERS \
          --net stormnet \
          --restart=always \
          baqend/storm supervisor \
           -c nimbus.host=nimbus \
           -c supervisor.slots.ports=6700,6701,6702,6703
done