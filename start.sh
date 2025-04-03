#!/bin/bash
set -e

TA_KEY="/etc/openvpn/easy-rsa/ta.key"
PKI_DIR="/etc/openvpn/easy-rsa/pki"
EASYRSA_DIR="/etc/openvpn/easy-rsa"
EASYRSA_CMD="/usr/share/easy-rsa/easyrsa"
CLIENT_NAME="client1"  # Имя клиента по умолчанию

# Переходим в каталог easy-rsa перед выполнением команд
mkdir -p "$EASYRSA_DIR"
cd "$EASYRSA_DIR"

# Функция для проверки и создания клиентского сертификата
create_client_cert() {
    local client_name=$1
    
    if [ ! -f "$PKI_DIR/issued/$client_name.crt" ] || [ ! -f "$PKI_DIR/private/$client_name.key" ]; then
        echo "Создание клиентского сертификата для $client_name..."
        
        # Генерация запроса
        export EASYRSA_REQ_CN="$client_name"
        "$EASYRSA_CMD" --batch gen-req "$client_name" nopass || { 
            echo "Ошибка: gen-req $client_name не удался"; 
            unset EASYRSA_REQ_CN;
            exit 1; 
        }
        unset EASYRSA_REQ_CN
        
        # Подписание сертификата
        echo "yes" | "$EASYRSA_CMD" --batch sign-req client "$client_name" || {
            echo "Ошибка: sign-req client $client_name не удался";
            exit 1;
        }
        
        echo "Клиентский сертификат для $client_name успешно создан."
    else
        echo "Клиентский сертификат для $client_name уже существует."
    fi
}

if [ ! -f "$TA_KEY" ] || [ ! -d "$PKI_DIR" ]; then
    echo "Генерация ключей и сертификатов..."

    # Генерация ta.key
    if [ ! -f "$TA_KEY" ]; then
        echo "Создание $TA_KEY..."
        mkdir -p "$(dirname "$TA_KEY")"
        openvpn --genkey secret "$TA_KEY" || { echo "Ошибка: Не удалось создать $TA_KEY"; exit 1; }
    fi

    # Генерация PKI и сертификатов
    if [ ! -d "$PKI_DIR" ]; then
        echo "Инициализация PKI..."
        "$EASYRSA_CMD" init-pki || { echo "Ошибка: init-pki не удался"; exit 1; }

        echo "Создание CA..."
        "$EASYRSA_CMD" --batch build-ca nopass || { echo "Ошибка: build-ca не удался"; exit 1; }

        echo "Создание запроса сертификата сервера..."
        export EASYRSA_REQ_CN="server"
        "$EASYRSA_CMD" --batch gen-req server nopass || { 
            echo "Ошибка: gen-req server не удался"; 
            unset EASYRSA_REQ_CN;
            exit 1; 
        }
        unset EASYRSA_REQ_CN

        echo "Подписание запроса сервера..."
        echo "yes" | "$EASYRSA_CMD" --batch sign-req server server || { echo "Ошибка: sign-req server не удался"; exit 1; }

        echo "Генерация параметров DH..."
        "$EASYRSA_CMD" gen-dh || { echo "Ошибка: gen-dh не удался"; exit 1; }

        # Создаем клиентский сертификат
        create_client_cert "$CLIENT_NAME"

        echo "Генерация ключей и сертификатов завершена."
    fi
else
    echo "Ключи и PKI уже существуют, пропускаем генерацию."
    # Проверяем наличие клиентского сертификата
    create_client_cert "$CLIENT_NAME"
fi

# Настройка iptables
echo "Настройка IPTables..."
if ! iptables -t nat -C POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE > /dev/null 2>&1; then
    iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE || echo "Предупреждение: Не удалось добавить правило IPTables (возможно, нужны права)."
else
    echo "Правило IPTables уже существует."
fi

echo "Запуск OpenVPN..."
openvpn --config /etc/openvpn/server/server.conf
