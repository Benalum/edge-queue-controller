#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bp3-verify-fresh-companion-job-real-model-read-only.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O45-E-BP3" "$DOC"
grep -Fq "requested_model=qwen2.5:0.5b" "$DOC"
grep -Fq "BP3_FRESH_COMPANION_JOB_QWEN25_VERIFIED=PASS" "$DOC"
grep -Fq "BP3_READ_ONLY_VERIFICATION_RECORDED=PASS" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO job mutation" "$DOC"
grep -Fq "NO model/helper/Ollama generation call" "$DOC"
grep -Fq "NO scheduler activation" "$DOC"
grep -Fq "NO persistent worker activation" "$DOC"
grep -Fq "BQ_bounded_one_job_worker_model_proof" "$DOC"

echo "PASS: Stage 16 FC-O45-E-BP3 verify fresh Companion job real model read-only smoke"
