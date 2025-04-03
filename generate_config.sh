#!/bin/bash

# Проверка аргументов
if [ "$#" -ne 1 ]; then
    echo "Использование: $0 <Сервер:Порт>" >&2
    exit 1
fi

SERVER_INFO="$1"
OUTPUT_FILE="client.ovpn"

# Проверка, что Easy-RSA и TLS-ключи существуют
CA_CERT="./openvpn_data/easy-rsa/pki/ca.crt"
TLS_KEY="./openvpn_data/easy-rsa/ta.key"

if [ ! -f "$CA_CERT" ] || [ ! -f "$TLS_KEY" ]; then
    echo "Ошибка: Не найдены CA-сертификат или TLS-ключ!" >&2
    exit 1
fi

# Создаем клиентский конфиг
{
    echo "client"
    echo "dev tun"
    echo "proto udp"
    echo "remote $SERVER_INFO"
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
    echo "key-direction 1"
    echo "<tls-auth>"
    cat "$TLS_KEY"
    echo "</tls-auth>"
    echo ""
    echo "auth-user-pass"
} > "$OUTPUT_FILE"

echo "Файл конфигурации сохранен как: $OUTPUT_FILE"