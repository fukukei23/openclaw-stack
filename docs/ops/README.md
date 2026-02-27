# Sanitized operational snapshot

This directory contains sanitized operational artifacts extracted from the OpenClaw installation.

Files:
- openclaw_config.sanitized.json : host config summary (API keys/tokens masked)
- openclaw_runtime.sanitized.json : runtime config from container (masked)
- paired.sanitized.json / pending.sanitized.json : device pairing artifacts (tokens removed)
- gateway.log.sanitized.txt : recent gateway logs with IPs/tokens masked
- env.sanitized.txt : presence/length summary for .env variables

Sanitization rules:
- API keys, tokens, JWTs, setup codes are replaced with "<REDACTED...>" placeholders and lengths retained.
- Public client IPs are replaced with "<REDACTED_IP>"; internal/private IPs (10/172.16-31/192.168/127) are kept.
- QR/setup codes, and any credentials are suppressed.

