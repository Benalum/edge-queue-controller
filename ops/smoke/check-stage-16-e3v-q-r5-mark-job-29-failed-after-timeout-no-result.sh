#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3v-q-r5-mark-job-29-failed-after-timeout-no-result.md"

echo "=== Stage 16 E3V-Q-R5 smoke: job 29 failed after timeout/no result ==="

test -s "$DOC"

grep -F "Mark Job 29 Failed After Timeout/No Result" "$DOC"
grep -F "E3V_Q_R5_MARK_JOB_29_FAILED_AFTER_TIMEOUT_NO_RESULT_OK" "$DOC"
grep -F "APPROVE_STAGE_16_E3V_Q_R5_MARK_JOB_29_FAILED_AFTER_TIMEOUT_NO_RESULT_ONLY" "$DOC"
grep -F "HEAD/origin/main/remote: e20576d" "$DOC"
grep -F "performed exactly one guarded DB update" "$DOC"
grep -F "It did not:" "$DOC"
grep -F "execute the wrapper" "$DOC"
grep -F "claim the job" "$DOC"
grep -F "increment attempts" "$DOC"
grep -F "insert job_results" "$DOC"
grep -F "call a model" "$DOC"
grep -F "DB_INTEGRITY_BEFORE=ok" "$DOC"
grep -F "PVESO_ACTIVE_MODEL_CLIENT_COUNT=0" "$DOC"
grep -F "PVESO_OLLAMA_11434_CONNECTION_COUNT=0" "$DOC"
grep -F "MODEL_ARTIFACT_STATUS=missing_or_empty" "$DOC"
grep -F "COMPLETION_ARTIFACT_STATUS=missing_or_empty" "$DOC"
grep -F "E3V_Q_R5_FAILURE_UPDATE_CHANGES=1" "$DOC"
grep -F "E3V_Q_R5_FAILURE_UPDATE_COMMIT_OK" "$DOC"
grep -F "DB_INTEGRITY_AFTER=ok" "$DOC"
grep -F "JOB29_POSTFLIGHT id=29 status=failed attempts=1" "$DOC"
grep -F "result_rows=0" "$DOC"
grep -F "last_error contains E3V-Q timeout recovery" "$DOC"
grep -F "Job results total remained unchanged" "$DOC"
grep -F "Do not rerun E3V-Q" "$DOC"

echo "E3V_Q_R5_DOC_SMOKE_OK"
