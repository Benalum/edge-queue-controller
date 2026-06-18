#!/usr/bin/env bash
set -euo pipefail

python3 -m py_compile edge_controller.py

python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "def _system_private_storage_status",
    '"mount_state": "unknown"',
    '"policy": "manual-unlock-only"',
    '"mountpoint": "/srv/apc-private-data"',
    '"data_authority": False',
    '"private_storage_status": private_storage_status',
]

for needle in required:
    if needle not in text:
        raise SystemExit(f"missing required source marker: {needle}")

helper_start = text.index("def _system_private_storage_status")
helper_end = text.index("_SYSTEM_STATUS_CACHE_TTL_SECONDS_DEFAULT", helper_start)
helper = text[helper_start:helper_end]

for forbidden in ["findmnt", "cryptsetup", "subprocess", "pct ", "ssh "]:
    if forbidden in helper:
        raise SystemExit(f"forbidden live probe marker in helper: {forbidden}")

print("PASS check-phase-14j-kx-static-private-storage-status-api-contract")
PY
