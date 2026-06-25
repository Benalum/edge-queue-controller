#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bq-r3-recover-job571-via-docker-ollama-model-proof.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O45-E-BQ-R3" "$DOC"
grep -Fq "APPROVE_FC_O45_E_BQ_RUN_EXACT_JOB_571_COMPANION_QWEN25_ONE_SHOT_WORKER_MODEL_PROOF" "$DOC"
grep -Fq "job_id=571" "$DOC"
grep -Fq "qwen2.5:0.5b" "$DOC"
grep -Fq "BQ_R3_EXACT_JOB_571_COMPLETED_WITH_QWEN25_RESULT=PASS" "$DOC"
grep -Fq "BQ_R3_RECOVERY_WORKER_MODEL_PROOF_RECORDED=PASS" "$DOC"
grep -Fq "BQ_R3_EXACT_JOB_571_WORKER_MODEL_PROOF_RECORDED=PASS" "$DOC"
grep -Fq "status=completed" "$DOC"
grep -Fq "attempts=2" "$DOC"
grep -Fq "result_rows=1" "$DOC"
grep -Fq "NO mutation of any job other than" "$DOC"
grep -Fq "NO scheduler activation" "$DOC"
grep -Fq "NO persistent worker activation" "$DOC"

echo "PASS: Stage 16 FC-O45-E-BQ-R3 recover job571 via Docker Ollama model proof smoke"
