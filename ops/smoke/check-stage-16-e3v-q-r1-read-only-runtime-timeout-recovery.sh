#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3v-q-r1-read-only-runtime-timeout-recovery.md"

echo "=== Stage 16 E3V-Q-R1 smoke: read-only timeout recovery ==="

test -s "$DOC"

grep -F "Read-Only Runtime Timeout Recovery" "$DOC"
grep -F "RECOVERY_FINAL_CLASSIFICATION=" "$DOC"
grep -F "DO_NOT_RERUN" "$DOC"
grep -F "RUN_READ_ONLY_RECOVERY_FIRST" "$DOC"
grep -F "E3V-Q-R1 did not:" "$DOC"
grep -F "execute the wrapper" "$DOC"
grep -F "write the DB" "$DOC"
grep -F "call a model" "$DOC"
grep -F "kill any process" "$DOC"
grep -F "HEAD/origin/main/remote: 2018fd8" "$DOC"
grep -F "DB recovery output" "$DOC"
grep -F "PVESO recovery output" "$DOC"
grep -F "Runtime artifact recovery output" "$DOC"
grep -F "Do not rerun E3V-Q" "$DOC"

echo "E3V_Q_R1_READ_ONLY_TIMEOUT_RECOVERY_DOC_SMOKE_OK"
