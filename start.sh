#!/bin/bash
set -e

sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1 || true

TA_KEY="/etc/openvpn/easy-rsa/ta.key"
PKI_DIR="/etc/openvpn/easy-rsa/pki"

if [ ! -f "$TA_KEY" ] || [ ! -d "$PKI_DIR" ]; then

    # Генерация ta.key
    if [ ! -f "$TA_KEY" ]; then
        openvpn --genkey --secret "$TA_KEY"
    fi

    # Генерация PKI и сертификатов
    if [ ! -d "$PKI_DIR" ]; then
        cd /etc/openvpn/easy-rsa
        easyrsa init-pki
        easyrsa build-ca
        easyrsa gen-req server nopass
        easyrsa sign-req server server
        easyrsa gen-dh
    fi
fi

iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

openvpn --config /etc/openvpn/server/server.conf
