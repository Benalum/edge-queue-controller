#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
from pathlib import Path

path = Path("frontend/study-ui/app.js")
text = path.read_text(errors="replace")

required = [
    "COMPANION_TRANSIENT_GATEWAY_V1",
    "function isCloudflareHtml",
    "function transientGatewayError",
    "err.transient = true",
    "data?.job_id",
    "function getPollUrl",
    "pollJob(jobId, pollUrl)",
    "I did not save the raw Cloudflare error page",
    "The companion is still thinking",
]

missing = [item for item in required if item not in text]

forbidden = [
    '" + err.message',
    "data?.id || data?.job?.id || data?.result?.id || null",
]

bad = [item for item in forbidden if item in text]

if missing or bad:
    if missing:
        print("ERROR: missing companion pending UX markers:")
        for item in missing:
            print(f"  - {item}")
    if bad:
        print("ERROR: old unsafe companion error handling still present:")
        for item in bad:
            print(f"  - {item}")
    raise SystemExit(1)

print("PASS: companion pending/gateway UX avoids raw Cloudflare HTML and polls queued jobs")
PY
