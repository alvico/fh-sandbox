#!/bin/sh

set -uxe 
dpkg -i /override/calliope*.deb

# --- setup clio and calliope
sleep 40

# Default mido_zookeeper_key
MIDO_ZOOKEEPER_ROOT_KEY=/midonet/v1

# Update ZK hosts in case they were linked to this container
MIDO_ZOOKEEPER_HOSTS="$(env | grep _PORT_2181_TCP_ADDR | sed -e 's/.*_PORT_2181_TCP_ADDR=//g' -e 's/^.*/&:2181/g' | sort -u)"
MIDO_ZOOKEEPER_HOSTS="$(echo $MIDO_ZOOKEEPER_HOSTS | sed 's/ /,/g')"

if [ -z "$MIDO_ZOOKEEPER_HOSTS" ]; then
    echo "No Zookeeper hosts specified neither by ENV VAR nor by linked containers"
    exit 1
fi

cat << EOF > /etc/midolman/midolman.conf
[zookeeper]
zookeeper_hosts = $MIDO_ZOOKEEPER_HOSTS
root_key = $MIDO_ZOOKEEPER_ROOT_KEY
EOF

/override/run_calliope.sh
