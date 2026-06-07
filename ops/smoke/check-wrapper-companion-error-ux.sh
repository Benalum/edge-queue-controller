#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
from pathlib import Path

path = Path("frontend/wrapper-ui/app.js")
text = path.read_text(errors="replace")

required = [
    "COMPANION_TRANSIENT_GATEWAY_WRAPPER_V1",
    "function isGatewayHtmlErrorText",
    "function cleanCompanionErrorMessage",
    "raw Cloudflare error page",
    "error code 502",
]

missing = [item for item in required if item not in text]

unsafe = [
    '"Error: " + err.message',
    "'Error: ' + err.message",
    "`Error: ${err.message}`",
    '"Error: " + String(err)',
    "'Error: ' + String(err)",
]

bad = [item for item in unsafe if item in text]

if missing or bad:
    if missing:
        print("ERROR: missing wrapper companion error UX markers:")
        for item in missing:
            print(f"  - {item}")
    if bad:
        print("ERROR: unsafe raw error rendering still present:")
        for item in bad:
            print(f"  - {item}")
    raise SystemExit(1)

print("PASS: wrapper companion error UX hides raw Cloudflare HTML")
PY
