#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-an-browser-job131-persona-worker-result.md"

test -f "$DOC"
grep -Fq "Stage 16 FC-O45-E-AN" "$DOC"
grep -Fq "APPROVE_FC_O45_E_AN_EXACT_ONE_BROWSER_JOB131_PERSONA_WORKER_RESULT" "$DOC"
grep -Fq "Target job" "$DOC"
grep -Fq "131" "$DOC"
grep -Fq "browser_signed_in_ui_submit_existing_job_id" "$DOC"
grep -Fq "qwen2.5:0.5b" "$DOC"
grep -Fq "quality_pass=true" "$DOC"
grep -Fq "quality_flags=none" "$DOC"
grep -Fq "normal browser signed-in submit" "$DOC"
grep -Fq "result-reader-compatible completed Companion job" "$DOC"
grep -Fq "NO scheduler activation" "$DOC"
grep -Fq "NO persistent worker activation" "$DOC"
grep -Fq "FC_O45_E_AN_RUNTIME_RECORDED" "$DOC"

echo "PASS: Stage 16 FC-O45-E-AN browser job131 persona worker result doc smoke"
