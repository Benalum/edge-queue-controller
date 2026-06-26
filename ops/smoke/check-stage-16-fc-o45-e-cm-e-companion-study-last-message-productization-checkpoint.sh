#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cm-e-companion-study-last-message-productization-checkpoint.md"
SMOKE="ops/smoke/check-stage-16-fc-o45-e-cm-e-companion-study-last-message-productization-checkpoint.sh"
APP="frontend/wrapper-ui/app.js"

test -f "$DOC"
test -f "$SMOKE"
test -f "$APP"
test -f edge_controller.py

python3 -m py_compile edge_controller.py

if command -v node >/dev/null 2>&1; then
  node --check "$APP"
else
  echo "NODE_NOT_FOUND_SKIP_JS_PARSE_CHECK=yes"
fi

grep -Fq "APC_COMPANION_LAST_MESSAGE_CL_U" "$APP"
grep -Fq "Please sign in to use the Study Companion." "$APP"
grep -Fq '"/api/companion/study/action"' "$APP"
grep -Fq 'action: "last_message"' "$APP"
grep -Fq "_stage16_cl_m_user_id = _study_current_user_id(request)" edge_controller.py
grep -Fq "backend-deterministic/no-model" edge_controller.py

check_doc() {
  local needle="$1"
  grep -Fq "$needle" "$DOC"
}

check_doc "Companion Study Last-Message Productization Checkpoint"
check_doc "3d9bd59"
check_doc "controller-stage-16-fc-o45-e-cm-c-record-token-safe-authenticated-public-last-message-proof-2026-06-26"
check_doc "c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835"
check_doc "eaed8a3abea6c49b623a0dea3f22c26b9b0afaf3e120c9259a5bdd105c562d30"
check_doc "backend auth-gated last_message action"
check_doc "deterministic no-model response contract"
check_doc "wrapper UI control deployed to VM200 app.js"
check_doc "signed-out public UI behavior verified"
check_doc "authenticated public behavior verified"
check_doc "integrity=ok"
check_doc "jobs_total=576"
check_doc "results_total=83"
check_doc "queued_companion=0"
check_doc "running_total=10"
check_doc "cleanup_rows=440"
check_doc "active_sessions=89"
check_doc "revoked_sessions=117"
check_doc "No scheduler, timer, persistent worker, helper, selector, model, Ollama, or PVESO path was activated."
check_doc "0a22952302d2973c6911f7b051a695df7848e7c422d3aa4c08d51a9882cddfed"
check_doc "/app.js?v=20260624fc045eccmanual2"
check_doc "GET /api/system/status => HTTP 200"
check_doc "GET /api/companion/voice/status => HTTP 200"
check_doc "Voice status returned a disabled/safe marker."
check_doc "POST /api/companion/study/action action=last_message => HTTP 401"
check_doc "public authenticated last_message HTTP 200"
check_doc "temporary session revoked"
check_doc "jobs_total remained 576"
check_doc "results_total remained 83"
check_doc "The Study Companion last-message MVP is stable at the intended first productization level."
check_doc "Option 1: Source refresh and new chat handoff."
check_doc "Option 2: UI polish."
check_doc "Option 3: Add a real authenticated Study Companion action."
check_doc "Option 4: Plan model-backed Companion later."

changed_paths="$(git status --porcelain | awk '{print $2}')"
echo "$changed_paths"

for required in "$DOC" "$SMOKE"; do
  grep -Fxq "$required" <<<"$changed_paths"
done

unexpected="$(
  printf '%s\n' "$changed_paths" |
    grep -v -Fx "$DOC" |
    grep -v -Fx "$SMOKE" || true
)"

if [ -n "$unexpected" ]; then
  echo "REFUSE_UNEXPECTED_CHANGED_PATHS"
  echo "$unexpected"
  exit 1
fi

echo "PASS stage-16-fc-o45-e-cm-e productization checkpoint record smoke"
