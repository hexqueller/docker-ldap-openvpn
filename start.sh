#!/bin/bash
set -e

iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

openvpn --config /etc/openvpn/server/server.conf
