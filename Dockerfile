FROM alpine:3.20

RUN apk add --no-cache openvpn easy-rsa iptables bash openvpn-auth-ldap && \
    mkdir -p /etc/openvpn/server && \
    mkdir -p /etc/openvpn/easy-rsa

COPY start.sh /start.sh
RUN chmod +x /start.sh

VOLUME ["/etc/openvpn"]

CMD ["/start.sh"]
