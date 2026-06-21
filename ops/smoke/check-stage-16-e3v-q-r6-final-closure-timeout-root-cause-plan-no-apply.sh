#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3v-q-r6-final-closure-timeout-root-cause-plan-no-apply.md"

echo "=== Stage 16 E3V-Q-R6 smoke: final closure timeout root-cause plan, no apply ==="

test -s "$DOC"

grep -F "Final Closure and Timeout Root-Cause Plan, No Apply" "$DOC"
grep -F "E3V_Q_R6_JOB29_FAILED_CLOSED_OK" "$DOC"
grep -F "E3V_Q_R6_DB_CLOSURE_OK" "$DOC"
grep -F "HEAD/origin/main/remote: 97673d3" "$DOC"
grep -F "E3V-Q-R6 did not:" "$DOC"
grep -F "write the DB" "$DOC"
grep -F "execute the wrapper" "$DOC"
grep -F "call a model" "$DOC"
grep -F "status=failed" "$DOC"
grep -F "attempts=1" "$DOC"
grep -F "result_rows=0" "$DOC"
grep -F "Job 29 is closed and must not be rerun" "$DOC"
grep -F "atomic claim artifact present" "$DOC"
grep -F "model adapter result missing or empty" "$DOC"
grep -F "completion result missing or empty" "$DOC"
grep -F "E3V-Q proved the atomic DB claim path works" "$DOC"
grep -F "outer PPB/tmux runtime timeout or interruption" "$DOC"
grep -F "Required prevention before next runtime attempt" "$DOC"
grep -F "Stage 16 E3W-A" "$DOC"
grep -F "Do not rerun E3V-Q" "$DOC"
grep -F "Do not retry job 29" "$DOC"

echo "E3V_Q_R6_FINAL_CLOSURE_TIMEOUT_ROOT_CAUSE_PLAN_NO_APPLY_SMOKE_OK"
