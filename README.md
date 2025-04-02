```bash
docker run -d --cap-add=NET_ADMIN --name openvpn \
    -v $(pwd)/server.conf:/etc/openvpn/server/server.conf \
    -v $(pwd)/easy-rsa:/etc/openvpn/easy-rsa \
    -p 2402:2402/udp \
    my-openvpn
```