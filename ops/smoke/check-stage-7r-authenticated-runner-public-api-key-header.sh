#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7R smoke: authenticated runner public API key header ==="

test -f ops/compare/run-authenticated-shadow-comparison.py
test -f docs/stage-7r-authenticated-runner-public-api-key-header.md

python3 - <<'PY'
from pathlib import Path

s = Path("ops/compare/run-authenticated-shadow-comparison.py").read_text()

required = [
    "EDGE_AUTH_SHADOW_COMPARE_PUBLIC_API_KEY",
    "EDGE_PUBLIC_API_KEY",
    'headers["x-edge-api-key"] = public_api_key',
    'headers["Authorization"] = f"Bearer {bearer}"',
    'headers = {"Content-Type": "application/json"}',
]

missing = [item for item in required if item not in s]
if missing:
    raise SystemExit("FAIL: missing required runner markers: " + ", ".join(missing))

if "print(public_api_key" in s or "print(headers" in s:
    raise SystemExit("FAIL: runner appears to print secret-bearing values")

print("OK: runner supports x-edge-api-key without printing secret-bearing headers")
PY

echo "OK: Stage 7R smoke passed"
