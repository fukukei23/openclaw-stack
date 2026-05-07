
# OpenClaw Gateway Deployment @ fopenclaw.com

The fopenclaw.com environment hosts a production OpenClaw Gateway on a VPS (<YOUR_VPS_IP>) protected by Caddy for TLS, HTTP BasicAuth, and reverse proxying into a loopback-bound gateway (`127.0.0.1:18789`). Device pairing is complete, a gateway token `<REDACTED>` is loaded via secrets, and all agent traffic uses the `openai/gpt-5.1-codex` model. Health checks are green, but the setup assumes strict firewall enforcement (UFW allowing only 80/443 and throttled 22).

## Environment Summary
- **Domain:** `fopenclaw.com` → `<YOUR_VPS_IP>`
- **Containers:** `caddy` (edge) + `openclaw-gateway` (loopback-only)
- **Exposure:** WAN access over 80/443 via Caddy; gateway port hidden on localhost
- **Authentication:** TLS + BasicAuth + gateway token + paired devices
- **Model:** `openai/gpt-5.1-codex`

## Quick Start & Verification
```bash
cd /opt/openclaw
docker compose up -d                   # bring up caddy + gateway
curl -u deployer:<REDACTED> https://fopenclaw.com/status
# => {"health":"ok","model":"openai/gpt-5.1-codex"}
```
> **Security Note:** Never leak `<REDACTED>` secrets into git; store them under `/opt/openclaw/secrets/` with `chmod 600`.

7.  (sanitized operations docs archive)

7.  (sanitized operations docs archive)

7. \ (sanitized operations docs archive)

7. docs/ops/README.md (sanitized operations docs archive)
