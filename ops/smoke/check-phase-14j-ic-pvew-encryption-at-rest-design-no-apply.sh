#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ic-pvew-encryption-at-rest-design-no-apply"
DOC="docs/${PHASE}.md"

echo "=== ${PHASE} smoke ==="
test -f "$DOC"

python3 - "$DOC" <<'PY'
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8")
required = [
    "Phase 14J-IC - PVEW encryption-at-rest design, no apply",
    "Base checkpoint: Phase 14J-IB, commit 572ca52.",
    "real user/platform data must not move there until encryption-at-rest is selected",
    "PVESO remains the on-demand model, worker, GPU, and heavy-compute host.",
    "website-edge must not contain user DB files",
    "If website-edge is exploited",
    "No key in ChatGPT",
    "Manual unlock after boot is the safer first design",
    "Backups containing user/platform data must be encrypted.",
    "Do not create CTs, create encrypted volumes, generate keys, migrate data, stop PVESO, or alter public routes.",
]
missing = [item for item in required if item not in text]
if missing:
    print("FAIL: missing required text")
    for item in missing:
        print("-", item)
    raise SystemExit(1)
print("PASS: phase-14j-ic-pvew-encryption-at-rest-design-no-apply doc smoke passed")
PY
