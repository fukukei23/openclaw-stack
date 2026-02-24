
# Deployment & Operations Checklist

| Item | Pass ☐ / Fail ☐ | Verification Steps |
| --- | --- | --- |
| DNS points to `162.43.17.111` | ☐ | `dig +short fopenclaw.com` |
| TLS + BasicAuth enforced | ☐ | `curl -I https://fopenclaw.com -u deployer:<REDACTED>` → `200 OK` |
| Gateway bound to loopback only | ☐ | `sudo ss -ltnp | grep 18789` (shows `127.0.0.1`); `sudo nmap -p 18789 162.43.17.111` (filtered) |
| UFW rules match policy | ☐ | `sudo ufw status numbered` (allow 80/443, limit 22, deny 18789) |
| Device pairing reviewed | ☐ | `docker compose exec gateway openclaw devices list` (no unknown devices) |
| Gateway health OK | ☐ | `curl -u deployer:<REDACTED> https://fopenclaw.com/status` |
| Logs accessible & sanitized | ☐ | `sudo tail -f /var/log/caddy/access.log`; `docker compose logs gateway` with `<REDACTED>` scrubbed |
| Rollback plan validated | ☐ | Confirm compose pin + local image/tarball (`docker images openclaw/gateway`) |

> **Reminder:** Do not mark “Pass” until each command has been executed and evidence captured.
