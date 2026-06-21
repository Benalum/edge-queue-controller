#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$ROOT/docs/stage-16-e3r-claim-lease-scheduler-dry-run-no-apply-plan.md"
OPERATOR="$ROOT/ops/model/operator-dispatch-one-queued-job-via-pveso.sh"

fail(){ echo "FAIL: $*" >&2; exit 1; }
must(){ grep -F -- "$1" "$DOC" >/dev/null || fail "missing: $1"; }

test -f "$DOC" || fail "missing E3R doc"
test -x "$OPERATOR" || fail "missing operator artifact"
bash -n "$OPERATOR"

must "Stage 16 E3R"
must "Claim/Lease Scheduler Dry-Run No-Apply Plan"
must "This phase is no-apply."
must "scheduler dry-run selector"
must "claim/lease data-shape plan"
must "read CT203 DB in read-only mode"
must "NO_DB_WRITE"
must "Candidate claim fields"
must "lease_expires_at"
must "dispatch_run_dir"
must "Lease rules"
must "exactly one active claim per job"
must "read-only timeout classification before recovery"
must "Activation boundary"
must "DB schema apply"
must "scheduler service start or enable"
must "persistent worker start or enable"
must "helper execution"
must "adapter execution"
must "model call"
must "job result insert"
must "scheduler off"
must "persistent workers off"
must "CT101 stopped/onboot=0"
must "PVESO Ollama localhost-only"
must "no rerun of job 27"
must "E3S: implement scheduler dry-run artifact"

grep -F -- 'APC_MANUAL_COMPLETION_APPROVAL="$HELPER_REQUIRED_APPROVAL"' "$OPERATOR" >/dev/null || fail "missing helper approval bridge"
grep -F -- 'JOB_ID="$JOB_ID"' "$OPERATOR" >/dev/null || fail "missing JOB_ID bridge"

test -f "$ROOT/docs/stage-16-e3q-scheduler-integration-no-apply-design.md" || fail "missing E3Q doc"
test -f "$ROOT/ops/smoke/check-stage-16-e3q-scheduler-integration-no-apply-design.sh" || fail "missing E3Q smoke"

echo "PASS stage-16-e3r-claim-lease-scheduler-dry-run-no-apply-plan smoke"
