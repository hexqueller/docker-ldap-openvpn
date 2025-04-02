#!/bin/bash
set -e # Оставляем set -e, но добавим явные проверки

echo "Включение IP Forwarding..."
sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1 || echo "Предупреждение: Не удалось включить IP Forwarding (возможно, нужны права или уже включено)."

TA_KEY="/etc/openvpn/easy-rsa/ta.key"
PKI_DIR="/etc/openvpn/easy-rsa/pki"
EASYRSA_DIR="/etc/openvpn/easy-rsa" # Указываем базовый каталог
EASYRSA_CMD="/usr/share/easy-rsa/easyrsa"

# Переходим в каталог easy-rsa перед выполнением команд
mkdir -p "$EASYRSA_DIR"
cd "$EASYRSA_DIR"

if [ ! -f "$TA_KEY" ] || [ ! -d "$PKI_DIR" ]; then
    echo "Генерация ключей и сертификатов..."

    # Генерация ta.key (исправленный синтаксис)
    if [ ! -f "$TA_KEY" ]; then
        echo "Создание $TA_KEY..."
        # Убедимся, что каталог существует
        mkdir -p "$(dirname "$TA_KEY")"
        # Используем новый синтаксис
        openvpn --genkey secret "$TA_KEY" || { echo "Ошибка: Не удалось создать $TA_KEY"; exit 1; }
    fi

    # Генерация PKI и сертификатов
    if [ ! -d "$PKI_DIR" ]; then
        echo "Инициализация PKI..."
        "$EASYRSA_CMD" init-pki || { echo "Ошибка: init-pki не удался"; exit 1; }

        echo "Создание CA..."
        # Используем --batch для полной автоматизации и nopass
        # Установим CN для CA через переменную или можно оставить дефолтное
        # export EASYRSA_REQ_CN="My VPN CA"
        "$EASYRSA_CMD" --batch build-ca nopass || { echo "Ошибка: build-ca не удался"; exit 1; }

        echo "Создание запроса сертификата сервера..."
        # Устанавливаем Common Name для серверного сертификата неинтерактивно
        export EASYRSA_REQ_CN="server"
        "$EASYRSA_CMD" --batch gen-req server nopass || { echo "Ошибка: gen-req server не удался"; exit 1; }
        # Убираем переменную, если она больше не нужна
        unset EASYRSA_REQ_CN

        echo "Подписание запроса сервера..."
        # Автоматическое подтверждение с 'yes'
        echo "yes" | "$EASYRSA_CMD" --batch sign-req server server || { echo "Ошибка: sign-req server не удался"; exit 1; }

        echo "Генерация параметров DH..."
        "$EASYRSA_CMD" gen-dh || { echo "Ошибка: gen-dh не удался"; exit 1; }

        echo "Генерация ключей и сертификатов завершена."
    fi
else
    echo "Ключи и PKI уже существуют, пропускаем генерацию."
fi

# Убедимся, что каталог для server.conf существует
mkdir -p /etc/openvpn/server

# Проверка существования файла конфигурации перед запуском
if [ ! -f "/etc/openvpn/server/server.conf" ]; then
    echo "Ошибка: Файл конфигурации /etc/openvpn/server/server.conf не найден!"
    # Возможно, здесь нужно создать базовый конфиг или скопировать его
    exit 1
fi

# Настройка iptables (проверяем, не существует ли правило уже)
echo "Настройка IPTables..."
if ! iptables -t nat -C POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE > /dev/null 2>&1; then
    iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE || echo "Предупреждение: Не удалось добавить правило IPTables (возможно, нужны права)."
else
    echo "Правило IPTables уже существует."
fi

echo "Запуск OpenVPN..."
# Запускаем openvpn в foreground, чтобы скрипт (и контейнер) не завершался сразу
openvpn --config /etc/openvpn/server/server.conf
