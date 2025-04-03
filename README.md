# OpenVPN Server with LDAP Authentication
```bash
docker compose up -d --build
```

## Create client config
```bash
chmod +x ./generate_config.sh
sudo ./generate_config.sh <server_addr> <server_port>
```
