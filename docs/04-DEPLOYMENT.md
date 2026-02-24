
# Deployment Procedure

## 1. VPS Preparation
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y ufw fail2ban git curl
sudo adduser deployer && sudo usermod -aG sudo deployer
```
- Copy SSH keys into `/home/deployer/.ssh/authorized_keys` (chmod 600).
- Harden SSH (`/etc/ssh/sshd_config`): disable root login/password auth, then `sudo systemctl reload sshd`.

## 2. Docker & Compose
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker deployer
sudo apt install -y docker-compose-plugin
```
Create `/opt/openclaw/docker-compose.yml`:
```yaml
services:
  caddy:
    image: caddy:2
    ports: ["80:80", "443:443"]
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    depends_on: [gateway]
  gateway:
    image: openclaw/gateway:2026.2.18
    environment:
      - OPENCLAW_GATEWAY_TOKEN=<REDACTED>
      - OPENAI_API_KEY=<REDACTED>
    command: ["openclaw","gateway","start","--bind","127.0.0.1:18789"]
    expose: ["18789"]
volumes:
  caddy_data:
  caddy_config:
```

## 3. Caddy Configuration
`/opt/openclaw/Caddyfile`:
```caddyfile
fopenclaw.com {
    encode gzip
    basicauth {
        deployer <REDACTED>
    }
    reverse_proxy 127.0.0.1:18789
    log {
        output file /var/log/caddy/access.log
    }
}
```
Reload with `docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile`.

## 4. Initial Bring-up
```bash
cd /opt/openclaw
docker compose pull
docker compose up -d
docker compose logs -f gateway
```
Verify health:
```bash
curl -u deployer:<REDACTED> https://fopenclaw.com/status
```

## 5. Rollback Strategy
- Pin known-good tags in compose file.
- If upgrade fails:
  ```bash
  docker compose down
  docker pull openclaw/gateway:2026.2.18
  docker compose up -d
  ```
- Keep tarball backups (`docker save openclaw/gateway:2026.2.18 > gateway.tar`) for offline restore.

> **Security Note:** Keep `/opt/openclaw/.env` restricted (`chmod 600`) since it holds `<REDACTED>` secrets.
