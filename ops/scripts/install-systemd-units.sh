#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/Desktop/edge-queue-controller}"

echo "[1/5] Verifying project directory: $PROJECT_DIR"
test -d "$PROJECT_DIR"
test -x "$PROJECT_DIR/.venv/bin/python"

echo "[2/5] Verifying Python syntax"
cd "$PROJECT_DIR"
"$PROJECT_DIR/.venv/bin/python" -m py_compile edge_controller.py

echo "[3/5] Installing systemd units"
sudo cp ops/systemd/edge-queue-controller.service /etc/systemd/system/
sudo cp ops/systemd/edge-queue-remediation-tick.service /etc/systemd/system/
sudo cp ops/systemd/edge-queue-remediation-tick.timer /etc/systemd/system/

echo "[4/5] Reloading systemd and enabling services"
sudo systemctl daemon-reload
sudo systemctl enable --now edge-queue-controller.service
sudo systemctl enable --now edge-queue-remediation-tick.timer

echo "[5/5] Status"
systemctl --no-pager status edge-queue-controller.service || true
systemctl list-timers --all | grep edge-queue || true

echo
echo "Done."
