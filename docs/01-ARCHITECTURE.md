
# Architecture

```
            Internet Clients / Devices
                       |
                TLS + BasicAuth
                       |
                +--------------+
                |    Caddy     |
                +--------------+
                       |
            Loopback 127.0.0.1:18789
                       |
                +----------------+
                | OpenClaw Gate- |
                | way Container  |
                +----------------+
                       |
            Provider HTTPS Requests
                       |
                +----------------+
                | openai/gpt-5.1 |
                |   -codex API   |
                +----------------+
```

## Responsibility Boundaries
- **Caddy (Edge Layer):** Terminates TLS, enforces BasicAuth, logs access, and proxies only authenticated traffic to the gateway via loopback.
- **OpenClaw Gateway (Control Plane):** Runs agents, stores pairing state, enforces gateway token checks, and exposes management endpoints bound to `127.0.0.1:18789`.
- **Agents:** Execute workflows triggered through the gateway; inherit the gateway’s IAM policies and secrets context.
- **LLM Provider (`openai/gpt-5.1-codex`):** Receives inference calls from agents via outbound HTTPS; API key `<REDACTED>` resides only in gateway secrets.

## Data Flow
1. Client → `https://fopenclaw.com` (TLS handshake + BasicAuth).
2. Caddy proxies request to `http://127.0.0.1:18789`.
3. Gateway authenticates via token/pairing, routes to agents.
4. Agents call OpenAI API; responses flow back through gateway and Caddy to the client.

> **Security Reminder:** The gateway must never bind to `0.0.0.0`; Caddy is the sole ingress point.
