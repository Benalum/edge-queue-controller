#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ib-pvew-always-on-pveso-on-demand-architecture-decision-no-apply"
DOC="docs/${PHASE}.md"

echo "=== ${PHASE} smoke ==="

python3 - "$DOC" <<'PY'
from pathlib import Path
import re
import sys

doc_path = Path(sys.argv[1])
if not doc_path.is_file():
    raise SystemExit(f"FAIL: missing doc {doc_path}")

text = doc_path.read_text(encoding="utf-8")

required = [
    "Phase 14J-IB - PVEW always-on and PVESO on-demand architecture decision, no apply",
    "docs/smoke only",
    "This phase does not approve any real migration or power mutation.",
    "Commit: `0ff0b32`",
    "PVESO is currently a good candidate for an on-demand model/worker/compute host",
    "PVEW is suitable for always-on lightweight platform edge/control/data candidates",
    "Always on: PVEW",
    "On demand: PVESO",
    "website-edge must not contain user DB files",
    "website-edge must not contain controller secrets",
    "User/platform data must be encrypted at rest before a real migration",
    "This phase does not choose the exact encryption implementation.",
    "Current live authority remains:",
    "Do not migrate user data, stop PVESO, create CTs, copy DB files, or alter public routes",
]

missing = [s for s in required if s not in text]
if missing:
    print("FAIL: missing required doc text:")
    for item in missing:
        print(f"- {item}")
    raise SystemExit(1)

for pattern in [
    r"100\.\d{1,3}\.\d{1,3}\.\d{1,3}",
    r"10\.\d{1,3}\.\d{1,3}\.\d{1,3}",
    r"192\.168\.\d{1,3}\.\d{1,3}",
    r"token=",
    r"secret=",
    r"password=",
    r"api[_-]?key=",
    r"Authorization:",
]:
    if re.search(pattern, text, re.IGNORECASE):
        raise SystemExit(f"FAIL: doc appears to contain raw network address or secret-like material: {pattern}")

print("PASS: phase-14j-ib-pvew-always-on-pveso-on-demand-architecture-decision-no-apply doc smoke passed")
PY
