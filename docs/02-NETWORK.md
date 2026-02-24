
# Network Topology

## Address & Port Matrix
| Component | IP/Interface | Port | Exposure | Notes |
| --- | --- | --- | --- | --- |
| Caddy HTTP | `0.0.0.0` | 80/tcp | Public | Redirects to HTTPS |
| Caddy HTTPS | `0.0.0.0` | 443/tcp | Public | TLS termination + BasicAuth |
| SSH (rate-limited) | `0.0.0.0` | 22/tcp | Restricted | Allow only trusted IPs via UFW `limit` |
| OpenClaw Gateway | `127.0.0.1` | 18789/tcp | Internal only | Accessed by Caddy; UFW denies WAN |

## Traffic Paths
- **Public Route:** Internet → Caddy (80/443) → Gateway loopback.
- **SSH Tunnel (admin-use):**
  ```bash
  ssh -L 18789:127.0.0.1:18789 ubuntu@162.43.17.111
  curl -u deployer:<REDACTED> https://localhost:18789/status
  ```
  Use when testing without exposing additional ports; still requires BasicAuth headers.

## Verification Commands
```bash
# Confirm DNS
dig +short fopenclaw.com

# Ensure gateway hidden externally
sudo nmap -p 18789 162.43.17.111     # should be filtered/closed
sudo nmap -p 18789 127.0.0.1         # should be open

# UFW state
sudo ufw status numbered
```

> **Security Note:** After editing firewall rules, reload (`sudo ufw reload`) and re-run the verification commands to catch accidental 0.0.0.0 exposure.
