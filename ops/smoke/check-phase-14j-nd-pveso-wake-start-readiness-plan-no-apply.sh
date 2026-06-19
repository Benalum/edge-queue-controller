#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-nd-pveso-wake-start-readiness-plan-no-apply"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"

grep -Fq "NO-APPLY PLAN ONLY." "$DOC"
grep -Fq "This phase does not wake PVESO" "$DOC"
grep -Fq "PVESO remains parked/offline unless explicitly approved." "$DOC"
grep -Fq "Worker/model runtime activation remains parked." "$DOC"
grep -Fq "APPROVE_PHASE_14J_NE_WAKE_PVESO_FOR_WORKER_MODEL_READINESS_NO_WORKER_ACTIVATION" "$DOC"
grep -Fq "workers status counts: \`offline:2\`" "$DOC"
grep -Fq "jobs status counts: \`failed:1,forwarded:20,queued:1\`" "$DOC"
grep -Fq "Future apply forbidden actions even after approval" "$DOC"
grep -Fq "start or enable worker services" "$DOC"
grep -Fq "call Ollama/model endpoints" "$DOC"
grep -Fq "route real user traffic to models/workers" "$DOC"
grep -Fq "private storage host mount state is not mounted" "$DOC"
grep -Fq "Expected next phases" "$DOC"
grep -Fq "Phase 14J-NE — approved PVESO wake/start readiness apply." "$DOC"
grep -Fq "RESULT=PASS_PHASE_14J_ND_PVESO_WAKE_START_READINESS_PLAN_NO_APPLY_DOC_READY" "$DOC"

echo "PASS: PVESO wake/start readiness no-apply plan contains required gates"
