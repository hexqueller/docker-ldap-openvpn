#!/bin/bash

# Проверка аргументов
if [ "$#" -ne 2 ]; then
    echo "Использование: $0 <Сервер> <Порт>" >&2
    exit 1
fi

SERVER_ADDR="$1"
SERVER_PORT="$2"
OUTPUT_FILE="client.ovpn"

# Проверка, что Easy-RSA и TLS-ключи существуют
CA_CERT="./openvpn_data/easy-rsa/pki/ca.crt"
TLS_KEY="./openvpn_data/easy-rsa/ta.key"

CLIENT_CERT="./openvpn_data/easy-rsa/pki/issued/client1.crt"
CLIENT_KEY="./openvpn_data/easy-rsa/pki/private/client1.key"

if [ ! -f "$CA_CERT" ] || [ ! -f "$TLS_KEY" ]; then
    echo "Ошибка: Не найдены CA-сертификат или TLS-ключ!" >&2
    exit 1
fi

if [ ! -f "$CLIENT_CERT" ] || [ ! -f "$CLIENT_KEY" ]; then
    echo "Ошибка: Не найдены Client-сертификат или Client-ключ!" >&2
    exit 1
fi

# Создаем клиентский конфиг
{
    echo "client"
    echo "dev tun"
    echo "proto udp"
    echo "remote $SERVER_ADDR"
    echo "port $SERVER_PORT"
    echo "resolv-retry infinite"
    echo "nobind"
    echo "persist-key"
    echo "persist-tun"
    echo "remote-cert-tls server"
    echo "auth SHA256"
    echo "cipher AES-256-GCM"
    echo "verb 3"
    echo ""
    echo "<ca>"
    cat "$CA_CERT"
    echo "</ca>"
    echo ""
    echo "<cert>"
    cat "$CLIENT_CERT"
    echo "</cert>"
    echo ""
    echo "<key>"
    cat "$CLIENT_KEY"
    echo "</key>"
    echo ""
    echo "key-direction 1"
    echo "<tls-auth>"
    cat "$TLS_KEY"
    echo "</tls-auth>"
    echo ""
    echo "auth-user-pass"
} > "$OUTPUT_FILE"

echo "Файл конфигурации сохранен как: $OUTPUT_FILE"