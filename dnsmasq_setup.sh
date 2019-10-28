#!/bin/sh

# dnsmasq_setup.sh

# This file is intended to set up local DNS caching for EKS nodes.
# It assumes that your current resolv.conf is working and valid, and uses that
# for DNSMasq's configuration, then sets up DNSMasq as the system-wide resolver.
# It is designed for Amazon Linux 2, but could easily be made to work with other
# distributions if needed.

# DISCLAIMER: This file is provided in hopes it will be useful. You are free to
# modify it if needed. No warranty comes with this, express or implied.

# Configuration

# Maximum number of queries for DNSMasq to handle concurrently.
# You may want to adjust this upward if you are seeing DNS failures.
DNS_FORWARD_MAX=500
CACHE_SIZE=1000

LOCAL_INTERFACE=eth0
LISTEN_PORT=53
PID_FILE=/var/run/dnsmasq.pid
# The path for dnsmasq's own resolv.conf, not the system-wide one
RESOLV_FILE=/etc/resolv.dnsmasq

# Local ip address. CoreDNS will not work correctly if we use 127.0.0.1
LOCAL_IP=$(ip -4 addr show $LOCAL_INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# Update installed packages, and install dnsmasq
yum -y update
yum -y install dnsmasq

# Create a user and group for dnsmasq to run as
groupadd -r dnsmasq
useradd -r -g dnsmasq dnsmasq

# Backup dnsmasq.conf
cp /etc/dnsmasq.conf /etc/dnsmasq.conf.orig

# Create DNSMasq's resolv.conf
cp /etc/resolv.conf $RESOLV_FILE

chown root:root $RESOLV_FILE
chmod 644 $RESOLV_FILE

# Configure dnsmasq
cat > /etc/dnsmasq.conf <<EOF
listen-address=$LOCAL_IP
port=$LISTEN_PORT
bind-interfaces
user=dnsmasq
group=dnsmasq
pid-file=$PID_FILE
no-hosts
dns-forward-max=$DNS_FORWARD_MAX
cache-size=$CACHE_SIZE
resolv-file=$RESOLV_FILE
EOF

# Configure system to resolve queries via DNSMasq
cat > /etc/resolv.conf <<EOF
nameserver $LOCAL_IP
EOF

# Enable DNSMasq
systemctl enable dnsmasq

reboot
