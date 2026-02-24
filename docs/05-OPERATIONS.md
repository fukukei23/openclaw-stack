
# Operations Guide

## Health Checks
```bash
curl -u deployer:<REDACTED> https://fopenclaw.com/status
docker compose exec gateway openclaw status
```
Automate via cron or monitoring.

## Logs
- **Caddy:** `/var/log/caddy/access.log`
  ```bash
  sudo tail -f /var/log/caddy/access.log
  ```
- **Gateway:** `docker compose logs -f gateway`
- Redact secrets before sharing:
  ```bash
  docker compose logs gateway | sed 's/<REDACTED>/REDACTED/g'
  ```

## Device Workflow
```bash
docker compose exec gateway openclaw devices pending
docker compose exec gateway openclaw devices approve <id>
docker compose exec gateway openclaw devices revoke <id>
```
Review monthly; revoke stale entries.

## Token Lifecycle
```bash
docker compose exec gateway openclaw gateway token rotate
docker compose exec gateway openclaw gateway token list
```
Update secrets store immediately after rotation and restart gateway (`docker compose restart gateway`).

## Incident Triage
1. **Gateway unreachable:** check `docker compose ps`, ensure port 443 open, inspect UFW.
2. **Auth failures:** inspect Caddy logs; consider enabling fail2ban jail on `/var/log/caddy/access.log`.
3. **LLM errors:** tail gateway logs for OpenAI errors; verify `OPENAI_API_KEY=<REDACTED>` set.

## Docker Compose Rollback (Operational)
```bash
docker compose pull gateway
docker compose up -d gateway
# if regression, revert:
git checkout HEAD~1 docker-compose.yml
docker compose up -d gateway
```
> **Security Reminder:** During outages, avoid disabling BasicAuth “temporarily”; fix the root cause instead.
