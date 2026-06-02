#!/usr/bin/env bash
set -euo pipefail

PROXMOX_HOST="${PROXMOX_HOST:-root@100.88.194.19}"
CT_ID="${CT_ID:-101}"

echo "[1/4] Copying service into CT ${CT_ID} on ${PROXMOX_HOST}"
ssh "$PROXMOX_HOST" "cat > /tmp/ct101-llm-stack-compose.service" \
  < ops/systemd/ct101-llm-stack-compose.service

echo "[2/4] Installing service inside CT"
ssh "$PROXMOX_HOST" "pct push ${CT_ID} /tmp/ct101-llm-stack-compose.service /etc/systemd/system/llm-stack-compose.service"

echo "[3/4] Enabling and starting service"
ssh "$PROXMOX_HOST" "pct exec ${CT_ID} -- bash -lc '
systemctl daemon-reload
systemctl enable llm-stack-compose.service
systemctl start llm-stack-compose.service
'"

echo "[4/4] Status"
ssh "$PROXMOX_HOST" "pct exec ${CT_ID} -- bash -lc '
systemctl status llm-stack-compose.service --no-pager || true
cd /opt/llm-stack
docker compose ps
'"

echo
echo "Done."
