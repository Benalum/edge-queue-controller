#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cl-r-token-safe-authenticated-last-message-proof-record.md"
SMOKE="ops/smoke/check-stage-16-fc-o45-e-cl-r-token-safe-authenticated-last-message-proof-record.sh"
TARGET="edge_controller.py"

test -f "$DOC"
test -f "$SMOKE"
test -f "$TARGET"

python3 -m py_compile "$TARGET"

grep -Fq "Stage 16 FC-O45-E-CL-M: auth-gated deterministic last_message branch" "$TARGET"
grep -Fq "_stage16_cl_m_user_id = _study_current_user_id(request)" "$TARGET"
grep -Fq "return _stage16_fc_o45_e_cl_f_companion_study_last_message_mvp" "$TARGET"
grep -Fq "Missing bearer token." "$TARGET"

if grep -Fq "Stage 16 FC-O45-E-CL-F-R2: authenticated deterministic last_message branch after JSON body parse" "$TARGET"; then
  echo "REFUSE_UNSAFE_CL_F_R2_BRANCH_PRESENT"
  exit 1
fi

check_doc() {
  local needle="$1"
  grep -Fq "$needle" "$DOC"
}

check_doc "Token-Safe Authenticated Last-Message Proof Record"
check_doc "3d229bf"
check_doc "eaed8a3abea6c49b623a0dea3f22c26b9b0afaf3e120c9259a5bdd105c562d30"
check_doc "Stage 16 FC-O45-E-CL-M: auth-gated deterministic last_message branch"
check_doc "_stage16_cl_m_user_id = _study_current_user_id(request)"
check_doc "return _stage16_fc_o45_e_cl_f_companion_study_last_message_mvp"
check_doc "Temporary failure in name resolution"
check_doc "FileNotFoundError"
check_doc "CL-Q-R3 final public authenticated proof"
check_doc "CL_Q_R3_PUBLIC_HTTP=200"
check_doc "feature=stage16_fc_o45_e_cl_f_last_message_contract"
check_doc "surface=companion_study"
check_doc "action=last_message"
check_doc "authenticated=True"
check_doc "mode=deterministic_no_model"
check_doc "model=backend-deterministic/no-model"
check_doc "job_id=None"
check_doc "user_id present=True"
check_doc "no_model_call"
check_doc "no_ollama_call"
check_doc "no_pveso_call"
check_doc "no_job_insert"
check_doc "no_result_insert"
check_doc "no_scheduler_activation"
check_doc "no_timer_activation"
check_doc "no_persistent_worker_activation"
check_doc "CL_Q_R3_PUBLIC_UNAUTH_AFTER_REVOKE_HTTP=401"
check_doc "CL_Q_R3_PUBLIC_UNAUTH_AFTER_REVOKE_STILL_401=yes"
check_doc "CL_Q_R3_DB_AFTER_REVOKE_JOBS_TOTAL=576"
check_doc "CL_Q_R3_DB_AFTER_REVOKE_RESULTS_TOTAL=83"
check_doc "CL_Q_R3_DB_AFTER_REVOKE_QUEUED_COMPANION=0"
check_doc "CL_Q_R3_DB_AFTER_REVOKE_CLEANUP_ROWS=440"
check_doc "CL_Q_R3_DB_AFTER_REVOKE_MARKER_SESSIONS_TOTAL=1"
check_doc "CL_Q_R3_DB_AFTER_REVOKE_MARKER_SESSIONS_ACTIVE=0"
check_doc "no token/token-hash/password/env secret values were printed"
check_doc 'backend-safe `last_message` MVP proof'

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

echo "PASS stage-16-fc-o45-e-cl-r-r2 token-safe authenticated last_message proof record smoke"
