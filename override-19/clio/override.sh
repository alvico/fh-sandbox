#!/bin/sh
set -uxe
dpkg -i /override/clio*.deb


#sleep 25
# --- setup clio and calliope

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

cat << EOF > /etc/midonet-clio/midonet-clio.conf
[zookeeper]
zookeeper_hosts = $MIDO_ZOOKEEPER_HOSTS
root_key = $MIDO_ZOOKEEPER_ROOT_KEY
EOF


cat /etc/hosts

ELKIP="$(cat /etc/hosts | grep 'elk1 ' | awk '{print $1}')"

HOSTNAME="$(hostname)"
CLIOIP="$(cat /etc/hosts | grep $HOSTNAME | awk '{print $1}')"

mn-conf set -t default <<EOF
clio.enabled=true 
calliope.enabled=true
clio.use_old_stack=true
agent.flow_history.enabled=true
EOF

echo "clio.target.udp_endpoint : \"$ELKIP:5000\"" | mn-conf set -t default 
echo "agent.flow_history.udp_endpoint : \"$CLIOIP:5001\"" | mn-conf set -t default 
echo "calliope.backend.elasticsearch.transport_endpoint : [\"$ELKIP:9300\"]" | mn-conf set -t default

/override/run_clio.sh
