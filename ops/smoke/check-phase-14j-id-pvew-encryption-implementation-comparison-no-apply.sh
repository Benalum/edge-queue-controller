#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-id-pvew-encryption-implementation-comparison-no-apply"
DOC="docs/${PHASE}.md"

echo "=== ${PHASE} smoke ==="
test -f "$DOC"

python3 - "$DOC" <<'PY'
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8")
required = [
    "Phase 14J-ID - PVEW encryption implementation comparison, no apply",
    "Base checkpoint: Phase 14J-IC, commit f469a0c.",
    "Option A - Dedicated LUKS-backed data volume",
    "Initial preference: recommended first path.",
    "Option B - Application-level encryption",
    "Option C - Encrypted backup artifacts only",
    "Option D - Host-wide encryption",
    "Preferred first design path:",
    "manual unlock after boot for the first version",
    "no keys in ChatGPT",
    "no user data inside website-edge",
    "Do not create CTs, create encrypted volumes, generate keys, migrate data, stop PVESO, or alter public routes.",
]
missing = [item for item in required if item not in text]
if missing:
    print("FAIL: missing required text")
    for item in missing:
        print("-", item)
    raise SystemExit(1)
print("PASS: phase-14j-id-pvew-encryption-implementation-comparison-no-apply doc smoke passed")
PY
