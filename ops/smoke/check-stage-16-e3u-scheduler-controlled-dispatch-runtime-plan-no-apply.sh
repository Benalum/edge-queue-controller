#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3u-scheduler-controlled-dispatch-runtime-plan-no-apply.md"

echo "=== Stage 16 E3U-A smoke: scheduler-controlled dispatch runtime plan, no apply ==="

test -s "$DOC"

grep -F "No Apply" "$DOC" || grep -F "no-apply only" "$DOC"
grep -F "WOULD_CLAIM job_id=28" "$DOC"
grep -F "job 28 status=queued" "$DOC"
grep -F "job 28 result rows=0" "$DOC"
grep -F "APPROVE_STAGE_16_E3U_RUN_ONE_SCHEDULER_CONTROLLED_DISPATCH_FOR_JOB_28_ONLY" "$DOC"
grep -F "target_job_id=28" "$DOC"
grep -F "result_rows_for_job_28=0" "$DOC"
grep -F "APC_STAGE16_E3T_SCHEDULER_DRY_RUN_CANDIDATE" "$DOC"
grep -F "PVESO Ollama listens only on 127.0.0.1:11434" "$DOC"
grep -F "CT101 is stopped and onboot=0" "$DOC"
grep -F "do not rerun" "$DOC"
grep -F "job 28 status=completed" "$DOC"
grep -F "job 28 result rows=1" "$DOC"
grep -F "job_results total=10" "$DOC"
grep -F "Do not reuse job 27" "$DOC"
grep -F "persistent scheduler activation" "$DOC"
grep -F "persistent worker activation" "$DOC"
grep -F "PVESO/Ollama remains private and localhost-only" "$DOC"

echo "E3U_A_NO_APPLY_PLAN_SMOKE_OK"
