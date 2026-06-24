#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-al-submit-to-worker-automation-design-contract.md"

test -f "$DOC"
grep -Fq "Stage 16 FC-O45-E-AL" "$DOC"
grep -Fq "repo/docs/smoke only" "$DOC"
grep -Fq "job: \`128\`" "$DOC"
grep -Fq "quality_pass=true" "$DOC"
grep -Fq "normal signed-in submit -> bounded worker completion -> result-reader display" "$DOC"
grep -Fq "APPROVE_FC_O45_E_AM_EXACT_ONE_SUBMIT_TO_PERSONA_WORKER_RESULT" "$DOC"
grep -Fq "Refuse unless target job has \`job_type=companion.chat\`" "$DOC"
grep -Fq "Insert exactly one result row only for the target job" "$DOC"
grep -Fq "Do **not** jump directly to scheduler/timer/persistent worker activation" "$DOC"
grep -Fq "NO model generation" "$DOC"
grep -Fq "Live source inventory" "$DOC"

echo "PASS: Stage 16 FC-O45-E-AL submit-to-worker automation design contract doc smoke"
