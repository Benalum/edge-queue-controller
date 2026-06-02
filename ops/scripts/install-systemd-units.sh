#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/Desktop/edge-queue-controller}"

echo "[1/6] Verifying project directory: $PROJECT_DIR"
test -d "$PROJECT_DIR"
test -x "$PROJECT_DIR/.venv/bin/python"

echo "[2/6] Verifying Python syntax"
cd "$PROJECT_DIR"
"$PROJECT_DIR/.venv/bin/python" -m py_compile edge_controller.py

echo "[3/6] Installing systemd units"
sudo cp ops/systemd/edge-queue-controller.service /etc/systemd/system/
sudo cp ops/systemd/edge-queue-remediation-tick.service /etc/systemd/system/
sudo cp ops/systemd/edge-queue-remediation-tick.timer /etc/systemd/system/
sudo cp ops/systemd/edge-queue-power-idle-tick.service /etc/systemd/system/
sudo cp ops/systemd/edge-queue-power-idle-tick.timer /etc/systemd/system/

echo "[4/6] Installing controller drop-ins"
sudo mkdir -p /etc/systemd/system/edge-queue-controller.service.d

sudo cp ops/systemd/edge-queue-controller-power-idle-override.conf \
  /etc/systemd/system/edge-queue-controller.service.d/10-power-idle.conf

sudo cp ops/systemd/edge-queue-controller-proxmox-inventory-override.conf \
  /etc/systemd/system/edge-queue-controller.service.d/20-proxmox-inventory.conf

sudo cp ops/systemd/edge-queue-controller-power-stop-plan-override.conf \
  /etc/systemd/system/edge-queue-controller.service.d/30-power-stop-plan.conf

sudo cp ops/systemd/edge-queue-controller-power-execute-override.conf \
  /etc/systemd/system/edge-queue-controller.service.d/40-power-execute.conf

echo "[5/6] Reloading systemd and enabling services/timers"
sudo systemctl daemon-reload
sudo systemctl enable --now edge-queue-controller.service
sudo systemctl enable --now edge-queue-remediation-tick.timer
sudo systemctl enable --now edge-queue-power-idle-tick.timer

echo "[6/6] Status"
systemctl --no-pager status edge-queue-controller.service || true
systemctl list-timers --all | grep edge-queue || true

echo
echo "Done."
