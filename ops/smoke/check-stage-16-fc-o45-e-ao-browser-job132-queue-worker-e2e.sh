#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-ao-browser-job132-queue-worker-e2e.md"

test -f "$DOC"
grep -Fq "Stage 16 FC-O45-E-AO" "$DOC"
grep -Fq "APPROVE_FC_O45_E_AO_EXACT_ONE_BROWSER_JOB132_QUEUE_WORKER_E2E" "$DOC"
grep -Fq "Target job" "$DOC"
grep -Fq "132" "$DOC"
grep -Fq "browser_signed_in_ui_submit_existing_job_id" "$DOC"
grep -Fq "transient_exact_one_queue_worker_e2e" "$DOC"
grep -Fq "qwen2.5:0.5b" "$DOC"
grep -Fq "quality_pass=true" "$DOC"
grep -Fq "quality_flags=none" "$DOC"
grep -Fq "transient exact-one queue worker reads that job" "$DOC"
grep -Fq "result-reader-compatible completed Companion job" "$DOC"
grep -Fq "NO scheduler activation" "$DOC"
grep -Fq "NO persistent worker activation" "$DOC"
grep -Fq "FC_O45_E_AO_RUNTIME_RECORDED" "$DOC"

echo "PASS: Stage 16 FC-O45-E-AO browser job132 queue worker E2E doc smoke"
