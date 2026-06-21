#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$ROOT/docs/stage-16-e3q-scheduler-integration-no-apply-design.md"
OPERATOR="$ROOT/ops/model/operator-dispatch-one-queued-job-via-pveso.sh"

fail(){ echo "FAIL: $*" >&2; exit 1; }
must(){ grep -F -- "$1" "$DOC" >/dev/null || fail "missing: $1"; }

test -f "$DOC" || fail "missing doc"
test -x "$OPERATOR" || fail "missing operator artifact"
bash -n "$OPERATOR"

must "Stage 16 E3Q"
must "Scheduler Integration No-Apply Design"
must "This phase is no-apply."
must "CT203 queued job"
must "operator dispatch artifact"
must "manual helper"
must "PVESO one-shot adapter"
must "localhost-only Ollama on PVESO"
must "CT203 DB completion"
must "scheduler claim/lease gate"
must "Default-off rule"
must "Scheduler loop remains inactive."
must "Persistent lane workers remain inactive."
must "Claim and lease requirements"
must "Duplicate-result guard"
must "Completed with one result row: do not rerun."
must "Runner active: do not rerun."
must "Scheduler eligibility rules"
must "Ollama listener localhost-only"
must "CT101 stopped/onboot=0"
must "Initial model allowlist:"
must "qwen2.5:32b-instruct-q4_K_M"
must "qwen2.5-coder:32b-instruct-q4_K_M"
must "Activation boundary"
must "scheduler service start/enable"
must "persistent worker start/enable"
must "helper execution"
must "adapter execution"
must "model call"
must "job result insert"
must "E3Q does not:"
must "activate scheduler"
must "activate persistent workers"
must "call models"
must "write DB rows"
must "rerun job 27"

grep -F -- 'APC_MANUAL_COMPLETION_APPROVAL="$HELPER_REQUIRED_APPROVAL"' "$OPERATOR" >/dev/null || fail "missing helper approval bridge"
grep -F -- 'JOB_ID="$JOB_ID"' "$OPERATOR" >/dev/null || fail "missing JOB_ID bridge"

test -f "$ROOT/docs/stage-16-e3p-e-controlled-dispatch-checkpoint-handoff.md" || fail "missing E3P-E doc"

echo "PASS stage-16-e3q-scheduler-integration-no-apply-design smoke"
