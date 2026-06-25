#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bp-r2-companion-real-model-routing-source-no-runtime.md"
SRC="edge_controller.py"

test -f "$DOC"
test -f "$SRC"

grep -Fq "Stage 16 FC-O45-E-BP-R2" "$DOC"
grep -Fq "requested_model=mock/no-model" "$DOC"
grep -Fq "qwen2.5:0.5b" "$DOC"
grep -Fq "_CHAT_QUEUED_REAL_MODEL" "$DOC"
grep -Fq "EDGE_COMPANION_CHAT_REQUESTED_MODEL" "$DOC"
grep -Fq "NO live deploy" "$DOC"
grep -Fq "NO CT203 runtime patch" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO job mutation" "$DOC"
grep -Fq "NO model/helper/Ollama generation call" "$DOC"
grep -Fq "BP2" "$DOC"
grep -Fq "FC-O45-E-BQ" "$DOC"

grep -Fq '_CHAT_QUEUED_REAL_MODEL' "$SRC"
grep -Fq 'EDGE_COMPANION_CHAT_REQUESTED_MODEL' "$SRC"
grep -Fq '"qwen2.5:0.5b"' "$SRC"
grep -Fq '"requested_model": _CHAT_QUEUED_REAL_MODEL,' "$SRC"
grep -Fq '_CHAT_QUEUED_JOB_TYPE = "companion.chat"' "$SRC"
if grep -Fq '"requested_model": _CHAT_QUEUED_MOCK_MODEL,' "$SRC"; then
  echo "FAIL: old mock requested_model assignment still present"
  exit 1
fi
python3 -m py_compile "$SRC"

echo "PASS: Stage 16 FC-O45-E-BP-R2 Companion real-model routing source no-runtime smoke"
