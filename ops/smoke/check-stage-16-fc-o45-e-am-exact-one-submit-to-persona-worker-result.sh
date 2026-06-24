#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-am-exact-one-submit-to-persona-worker-result.md"

test -f "$DOC"
grep -Fq "Stage 16 FC-O45-E-AM" "$DOC"
grep -Fq "APPROVE_FC_O45_E_AM_EXACT_ONE_SUBMIT_TO_PERSONA_WORKER_RESULT" "$DOC"
grep -Fq "Target job" "$DOC"
grep -Fq "129" "$DOC"
grep -Fq "Creation method" "$DOC"
grep -Fq "controller_db_fallback_no_public_bearer_token" "$DOC"
grep -Fq "qwen2.5:0.5b" "$DOC"
grep -Fq "quality_pass=true" "$DOC"
grep -Fq "quality_flags=none" "$DOC"
grep -Fq "NO scheduler activation" "$DOC"
grep -Fq "NO persistent worker activation" "$DOC"
grep -Fq "FC_O45_E_AM_RUNTIME_RECORDED" "$DOC"

echo "PASS: Stage 16 FC-O45-E-AM exact-one submit-to-persona-worker result doc smoke"
