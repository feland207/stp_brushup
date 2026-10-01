#!/bin/sh
# Shared across all switch nodes (sw1, sw2, sw3) via bind mount.
# Per-node differences come in entirely through environment variables
# set in the topology file's `env:` block — this script itself never
# changes between nodes.
#
# Required env vars:
#   BRIDGE_IFACES   - space-separated list of interfaces to bridge,
#                      e.g. "eth1 eth2" or "eth1 eth2 eth3"
#   BRIDGE_IP       - CIDR address for br0, e.g. "192.168.99.11/24"
# Optional:
#   STP_PRIORITY    - bridge priority (default 32768 if unset)
set -e

ip link add name br0 type bridge
ip link set br0 type bridge stp_state 1

if [ -n "$STP_PRIORITY" ]; then
    ip link set dev br0 type bridge priority "$STP_PRIORITY"
fi

for iface in $BRIDGE_IFACES; do
    ip link set "$iface" master br0
    ip link set "$iface" up
done

ip link set br0 up

if [ -n "$BRIDGE_IP" ]; then
    ip addr add "$BRIDGE_IP" dev br0
fi
