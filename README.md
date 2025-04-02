```bash
docker run -d --cap-add=NET_ADMIN --name openvpn \
    -v $(pwd)/server.conf:/etc/openvpn/server/server.conf \
    -v $(pwd)/easy-rsa:/etc/openvpn/easy-rsa \
    -p 1194:1194/udp \
    my-openvpn
```