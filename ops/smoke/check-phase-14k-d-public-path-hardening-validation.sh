#!/usr/bin/env bash
set -euo pipefail
set +H

DOC="docs/phase-14k-d-public-path-hardening-validation.md"

echo "=== Phase 14K-D smoke ==="

test -f "$DOC"
echo "PASS: validation doc exists"

python3 - "$DOC" <<'PY'
import sys
path=sys.argv[1]
text=open(path, "r", encoding="utf-8").read()
requirements=[
    "CT203 is no longer DHCP in Proxmox/LXC config",
    "VM200 local wrapper route `/api/system/status` is healthy on `127.0.0.1:18080`",
    "Public `/api/system/status` is now healthy",
    "CT204 remained stopped",
    "Private storage remained locked/unmounted",
    "No CT203 restart was performed",
    "Phase 14K public-path hardening is validated",
]
missing=[]
for item in requirements:
    if item in text:
        print(f"PASS: found required text: {item}")
    else:
        print(f"FAIL: missing required text: {item}")
        missing.append(item)
if missing:
    sys.exit(1)
PY

echo "PASS_PHASE_14K_D_SMOKE"
