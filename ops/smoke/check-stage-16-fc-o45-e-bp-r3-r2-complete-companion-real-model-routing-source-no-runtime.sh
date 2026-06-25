#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bp-r3-r2-complete-companion-real-model-routing-source-no-runtime.md"
SRC="edge_controller.py"

test -f "$DOC"
test -f "$SRC"

grep -Fq "Stage 16 FC-O45-E-BP-R3-R2" "$DOC"
grep -Fq "_CHAT_QUEUED_REAL_MODEL" "$DOC"
grep -Fq "_CHAT_QUEUED_MOCK_MODEL" "$DOC"
grep -Fq "EDGE_COMPANION_CHAT_REQUESTED_MODEL" "$DOC"
grep -Fq "qwen2.5:0.5b" "$DOC"
grep -Fq "NO live deploy" "$DOC"
grep -Fq "NO CT203 runtime patch" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO job mutation" "$DOC"
grep -Fq "NO model/helper/Ollama generation call" "$DOC"
grep -Fq "FC-O45-E-BP2" "$DOC"
grep -Fq "FC-O45-E-BQ" "$DOC"

grep -Fq '_CHAT_QUEUED_REAL_MODEL' "$SRC"
grep -Fq 'EDGE_COMPANION_CHAT_REQUESTED_MODEL' "$SRC"
grep -Fq '"qwen2.5:0.5b"' "$SRC"
grep -Fq '"requested_model": _CHAT_QUEUED_REAL_MODEL,' "$SRC"
grep -Fq '_CHAT_QUEUED_JOB_TYPE = "companion.chat"' "$SRC"

python3 - <<'PY'
from pathlib import Path
text = Path("edge_controller.py").read_text()
for i, line in enumerate(text.splitlines(), 1):
    if "_CHAT_QUEUED_MOCK_MODEL" in line and '_CHAT_QUEUED_MOCK_MODEL = "mock/no-model"' not in line:
        raise SystemExit(f"FAIL: non-constant mock model reference remains at line {i}: {line}")
print("PASS: no non-constant mock model references remain")
PY

python3 -m py_compile "$SRC"

echo "PASS: Stage 16 FC-O45-E-BP-R3-R2 complete Companion real-model routing source no-runtime smoke"
