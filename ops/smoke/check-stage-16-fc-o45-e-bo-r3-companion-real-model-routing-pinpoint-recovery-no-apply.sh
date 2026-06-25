#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bo-r3-companion-real-model-routing-pinpoint-recovery-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O45-E-BO-R3" "$DOC"
grep -Fq "BO-R3 recovers the BO-R2 doc/smoke checkpoint" "$DOC"
grep -Fq "requested_model=mock/no-model" "$DOC"
grep -Fq "_CHAT_QUEUED_MOCK_MODEL" "$DOC"
grep -Fq "decision[\"requested_model\"]" "$DOC"
grep -Fq "qwen2.5:0.5b" "$DOC"
grep -Fq "NO source patch" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO job mutation" "$DOC"
grep -Fq "NO model/helper/Ollama generation call" "$DOC"
grep -Fq "FC-O45-E-BP" "$DOC"
grep -Fq "FC-O45-E-BQ" "$DOC"

echo "PASS: Stage 16 FC-O45-E-BO-R3 Companion real-model routing pinpoint recovery no-apply smoke"
