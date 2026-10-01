#!/bin/sh
# Shared on every node (switches + hosts) via bind mount.
# Keeping this as its own script, separate from the role-specific
# configure-switch.sh / configure-host.sh, means the package list
# lives in exactly one place regardless of how many nodes use it.
set -e

apt-get update && apt-get install -y \
    python3 python3-pip less openssh-server tree frr \
    traceroute tcpdump iperf3 iproute2 iputils-ping git sudo

# --- SSH daemon setup ---
# /run/sshd must exist before sshd will start in a minimal container
mkdir -p /run/sshd
# Ensure host keys exist regardless of how the package postinst behaved
ssh-keygen -A

# --- deployer user + NOPASSWD sudo ---
if ! id deployer >/dev/null 2>&1; then
    useradd -m -s /bin/bash deployer
fi
echo "deployer:deployer123" | chpasswd

groupadd -f sudo
usermod -aG sudo deployer

cat > /etc/sudoers.d/nopasswd-sudo << 'SUDOERS'
%sudo ALL=(ALL) NOPASSWD:ALL
SUDOERS
chmod 0440 /etc/sudoers.d/nopasswd-sudo

# --- sshd_config: password auth for deployer only ---
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
grep -q '^AllowUsers' /etc/ssh/sshd_config || echo 'AllowUsers deployer' >> /etc/ssh/sshd_config

service ssh start
