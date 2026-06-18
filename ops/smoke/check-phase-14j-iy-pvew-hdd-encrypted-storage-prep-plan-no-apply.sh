#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-iy-pvew-hdd-encrypted-storage-prep-plan-no-apply.md"

echo "=== smoke: Phase 14J-IY PVEW HDD encrypted-storage prep plan, no apply ==="

test -f "$DOC"

grep -F "MUTATION_SCOPE: docs_smoke_only_no_apply" "$DOC"
grep -F "/dev/disk/by-id/ata-Hitachi_HDS721010CLA332_JP2940J81AMYSD" "$DOC"
grep -F "Hitachi HDS721010CLA332" "$DOC"
grep -F "JP2940J81AMYSD" "$DOC"
grep -F "1,000,204,886,016 bytes" "$DOC"
grep -F "/dev/sdb1: 100 MiB NTFS" "$DOC"
grep -F "/dev/sdb2: 931.4 GiB NTFS" "$DOC"
grep -F "SMART overall-health self-assessment: PASSED" "$DOC"
grep -F "Reallocated_Sector_Ct: 1" "$DOC"
grep -F "Current_Pending_Sector: 0" "$DOC"
grep -F "Offline_Uncorrectable: 0" "$DOC"
grep -F "UDMA_CRC_Error_Count: 0" "$DOC"
grep -F "Do not use /dev/sdb directly when mutating storage" "$DOC"
grep -F "Do not place private DBs, controller DBs, keys, private mounts, or controller authority inside VM200" "$DOC"
grep -F "Do not migrate data before encrypted storage exists and is verified" "$DOC"

python3 - "$DOC" <<'PY'
import re
import sys

doc = sys.argv[1]
bad = []

# Detect actual command-like examples, not prose such as "mount path;".
patterns = [
    re.compile(r'(^|[`$#;&|])\s*mkfs(\.|[[:space:]])'.replace('[[:space:]]', r'\s')),
    re.compile(r'(^|[`$#;&|])\s*cryptsetup\s+luksFormat\b'),
    re.compile(r'(^|[`$#;&|])\s*wipefs\s+-a\b'),
    re.compile(r'(^|[`$#;&|])\s*sgdisk\s+'),
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

echo "PASS: Phase 14J-IY no-apply storage prep doc validated"
