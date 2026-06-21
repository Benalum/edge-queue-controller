#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3v-j-dry-run-wrapper-guard-execution-result.md"

echo "=== Stage 16 E3V-J smoke: documented dry-run wrapper guard execution result ==="

test -s "$DOC"

grep -F "E3V_OPTION_B_DRY_RUN_GUARD_PREFLIGHT_OK" "$DOC"
grep -F "wrapper_rc=0" "$DOC"
grep -F "HEAD/origin/main/remote: da91ec5" "$DOC"
grep -F "NO_DB_WRITE" "$DOC"
grep -F "NO_SCHEMA_MIGRATION" "$DOC"
grep -F "NO_DB_CLAIM" "$DOC"
grep -F "NO_HELPER_CALL" "$DOC"
grep -F "NO_ADAPTER_CALL" "$DOC"
grep -F "NO_MODEL_CALL" "$DOC"
grep -F "DB_OPEN_MODE=sqlite_uri_mode_ro_immutable" "$DOC"
grep -F "DB_INTEGRITY=ok" "$DOC"
grep -F "DUPLICATE_JOB_RESULTS none" "$DOC"
grep -F "CT203 DB stat was unchanged" "$DOC"
grep -F "PVESO_PREFLIGHT_OK" "$DOC"
grep -F "OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=0" "$DOC"
grep -F "PVESO_RUNNER_OR_ADAPTER_PROCESS_COUNT=0" "$DOC"
grep -F "TARGET_MODEL_PRESENT=true" "$DOC"
grep -F "CT101_STATUS=stopped" "$DOC"
grep -F "CT101_ONBOOT=0" "$DOC"
grep -F "No runtime marker was found" "$DOC"
grep -F "Runtime apply remains blocked" "$DOC"
grep -F "execute-approved path remains blocked" "$DOC"

echo "E3V_J_DOC_SMOKE_OK"
