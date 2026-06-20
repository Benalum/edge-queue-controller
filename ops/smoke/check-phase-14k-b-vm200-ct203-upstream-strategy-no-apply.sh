#!/usr/bin/env bash
set -euo pipefail
set +H

DOC="docs/phase-14k-b-vm200-ct203-upstream-strategy-no-apply.md"

echo "=== Phase 14K-B smoke ==="

test -f "$DOC"
echo "PASS: strategy doc exists"

python3 - "$DOC" <<'PY'
import sys

path = sys.argv[1]
text = open(path, "r", encoding="utf-8").read()

requirements = [
    "Recommended strategy",
    "Option A: static CT203 address in Proxmox/LXC config",
    "Public `/api/system/status` returned HTTP `404`",
    "CT203 Proxmox/LXC config still used DHCP",
    "VM200 nginx snippets proxy to literal private upstream addresses",
    "Phase 14K-C must not run without explicit approval",
    "Do not resume Decision Maker, Ollama/model worker, Companion, Study/Flashcards, or speaking/listening",
]

missing = []
for needle in requirements:
    if needle in text:
        print(f"PASS: found required text: {needle}")
    else:
        print(f"FAIL: missing required text: {needle}")
        missing.append(needle)

if missing:
    sys.exit(1)
PY

echo "PASS_PHASE_14K_B_SMOKE"
