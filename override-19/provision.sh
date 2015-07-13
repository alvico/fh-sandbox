#!/bin/sh

set -uxe
CLI_HOST="$(docker ps | grep midonet-api | awk '{print $1}')"
CLI_COMMAND="docker exec $CLI_HOST midonet-cli -A -e"

HOST0_ID=$($CLI_COMMAND host list | head -n 1 | awk '{print $2}')
HOST1_ID=$($CLI_COMMAND host list | tail -n 1 | awk '{print $2}')
HOST0_NAME=$($CLI_COMMAND host $HOST0_ID show name)
HOST1_NAME=$($CLI_COMMAND host $HOST1_ID show name)

# restarting midolman to load the configuration changes made by clio
docker restart $HOST0_NAME
docker restart $HOST1_NAME

MIDOLMAN1_IP="$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $HOST0_NAME)"
MIDOLMAN2_IP="$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $HOST1_NAME)"

MIDOLMAN1_CMD="docker exec $HOST0_NAME"
MIDOLMAN2_CMD="docker exec $HOST1_NAME"

# Create the tunnelzone and add midolman

$CLI_COMMAND tunnel-zone create name default type vxlan 

TZONEID=$($CLI_COMMAND tunnel-zone list | awk '{print $2}')

$CLI_COMMAND tunnel-zone $TZONEID add member host $HOST0_ID address $MIDOLMAN1_IP
$CLI_COMMAND tunnel-zone $TZONEID add member host $HOST1_ID address $MIDOLMAN2_IP


# Create a bridge

$CLI_COMMAND bridge create name demo

BRIDGEID=$($CLI_COMMAND bridge list | tail -n 1 | awk '{print $2}')

$CLI_COMMAND bridge $BRIDGEID add port
$CLI_COMMAND bridge $BRIDGEID add port


PORT0ID=$($CLI_COMMAND bridge $BRIDGEID port list | head -n 1 | awk '{print $2}')
PORT1ID=$($CLI_COMMAND bridge $BRIDGEID port list | tail -n 1 | awk '{print $2}')

# Create a ns in the first midolman
$MIDOLMAN1_CMD ip netns add left
$MIDOLMAN1_CMD ip link add name leftdp type veth peer name leftns
$MIDOLMAN1_CMD ip link set leftdp up
$MIDOLMAN1_CMD ip link set leftns netns left
$MIDOLMAN1_CMD ip netns exec left ip link set leftns up
$MIDOLMAN1_CMD ip netns exec left ip address add 10.25.25.1/24 dev leftns
$MIDOLMAN1_CMD ip netns exec left ip link set dev lo up


# Create a ns in the second midolman
$MIDOLMAN2_CMD ip netns add right
$MIDOLMAN2_CMD ip link add name rightdp type veth peer name rightns
$MIDOLMAN2_CMD ip link set rightdp up
$MIDOLMAN2_CMD ip link set rightns netns right
$MIDOLMAN2_CMD ip netns exec right ip link set rightns up
$MIDOLMAN2_CMD ip netns exec right ip address add 10.25.25.2/24 dev rightns
$MIDOLMAN2_CMD ip netns exec right ip link set dev lo up

# bind
$CLI_COMMAND host $HOST0_ID add binding interface leftdp port $PORT0ID
$CLI_COMMAND host $HOST1_ID add binding interface rightdp port $PORT1ID

