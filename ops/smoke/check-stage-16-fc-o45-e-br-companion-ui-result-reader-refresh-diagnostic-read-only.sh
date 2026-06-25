#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-br-companion-ui-result-reader-refresh-diagnostic-read-only.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O45-E-BR" "$DOC"
grep -Fq "hard refresh" "$DOC"
grep -Fq "job_id=571" "$DOC"
grep -Fq "qwen2.5:0.5b" "$DOC"
grep -Fq "result_rows=1" "$DOC"
grep -Fq "BACKEND_MODEL_RESULT_STATUS=job571_completed_result_rows_1_model_qwen2.5:0.5b" "$DOC"
grep -Fq "LIKELY_GAP=companion_ui_result_reader_or_refresh_state_restore" "$DOC"
grep -Fq "FC-O45-E-BS" "$DOC"
grep -Fq "NO source patch" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO job mutation" "$DOC"
grep -Fq "NO model/helper/Ollama call" "$DOC"

echo "PASS: Stage 16 FC-O45-E-BR Companion UI result-reader hard-refresh diagnostic read-only smoke"
