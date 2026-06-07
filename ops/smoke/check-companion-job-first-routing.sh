#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
from pathlib import Path

path = Path("frontend/study-ui/app.js")
text = path.read_text(errors="replace")

required = [
    "COMPANION_JOB_FIRST_V1",
    "url: `${base}/jobs`",
    "url: `${base}/companion/chat`",
    "pollJob(jobId, pollUrl)",
    'job_type: "ollama_chat"',
]

missing = [item for item in required if item not in text]
if missing:
    print("FAIL: missing companion job-first routing markers:")
    for item in missing:
        print(f"  - {item}")
    raise SystemExit(1)

marker_idx = text.find("COMPANION_JOB_FIRST_V1")
jobs_idx = text.find("url: `${base}/jobs`", marker_idx)
chat_idx = text.find("url: `${base}/companion/chat`", marker_idx)

if marker_idx < 0 or jobs_idx < 0 or chat_idx < 0:
    print("FAIL: could not locate companion route order markers")
    raise SystemExit(1)

if not jobs_idx < chat_idx:
    print("FAIL: companion direct chat route appears before queued jobs route")
    raise SystemExit(1)

print("PASS: companion chat prefers queued jobs before direct route")
PY
