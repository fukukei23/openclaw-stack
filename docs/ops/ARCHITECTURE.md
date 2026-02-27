# Operations Architecture Summary

## Runtime Topology

- Public entrypoint: Caddy (`80/443`)
- Internal gateway: `openclaw-gateway` bound to localhost
- Upstream model provider: OpenAI API through gateway
- Control layers: TLS, BasicAuth, gateway token, device pairing

## Security Baseline

- Expose only `80` and `443` publicly.
- Block direct public access to gateway port.
- Keep environment variables and device keys out of version control.

## Operational Notes

- Perform health checks after deploy and after credential rotation.
- Keep runbooks and sanitized snapshots in this `docs/ops` tree.
