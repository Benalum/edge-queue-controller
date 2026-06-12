#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7T smoke: Proxmox inventory Tailscale SSH check root cause ==="

test -f docs/stage-7t-proxmox-inventory-tailscale-ssh-check-root-cause.md

python3 - <<'PY'
from pathlib import Path

doc = Path("docs/stage-7t-proxmox-inventory-tailscale-ssh-check-root-cause.md").read_text()

required = [
    "Stage 7T Proxmox Inventory Tailscale SSH Check Root Cause",
    "This stage does not change runtime behavior.",
    "This stage does not resume power automation.",
    "EDGE_POWER_AUTO_PAUSED=1",
    "Tailscale SSH required an additional interactive authentication check",
    "Stage 7P fixed the web/controller blocking problem.",
    "Do not resume production power automation",
    "non-interactive SSH method",
    "dedicated restricted automation identity",
]

missing = [item for item in required if item not in doc]
if missing:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing))

for forbidden in [
    "https://login.tailscale.com/",
    "postgresql://",
    "EDGE_PUBLIC_API_KEY=",
    "edgeStudyToken=",
    "Authorization: Bearer ",
]:
    if forbidden in doc:
        raise SystemExit(f"FAIL: doc contains forbidden secret/sensitive marker: {forbidden}")

print("OK: Stage 7T root cause checkpoint is documented safely")
PY

echo "OK: Stage 7T smoke passed"
