#!/bin/sh
# Shared on every node (switches + hosts) via bind mount.
# Keeping this as its own script, separate from the role-specific
# configure-switch.sh / configure-host.sh, means the package list
# lives in exactly one place regardless of how many nodes use it.
set -e

apt-get update && apt-get install -y \
    python3 python3-pip less openssh-server tree frr \
    traceroute tcpdump iperf3 iproute2 iputils-ping git sudo
