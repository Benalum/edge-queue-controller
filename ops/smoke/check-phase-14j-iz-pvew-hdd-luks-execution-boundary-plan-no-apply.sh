#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-iz-pvew-hdd-luks-execution-boundary-plan-no-apply.md"

echo "=== smoke: Phase 14J-IZ PVEW HDD LUKS execution boundary plan, no apply ==="

test -f "$DOC"

grep -F "MUTATION_SCOPE: docs_smoke_only_no_apply" "$DOC"
grep -F "/dev/disk/by-id/ata-Hitachi_HDS721010CLA332_JP2940J81AMYSD" "$DOC"
grep -F "Hitachi HDS721010CLA332" "$DOC"
grep -F "JP2940J81AMYSD" "$DOC"
grep -F "APPROVE_PHASE_14J_JA_PVEW_HDD_WIPE_LUKS_CREATE_MANUAL_UNLOCK_ONLY" "$DOC"
grep -F "No encryption passphrase" "$DOC"
grep -F "VM200 remains public/static only" "$DOC"
grep -F "CT203 edge-controller-pvew is stopped and non-authoritative" "$DOC"
grep -F "CT204 edge-data-pvew is stopped and non-authoritative" "$DOC"
grep -F "laptop DB authority remains unchanged" "$DOC"
grep -F "no secrets appeared in logs" "$DOC"

python3 - "$DOC" <<'PY'
import re
import sys

doc = sys.argv[1]
bad = []
patterns = [
    re.compile(r'(^|[`$#;&|])\s*mkfs(\.|\s)'),
    re.compile(r'(^|[`$#;&|])\s*cryptsetup\s+'),
    re.compile(r'(^|[`$#;&|])\s*wipefs\s+'),
    re.compile(r'(^|[`$#;&|])\s*sgdisk\s+'),
    re.compile(r'(^|[`$#;&|])\s*parted\s+'),
    re.compile(r'(^|[`$#;&|])\s*pvcreate\s+'),
    re.compile(r'(^|[`$#;&|])\s*vgcreate\s+'),
    re.compile(r'(^|[`$#;&|])\s*lvcreate\s+'),
    re.compile(r'(^|[`$#;&|])\s*pvesm\s+(add|set)\b'),
    re.compile(r'(^|[`$#;&|])\s*mount\s+(-|/dev|/mnt|/srv|/opt)\b'),
]
with open(doc, "r", encoding="utf-8") as f:
    for lineno, line in enumerate(f, 1):
        for pat in patterns:
            if pat.search(line):
                bad.append((lineno, line.rstrip()))
                break

if bad:
    print("FAIL: no-apply doc contains live command-like storage mutation text")
    for lineno, line in bad:
        print(f"{lineno}: {line}")
    raise SystemExit(1)

print("PASS: no live storage mutation command text detected")
PY

echo "PASS: Phase 14J-IZ no-apply execution boundary doc validated"
