#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cl-o-auth-gated-last-message-source-deploy-record.md"
SMOKE="ops/smoke/check-stage-16-fc-o45-e-cl-o-auth-gated-last-message-source-deploy-record.sh"
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

check_doc "Auth-Gated Last-Message Source and Deploy Record"
check_doc "e281a6e"
check_doc "fix: gate companion study last message auth"
check_doc "controller-stage-16-fc-o45-e-cl-m-auth-gated-last-message-source-only-2026-06-26"
check_doc "Stage 16 FC-O45-E-CL-M: auth-gated deterministic last_message branch"
check_doc "auth_line=23574"
check_doc "return_line=23575"
check_doc "_stage16_cl_m_user_id = _study_current_user_id(request)"
check_doc "return _stage16_fc_o45_e_cl_f_companion_study_last_message_mvp"
check_doc 'HTTPException(status_code=401, detail="Missing bearer token.")'
check_doc "mode=deterministic_no_model"
check_doc "model=backend-deterministic/no-model"
check_doc "job_id=None"
check_doc "APPROVE_CL_N_DEPLOY_AUTH_GATED_LAST_MESSAGE_TO_CT203"
check_doc "29f1cc92f9c6c7a6c1c89b8b8454c2d0118a820b0d9df58dc6cc947bc3c4d857"
check_doc "eaed8a3abea6c49b623a0dea3f22c26b9b0afaf3e120c9259a5bdd105c562d30"
check_doc "ce49016c13871cac8968eee9567ba4db4f2e3f96b017519731640ebcf887f1a5"
check_doc "jobs_total=576"
check_doc "results_total=83"
check_doc "queued_companion=0"
check_doc "cleanup_rows=440"
check_doc "POST /api/companion/study/action action=last_message => HTTP 401 Missing bearer token"
check_doc "edge-queue-scheduler-one-shot.timer active=inactive enabled=disabled"
check_doc 'authenticated `last_message` success path still needs a separate proof'
check_doc "non-printing bearer-token strategy"

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

echo "PASS stage-16-fc-o45-e-cl-o-r2 auth-gated last_message source deploy record smoke"
