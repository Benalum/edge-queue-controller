#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cm-c-token-safe-authenticated-public-last-message-proof.md"
SMOKE="ops/smoke/check-stage-16-fc-o45-e-cm-c-token-safe-authenticated-public-last-message-proof.sh"
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

check_doc "Token-Safe Authenticated Public Last-Message Proof Record"
check_doc "c936e48"
check_doc "controller-stage-16-fc-o45-e-cm-a-record-signed-out-public-ui-verification-2026-06-26"
check_doc "c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835"
check_doc "APC_COMPANION_LAST_MESSAGE_CL_U"
check_doc "Python SyntaxError in generated insert SQL"
check_doc "CM-B-R2 repaired the generated SQL"
check_doc "No token values were printed."
check_doc "No token hashes were printed."
check_doc "eaed8a3abea6c49b623a0dea3f22c26b9b0afaf3e120c9259a5bdd105c562d30"
check_doc "integrity=ok"
check_doc "jobs_total=576"
check_doc "results_total=83"
check_doc "active_temp_sessions=0"
check_doc "/app.js?v=20260624fc045eccmanual2"
check_doc "HTTP 200"
check_doc "feature=stage16_fc_o45_e_cl_f_last_message_contract"
check_doc "surface=companion_study"
check_doc "action=last_message"
check_doc "authenticated=true"
check_doc "mode=deterministic_no_model"
check_doc "model=backend-deterministic/no-model"
check_doc "no_model_call=true"
check_doc "no_ollama_call=true"
check_doc "no_pveso_call=true"
check_doc "no_job_insert=true"
check_doc "no_result_insert=true"
check_doc "no_scheduler_activation=true"
check_doc "no_timer_activation=true"
check_doc "no_persistent_worker_activation=true"
check_doc "without bearer => HTTP 401"
check_doc "jobs_total unchanged: 576 before and 576 after"
check_doc "results_total unchanged: 83 before and 83 after"
check_doc "temporary session is revoked"
check_doc "Next stage should be CM-D read-only productization checkpoint."

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

echo "PASS stage-16-fc-o45-e-cm-c token-safe authenticated public last_message proof record smoke"
