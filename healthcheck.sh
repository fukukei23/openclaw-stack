#!/usr/bin/env bash
set -euo pipefail

cd /home/op/openclaw-stack

echo "== TIME =="
date

echo
echo "== DISK =="
df -h /

echo
echo "== DOCKER COMPOSE PS =="
sudo docker compose ps

echo
echo "== CADDYFILE (host) =="
nl -ba ./caddy/Caddyfile | sed -n '1,120p'

echo
echo "== CADDY VALIDATE (container) =="
sudo docker compose exec caddy sh -lc 'caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile'

echo
echo "== GATEWAY LOGS (tail 60) =="
sudo docker compose logs --tail=60 openclaw-gateway

echo
echo "== CADDY LOGS (tail 60) =="
sudo docker compose logs --tail=60 caddy

echo
echo "== ACCESS LOG (tail 20) =="
tail -n 20 ./caddy/logs/access.log || sudo tail -n 20 ./caddy/logs/access.log

echo
echo "== DONE =="
