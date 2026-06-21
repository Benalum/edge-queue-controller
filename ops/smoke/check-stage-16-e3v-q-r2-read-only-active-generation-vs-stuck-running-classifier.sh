#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3v-q-r2-read-only-active-generation-vs-stuck-running-classifier.md"

echo "=== Stage 16 E3V-Q-R2 smoke: active-generation vs stuck-running classifier ==="

test -s "$DOC"

grep -F "Read-Only Active-Generation vs Stuck-Running Classifier" "$DOC"
grep -F "RECOVERY_R2_FINAL_CLASSIFICATION=" "$DOC"
grep -F "DO_NOT_RERUN" "$DOC"
grep -F "RUN_READ_ONLY_RECOVERY_FIRST" "$DOC"
grep -F "E3V-Q-R2 did not:" "$DOC"
grep -F "execute the wrapper" "$DOC"
grep -F "write the DB" "$DOC"
grep -F "call a model" "$DOC"
grep -F "kill any process" "$DOC"
grep -F "HEAD/origin/main/remote: 2018fd8" "$DOC"
grep -F "DB read-only output" "$DOC"
grep -F "PVESO read-only output" "$DOC"
grep -F "Runtime artifact output" "$DOC"
grep -F "Do not rerun E3V-Q" "$DOC"

echo "E3V_Q_R2_READ_ONLY_CLASSIFIER_DOC_SMOKE_OK"
