#!/bin/bash
set -e

sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1 || true

TA_KEY="/etc/openvpn/easy-rsa/ta.key"
if [ ! -f "$TA_KEY" ]; then
    openvpn --genkey --secret "$TA_KEY"
fi

iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

openvpn --config /etc/openvpn/server/server.conf
