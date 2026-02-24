
# Security Controls

## BasicAuth (Caddy)
- Hash passwords with `caddy hash-password --plaintext 'StrongPass!'`.
- Sample snippet (hash truncated, secrets `<REDACTED>`):
  ```caddyfile
  fopenclaw.com {
      basicauth {
          deployer <REDACTED>
      }
      reverse_proxy 127.0.0.1:18789
  }
  ```
- Rotate quarterly; store plaintext only in a password vault.

## UFW Enforcement
```bash
sudo ufw default deny incoming
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw limit 22/tcp
sudo ufw deny 18789/tcp
sudo ufw enable
```
- Confirm status after every change; document rule numbers for quick removal.

## Trusted Proxies
- Configure gateway to trust only loopback/networks hosting Caddy:
  ```yaml
  trustedProxies:
    - 127.0.0.1
    - 172.18.0.0/16  # docker bridge (adjust if different)
  ```
- Never set `0.0.0.0/0`; that would allow spoofed `X-Forwarded-*`.

## Token & Pairing Authentication
- Gateway token `<REDACTED>` stored via env/secret file; rotate with `openclaw gateway token rotate`.
- Device pairing already complete; audit regularly:
  ```bash
  docker compose exec gateway openclaw devices list
  docker compose exec gateway openclaw devices revoke <device-id>
  ```

## Risks & Recommendations
- **Credential leakage:** sanitize logs before sharing (`sed 's/<REDACTED>/…/g'`).
- **Config drift:** pin Docker image tags (e.g., `openclaw/gateway:2026.2.18`) and review before upgrades.
- **Brute-force attempts:** enable fail2ban on SSH and Caddy logs for repeated BasicAuth failures.

> **Security Warning:** Any accidental bind to `0.0.0.0:18789` exposes the control plane—monitor with `sudo ss -ltnp | grep 18789`.
