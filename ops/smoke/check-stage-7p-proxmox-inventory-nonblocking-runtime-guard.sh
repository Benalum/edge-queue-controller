#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7P smoke: Proxmox inventory nonblocking runtime guard ==="

test -f edge_controller.py
test -f docs/stage-7p-proxmox-inventory-nonblocking-runtime-guard.md

python3 - <<'PY'
from pathlib import Path

s = Path("edge_controller.py").read_text()

if "import asyncio" not in s:
    raise SystemExit("FAIL: asyncio import missing")

start_marker = '@app.post("/power/proxmox/inventory")'
start = s.find(start_marker)
if start < 0:
    raise SystemExit("FAIL: proxmox inventory route missing")

next_route = s.find("\n@app.", start + len(start_marker))
if next_route < 0:
    raise SystemExit("FAIL: could not find end of proxmox inventory route block")

block = s[start:next_route]

required = [
    "async def proxmox_inventory()",
    "result = await asyncio.to_thread(",
    "subprocess.run,",
    "timeout=",
    "Timed out while querying Proxmox inventory over SSH.",
]

missing = [item for item in required if item not in block]
if missing:
    raise SystemExit("FAIL: missing required markers in proxmox inventory block: " + ", ".join(missing))

if "result = subprocess.run(" in block:
    raise SystemExit("FAIL: direct blocking result = subprocess.run remains in proxmox inventory block")

print("OK: proxmox inventory SSH subprocess is offloaded from async event loop")
PY

echo "OK: Stage 7P smoke passed"
