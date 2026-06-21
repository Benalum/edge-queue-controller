#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3w-a-runtime-timeout-prevention-design-no-apply.md"

echo "=== Stage 16 E3W-A smoke: runtime timeout prevention design, no apply ==="

test -s "$DOC"

grep -F "Runtime Timeout Prevention Design, No Apply" "$DOC"
grep -F "does not insert a job" "$DOC"
grep -F "does not claim a job" "$DOC"
grep -F "does not call a model" "$DOC"
grep -F "atomic DB claim path works" "$DOC"
grep -F "outer PPB/tmux runtime timeout or interruption" "$DOC"
grep -F "job 29 status=failed" "$DOC"
grep -F "job 29 must not be rerun" "$DOC"
grep -F "wrapper_model_timeout_seconds < wrapper_total_timeout_seconds < PPB_outer_timeout_seconds" "$DOC"
grep -F "model call timeout target: 60 seconds" "$DOC"
grep -F "model num_predict target: 16 or lower" "$DOC"
grep -F "E3W-B read-only PVESO model inventory and timeout budget check" "$DOC"
grep -F "The next runtime proof must use a new job id" "$DOC"
grep -F "It must not use job 29" "$DOC"
grep -F "E3W_RUNTIME_ATOMIC_CLAIM_CHANGES=1" "$DOC"
grep -F "REFUSE_E3W_ATOMIC_CLAIM_NOT_ONE" "$DOC"
grep -F "E3W_ONE_SHOT_MODEL_RESULT=ok" "$DOC"
grep -F "E3W_RUNTIME_INTERNAL_FAILURE_UPDATE_CHANGES=1" "$DOC"
grep -F "E3W_RUNTIME_COMPLETION_OK" "$DOC"
grep -F "DO_NOT_RERUN" "$DOC"
grep -F "RUN_READ_ONLY_RECOVERY_FIRST" "$DOC"
grep -F "E3W must use a new job" "$DOC"

echo "E3W_A_RUNTIME_TIMEOUT_PREVENTION_DESIGN_NO_APPLY_SMOKE_OK"
