#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-q-scheduler-artifact-allowlist-update-plan-no-activation.md"
SMOKE="ops/smoke/check-stage-16-e3z-q-scheduler-artifact-allowlist-update-plan-no-activation.sh"

echo "=== Stage 16 E3Z-Q no-activation plan smoke R4 ==="
echo "MUTATION_SCOPE=read_only_repo_file_validation_only"
echo "NO live infra mutation"
echo "NO DB write"
echo "NO service/timer mutation"
echo "NO helper/model call"

test -f "$DOC"
test -f "$SMOKE"

grep -Fq "STAGE_16_E3Z_Q_PLAN=1" "$DOC"
grep -Fq "NO_ACTIVATION=1" "$DOC"
grep -Fq "PROOF_JOB_ALLOWLIST=35,36" "$DOC"
grep -Fq "HARD_NO_RERUN=E3V-Q,29,30,31,32,33,34" "$DOC"
grep -Fq "job 35: marker" "$DOC"
grep -Fq "job 36: marker" "$DOC"
grep -Fq "one proof job per tick" "$DOC"
grep -Fq "E3Z-R should perform the scheduler artifact allowlist update with explicit approval" "$DOC"
grep -Fq "E3Z-T should require separate explicit approval for any timer/service activation" "$DOC"

echo "E3Z_Q_NO_ACTIVATION_PLAN_SMOKE_OK=1"
