#!/bin/bash

set -e

CONTAINER_NAME=$1
LINK_CLIENT_WG_PUBKEY=$2

# get local port range
read LOWER_PORT UPPER_PORT < /proc/sys/net/ipv4/ip_local_port_range
# credit: https://unix.stackexchange.com/a/423052
# compare active udp ports against local port range, select an open port at random
WIREGUARD_PORT=$(comm -23 <(seq $LOWER_PORT $UPPER_PORT | sort) <(ss -Huan | awk '{print $4}' | cut -d':' -f2 | sort -u) | shuf | head -1)

# create gateway-link container
CONTAINER_ID=$(docker run --name $CONTAINER_NAME --network gateway -p $WIREGUARD_PORT:18521/udp --cap-add NET_ADMIN --restart unless-stopped -it -e LINK_CLIENT_WG_PUBKEY=$LINK_CLIENT_WG_PUBKEY -d fractalnetworks/gateway-link:latest)
# get gateway-link WireGuard pubkey 
GATEWAY_LINK_WG_PUBKEY=$(docker exec $CONTAINER_NAME bash -c 'cat /etc/wireguard/link0.key |wg pubkey')
# get public ipv4 address
GATEWAY_IP=$(curl -s 4.icanhazip.com)

echo "$GATEWAY_LINK_WG_PUBKEY $GATEWAY_IP:$WIREGUARD_PORT"
