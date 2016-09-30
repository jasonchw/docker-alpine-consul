#!/bin/bash

set -e

CONSUL_BIN=/usr/local/bin/consul
CONSUL_BOOTSTRAP=${CONSUL_BOOTSTRAP:-false}

NODE_NAME=${NODE_PREFIX}-$(hostname -f)

sed -i -e "s#\"node_name\":.*#\"node_name\": \"${NODE_NAME}\",#" /etc/consul.d/agent.json

if [ "X${CONSUL_BOOTSTRAP}" == "Xtrue" ]; then
    sed -i -e "s#\"bootstrap\":.*#\"bootstrap\": true,#" /etc/consul.d/agent.json
    CONSUL_SERVER=true
elif [ "X${CONSUL_BOOTSTRAP_EXPECT}" != "X" ]; then
    sed -i -e "s#\"bootstrap\":.*#\"bootstrap_expect\": ${CONSUL_BOOTSTRAP_EXPECT},#" /etc/consul.d/agent.json
    CONSUL_SERVER=true
fi
if [ "X${CONSUL_SERVER}" == "Xtrue" ]; then
    sed -i -e "s#\"server\":.*#\"server\": true,#" /etc/consul.d/agent.json
fi

if [ ! -z "${CONSUL_CLUSTER_IPS}" ]; then
    START_JOIN=""
    for IP in $(echo ${CONSUL_CLUSTER_IPS} | sed -e 's/,/ /g'); do
        if [ "${NODE_NAME}" != "X${IP}" ]; then
            START_JOIN+=" ${IP}"
        elif [ "X${CONSUL_SKIP_CURL}" == "Xtrue" ]; then
            START_JOIN+=" ${IP}"
        fi
    done
    START_JOIN=$(echo ${START_JOIN}|sed -e 's/ /\",\"/g')
    if [ "X${START_JOIN}" != "X" ]; then
        sed -i -e "s#\"start_join\":.*#\"start_join\": [\"${START_JOIN}\"],#" /etc/consul.d/agent.json
    fi
fi

CONSUL_BIND=
if [ -n "$CONSUL_BIND_INTERFACE" ]; then
    CONSUL_BIND_ADDRESS=$(ip -o -4 addr list $CONSUL_BIND_INTERFACE | head -n1 | awk '{print $4}' | cut -d/ -f1)
    if [ -z "$CONSUL_BIND_ADDRESS" ]; then
        echo "Could not find IP for interface '$CONSUL_BIND_INTERFACE', exiting"
        exit 1
    fi

    CONSUL_BIND="-bind=$CONSUL_BIND_ADDRESS"
    echo "==> Found address '$CONSUL_BIND_ADDRESS' for interface '$CONSUL_BIND_INTERFACE', setting bind option..."
fi

trap 'consul leave' HUP INT TERM EXIT

setcap "cap_net_bind_service=+ep" ${CONSUL_BIN}

set -- gosu consul ${CONSUL_BIN} agent -config-file=/etc/consul.d/agent.json -config-dir=/etc/consul.d $CONSUL_BIND

exec "$@"

