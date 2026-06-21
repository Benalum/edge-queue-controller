#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3v-q-r3-read-only-refined-stuck-running-classifier.md"

echo "=== Stage 16 E3V-Q-R3 smoke: refined stuck-running classifier ==="

test -s "$DOC"

grep -F "Read-Only Refined Stuck-Running Classifier" "$DOC"
grep -F "RECOVERY_R3_FINAL_CLASSIFICATION=" "$DOC"
grep -F "DO_NOT_RERUN" "$DOC"
grep -F "RUN_READ_ONLY_RECOVERY_FIRST" "$DOC"
grep -F "E3V-Q-R3 did not:" "$DOC"
grep -F "execute the wrapper" "$DOC"
grep -F "write the DB" "$DOC"
grep -F "call a model" "$DOC"
grep -F "kill any process" "$DOC"
grep -F "HEAD/origin/main/remote: 2018fd8" "$DOC"
grep -F "DB read-only output" "$DOC"
grep -F "PVESO refined read-only output" "$DOC"
grep -F "Runtime artifact refined output" "$DOC"
grep -F "Do not rerun E3V-Q" "$DOC"
grep -F "manual recovery plan" "$DOC"

echo "E3V_Q_R3_READ_ONLY_REFINED_CLASSIFIER_DOC_SMOKE_OK"
