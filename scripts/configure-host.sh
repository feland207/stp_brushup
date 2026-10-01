#!/bin/sh
# Shared across all end-host nodes (host1, host3) via bind mount.
# Required env var:
#   HOST_IP   - CIDR address for eth1, e.g. "192.168.99.101/24"
set -e

ip addr add "$HOST_IP" dev eth1
ip link set eth1 up
