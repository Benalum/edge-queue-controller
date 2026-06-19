#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-nb-worker-model-reentry-procedure-plan-no-apply"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"

grep -Fq "NO-APPLY PLAN ONLY." "$DOC"
grep -Fq "This phase does not wake PVESO" "$DOC"
grep -Fq "Users must continue to flow through:" "$DOC"
grep -Fq "Frontend → Backend/API → Queue → Scheduler/Worker → Model" "$DOC"
grep -Fq "APPROVE_PHASE_14J_NE_WAKE_PVESO_FOR_WORKER_MODEL_READINESS_NO_WORKER_ACTIVATION" "$DOC"
grep -Fq "APPROVE_PHASE_14J_NH_ENABLE_ONE_GUARDED_WORKER_NO_PUBLIC_MODEL_TRAFFIC" "$DOC"
grep -Fq "APPROVE_PHASE_14J_NJ_ONE_MODEL_ENDPOINT_SMOKE_NO_PUBLIC_TRAFFIC" "$DOC"
grep -Fq "APPROVE_PHASE_14J_NL_ONE_SYNTHETIC_QUEUE_JOB_NO_REAL_USER_TRAFFIC" "$DOC"
grep -Fq "Hard forbidden actions without separate approval" "$DOC"
grep -Fq "No future worker/model re-entry phase may implicitly:" "$DOC"
grep -Fq "wake or start PVESO" "$DOC"
grep -Fq "route real user traffic to workers/models" "$DOC"
grep -Fq "RESULT=PASS_PHASE_14J_NB_WORKER_MODEL_REENTRY_PROCEDURE_PLAN_NO_APPLY_DOC_READY" "$DOC"

echo "PASS: worker/model re-entry no-apply plan doc contains required gates"
