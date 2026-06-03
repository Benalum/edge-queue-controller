#!/usr/bin/env bash
set -euo pipefail

TUNNEL_NAME="edge-queue-controller"
HOSTNAME="edge-api.alexhartel.com"
LOCAL_SERVICE="http://127.0.0.1:7070"
CLOUDFLARED_DIR="$HOME/.cloudflared"
SYSTEM_DIR="/etc/cloudflared"

echo "=== stopping cloudflared service if running ==="
sudo systemctl stop cloudflared || true
sudo systemctl disable cloudflared || true
sudo systemctl reset-failed cloudflared || true

echo
echo "=== existing tunnels ==="
cloudflared tunnel list || true

echo
echo "=== deleting existing $TUNNEL_NAME tunnel if present ==="
if cloudflared tunnel list | awk '{print $2}' | grep -qx "$TUNNEL_NAME"; then
  cloudflared tunnel delete --force "$TUNNEL_NAME" || true
fi

echo
echo "=== creating new tunnel: $TUNNEL_NAME ==="
cloudflared tunnel create "$TUNNEL_NAME"

UUID="$(cloudflared tunnel list | awk -v name="$TUNNEL_NAME" '$2==name{print $1; exit}')"

if [ -z "$UUID" ]; then
  echo "ERROR: could not find UUID for $TUNNEL_NAME"
  exit 1
fi

CREDS="$CLOUDFLARED_DIR/$UUID.json"

if [ ! -f "$CREDS" ]; then
  echo "ERROR: credentials file missing: $CREDS"
  ls -la "$CLOUDFLARED_DIR"
  exit 1
fi

echo
echo "=== writing user config ==="
mkdir -p "$CLOUDFLARED_DIR"

cat > "$CLOUDFLARED_DIR/config.yml" <<CONFIG
tunnel: $UUID
credentials-file: $CREDS

ingress:
  - hostname: $HOSTNAME
    service: $LOCAL_SERVICE
  - service: http_status:404
CONFIG

chmod 600 "$CLOUDFLARED_DIR/config.yml"

echo
echo "=== routing DNS ==="
cloudflared tunnel route dns "$TUNNEL_NAME" "$HOSTNAME"

echo
echo "=== installing system service config ==="
sudo mkdir -p "$SYSTEM_DIR"
sudo cp "$CLOUDFLARED_DIR/config.yml" "$SYSTEM_DIR/config.yml"
sudo cp "$CREDS" "$SYSTEM_DIR/$UUID.json"
sudo chmod 600 "$SYSTEM_DIR/config.yml" "$SYSTEM_DIR/$UUID.json"

sudo cloudflared service uninstall || true
sudo cloudflared service install

sudo systemctl enable --now cloudflared

echo
echo "=== cloudflared service status ==="
systemctl status cloudflared --no-pager || true

echo
echo "=== done ==="
echo "Tunnel name: $TUNNEL_NAME"
echo "Hostname: $HOSTNAME"
echo "Local service: $LOCAL_SERVICE"
echo "UUID: $UUID"
echo
echo "Do not paste the credentials JSON or tunnel token anywhere."
