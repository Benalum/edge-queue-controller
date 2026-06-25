#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bu-exact-job572-companion-qwen25-one-shot-worker-model-proof.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O45-E-BU" "$DOC"
grep -Fq "APPROVE_FC_O45_E_BU_RUN_EXACT_JOB_572_COMPANION_QWEN25_ONE_SHOT_WORKER_MODEL_PROOF" "$DOC"
grep -Fq "job_id=572" "$DOC"
grep -Fq "qwen2.5:0.5b" "$DOC"
grep -Fq "BU_EXACT_JOB_572_COMPLETED_WITH_QWEN25_RESULT=PASS" "$DOC"
grep -Fq "BU_ONE_SHOT_WORKER_MODEL_PROOF_RECORDED=PASS" "$DOC"
grep -Fq "BU_EXACT_JOB_572_WORKER_MODEL_PROOF_RECORDED=PASS" "$DOC"
grep -Fq "status=completed" "$DOC"
grep -Fq "attempts=1" "$DOC"
grep -Fq "result_rows=1" "$DOC"
grep -Fq "NO mutation of any job other than" "$DOC"
grep -Fq "NO scheduler activation" "$DOC"
grep -Fq "NO persistent worker activation" "$DOC"

echo "PASS: Stage 16 FC-O45-E-BU exact job572 Companion qwen25 one-shot worker/model proof smoke"
