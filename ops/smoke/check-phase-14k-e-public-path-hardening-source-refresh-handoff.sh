#!/usr/bin/env bash
set -euo pipefail
set +H

DOC="docs/phase-14k-e-public-path-hardening-source-refresh-handoff.md"
PROMPT_DOC="docs/new-chat-prompt-after-phase-14k-e-public-path-hardening.md"

echo "=== Phase 14K-E smoke ==="

test -f "$DOC"
test -f "$PROMPT_DOC"
echo "PASS: handoff docs exist"

python3 - "$DOC" "$PROMPT_DOC" <<'PY'
import sys

checks = {
    sys.argv[1]: [
        "HEAD/origin/main: `44e1064`",
        "CT203 `net0` is static and includes a gateway",
        "Public `/api/system/status` returns HTTP 200",
        "VM200 local `127.0.0.1:18080/api/system/status` returns HTTP 200",
        "CT204 remains stopped",
        "Private storage `/srv/apc-private-data` is not mounted",
        "Begin Stage 15: Controller/queue/Decision Maker integration",
        "Chat title suggestion",
        "New chat handoff prompt",
    ],
    sys.argv[2]: [
        "Continue AI Platform Control from the Phase 14K-E Public Path Hardening Source Refresh Handoff",
        "HEAD/origin/main: `44e1064`",
        "Public `/api/system/status` is HTTP 200",
        "CT203 direct `/api/system/status` is HTTP 404",
        "Start Stage 15 with a compact read-only/no-apply CT203 controller/queue/Decision Maker inventory",
        "Do not activate workers, scheduler, or live model calls yet",
    ],
}

missing = []
for path, needles in checks.items():
    text = open(path, "r", encoding="utf-8").read()
    for needle in needles:
        if needle in text:
            print(f"PASS: {path}: {needle}")
        else:
            print(f"FAIL: {path}: missing {needle}")
            missing.append((path, needle))

if missing:
    sys.exit(1)
PY

echo "PASS_PHASE_14K_E_SMOKE"
