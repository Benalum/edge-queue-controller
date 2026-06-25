#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

CONTROLLER="$(find . -path './.git' -prune -o -path './node_modules' -prune -o -path './.cleanup-archive' -prune -o -type f -name 'edge_controller.py' -print | sort | head -n 1)"
DOC="docs/stage-16-fc-o45-e-ch-c-backend-companion-study-action-endpoint.md"

test -n "$CONTROLLER"
test -f "$CONTROLLER"
test -f "$DOC"

grep -Fq "APC_STAGE16_FC_O45_E_CH_C_COMPANION_STUDY_ACTION_START" "$CONTROLLER"
grep -Fq "APC_STAGE16_FC_O45_E_CH_C_COMPANION_STUDY_ACTION_END" "$CONTROLLER"
grep -Fq '@app.post("/api/companion/study/action")' "$CONTROLLER"
grep -Fq '@app.post("/public/companion/study/action")' "$CONTROLLER"
grep -Fq "async def api_companion_study_action" "$CONTROLLER"
grep -Fq "async def public_companion_study_action" "$CONTROLLER"
grep -Fq "_stage16_chc_companion_study_action_dispatch" "$CONTROLLER"
grep -Fq "public_study_session_status" "$CONTROLLER"
grep -Fq "public_study_session_start" "$CONTROLLER"
grep -Fq "public_study_session_pause" "$CONTROLLER"
grep -Fq "public_study_session_resume" "$CONTROLLER"
grep -Fq "public_study_session_stop" "$CONTROLLER"
grep -Fq "public_study_session_command" "$CONTROLLER"
grep -Fq "public_study_list_decks" "$CONTROLLER"
grep -Fq "public_study_list_cards" "$CONTROLLER"
grep -Fq "public_study_create_card" "$CONTROLLER"
grep -Fq "make_flashcards" "$CONTROLLER"
grep -Fq "Use add_card to save selected cards" "$CONTROLLER"

grep -Fq "No frontend patch" "$DOC"
grep -Fq "Backend source/docs/smoke only" "$DOC"
grep -Fq "POST /api/companion/study/action" "$DOC"
grep -Fq "make_flashcards" "$DOC"

python3 - <<'PY'
from pathlib import Path
import ast

controller = next(
    p for p in sorted(Path(".").rglob("edge_controller.py"))
    if ".git" not in p.parts and "node_modules" not in p.parts and ".cleanup-archive" not in p.parts
)
ast.parse(controller.read_text())
print("python_ast_parse_ok=yes")
PY

echo "PASS stage-16-fc-o45-e-ch-c backend Companion Study action endpoint source smoke"
