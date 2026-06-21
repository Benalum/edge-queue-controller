#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3u-b-read-only-runtime-preflight-result.md"

echo "=== Stage 16 E3U-B-R7 smoke: documented read-only runtime preflight ==="

test -s "$DOC"

grep -F "E3U_B_READ_ONLY_RUNTIME_PREFLIGHT_OK" "$DOC"
grep -F "E3U_B_R6_PVESO_CT101_PREFLIGHT_OK" "$DOC"
grep -F "HEAD/origin/main/remote: 24266ef" "$DOC"
grep -F "NO_DB_WRITE" "$DOC"
grep -F "TARGET_JOB_ID=28" "$DOC"
grep -F "DB_INTEGRITY=ok" "$DOC"
grep -F "JOBS_TOTAL=27" "$DOC"
grep -F "JOB_RESULTS_TOTAL=9" "$DOC"
grep -F "JOB_28_STATUS=queued" "$DOC"
grep -F "JOB_28_ATTEMPTS=0" "$DOC"
grep -F "JOB_28_RESULT_ROWS=0" "$DOC"
grep -F "JOB_28_MODEL=qwen2.5:32b-instruct-q4_K_M" "$DOC"
grep -F "JOB_28_PROMPT=APC_STAGE16_E3T_SCHEDULER_DRY_RUN_CANDIDATE" "$DOC"
grep -F "QUEUED_TOTAL=3" "$DOC"
grep -F "ELIGIBLE_WOULD_CLAIM_COUNT=1" "$DOC"
grep -F "WOULD_CLAIM job_id=28" "$DOC"
grep -F "PVESO_TAILSCALE_STATUS_LOOKUP=OK" "$DOC"
grep -F "root SSH_OK" "$DOC"
grep -F "OLLAMA_SERVICE_STATE=active" "$DOC"
grep -F "127.0.0.1:11434" "$DOC"
grep -F "OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=0" "$DOC"
grep -F "OLLAMA_RUNNER_COUNT=0" "$DOC"
grep -F "CT101_STATUS=stopped" "$DOC"
grep -F "CT101_ONBOOT=0" "$DOC"
grep -F "PVESO_CT101_PREFLIGHT_OK" "$DOC"
grep -F "APPROVE_STAGE_16_E3U_RUN_ONE_SCHEDULER_CONTROLLED_DISPATCH_FOR_JOB_28_ONLY" "$DOC"
grep -F "job_results total becomes 10" "$DOC"
grep -F "Do not reuse job 27" "$DOC"

echo "E3U_B_R7_DOC_SMOKE_OK"
