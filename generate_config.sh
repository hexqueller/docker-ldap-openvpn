#!/bin/bash

# Проверка аргументов
if [ "$#" -ne 2 ]; then
    echo "Использование: $0 <ИмяКлиента> <Сервер:Порт>" >&2
    echo "Пример: $0 client1 vpn.example.com:2402" >&2
    exit 1
fi

CLIENT_NAME="$1"
SERVER_INFO="$2"
OUTPUT_FILE="${CLIENT_NAME}.ovpn"

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