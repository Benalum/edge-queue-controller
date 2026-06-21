#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3v-g-static-wrapper-refusal-execution-smoke-result.md"
WRAPPER="ops/scheduler/stage-16-e3v-run-one-existing-status-atomic-claim-dispatch.sh"

echo "=== Stage 16 E3V-G smoke: documented static wrapper refusal execution result ==="

test -s "$DOC"
test -x "$WRAPPER"

grep -F "E3V_G_STATIC_WRAPPER_REFUSAL_EXECUTION_SMOKE_OK" "$DOC"
grep -F "HEAD/origin/main/remote: 8682c7c" "$DOC"
grep -F "STATIC_ARTIFACT_STATUS=created_not_runtime_enabled" "$DOC"
grep -F "DEFAULT_REFUSAL=true" "$DOC"
grep -F "REFUSE_MODE_REQUIRED" "$DOC"
grep -F "MODE=dry-run" "$DOC"
grep -F "NO_DB_WRITE" "$DOC"
grep -F "NO_SCHEMA_MIGRATION" "$DOC"
grep -F "NO_DB_CLAIM" "$DOC"
grep -F "NO_HELPER_CALL" "$DOC"
grep -F "NO_ADAPTER_CALL" "$DOC"
grep -F "NO_MODEL_CALL" "$DOC"
grep -F "SCHEDULER_ACTIVATION=not_performed" "$DOC"
grep -F "PERSISTENT_WORKER_ACTIVATION=not_performed" "$DOC"
grep -F "REFUSE_E3V_RUNTIME_NOT_IMPLEMENTED_IN_STATIC_ARTIFACT" "$DOC"
grep -F "REFUSE_APPROVAL_MISSING" "$DOC"
grep -F "APPROVAL_CAPTURED=APPROVE_STAGE_16_E3V_RUN_ONE_EXISTING_STATUS_ATOMIC_CLAIM_DISPATCH_ONLY" "$DOC"
grep -F "CT203 DB stat was unchanged" "$DOC"
grep -F "did not write the CT203 DB" "$DOC"
grep -F "wrapper scaffold is still not runtime-enabled" "$DOC"
grep -F "Runtime apply remains blocked" "$DOC"

echo "E3V_G_DOC_SMOKE_OK"
