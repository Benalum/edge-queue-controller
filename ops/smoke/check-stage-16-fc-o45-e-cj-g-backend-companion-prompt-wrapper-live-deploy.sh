#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cj-f-backend-companion-prompt-wrapper-live-deploy.md"

test -f "$DOC"

grep -Fq "Backend Companion Prompt Wrapper Live Deploy" "$DOC"
grep -Fq "/opt/edge-queue-controller/current/edge_controller.py" "$DOC"
grep -Fq "464a464d9388088de21a86f1135ba834e84bb5f34efe9f207bb328926c334dd4" "$DOC"
grep -Fq "a4c2a93aa38b7445f360910f2e20ddf2172b1c250c2a1ee889e18d71eec9b54e" "$DOC"
grep -Fq "stage-16-fc-o45-e-cj-f-backend-companion-prompt-wrapper-deploy-20260626T035417Z" "$DOC"
grep -Fq "edge-queue-controller.service" "$DOC"
grep -Fq "port 7070" "$DOC"
grep -Fq "APC_STAGE16_FC_O45_E_CJ_E_COMPANION_PROMPT_WRAPPER_START" "$DOC"
grep -Fq "FC-O45-E-CF-R2-BROWSER-OK" "$DOC"
grep -Fq "kind=exact_answer" "$DOC"
grep -Fq "exact_output_only" "$DOC"
grep -Fq "/api/companion/study/action" "$DOC"
grep -Fq "/api/companion/voice/status" "$DOC"
grep -Fq "No frontend patch" "$DOC"
grep -Fq "Do not enable persistent workers" "$DOC"

echo "PASS stage-16-fc-o45-e-cj-g backend Companion prompt wrapper deploy record smoke"
