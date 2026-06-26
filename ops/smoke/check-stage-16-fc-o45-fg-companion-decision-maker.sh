#!/usr/bin/env bash
set -euo pipefail
set +H

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if [ ! -f edge_modules/companion_decision_maker.py ]; then
  echo "FAIL: missing edge_modules/companion_decision_maker.py" >&2
  exit 1
fi

python3 edge_modules/companion_decision_maker.py --self-test

python3 - <<'PY'
from edge_modules.companion_decision_maker import decide_companion_action

cases = [
    ("hello", "companion_chat"),
    ("explain this study card", "study_explain"),
    ("make flashcards from this note", "study_flashcard_help"),
    ("", "refusal_or_safe_reply"),
]
for message, expected in cases:
    d = decide_companion_action(user_id=16, message=message)
    assert d.decision_type == expected, (message, d.decision_type, expected)
    assert d.model_call_allowed is False
    assert d.queue_allowed is False
    assert "no_direct_browser_to_ollama" in d.safety_flags

live = decide_companion_action(user_id=16, message="hello", allow_queue=True, allow_model=True)
assert live.queue_allowed is True
assert live.model_call_allowed is True
assert live.job_type == "companion.chat"

print("PASS: stage16-fc-o45-fg companion decision maker contract")
PY
