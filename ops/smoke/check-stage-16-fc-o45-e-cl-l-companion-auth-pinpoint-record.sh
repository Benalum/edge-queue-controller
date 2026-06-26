#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cl-l-companion-auth-pinpoint-record.md"
SMOKE="ops/smoke/check-stage-16-fc-o45-e-cl-l-companion-auth-pinpoint-record.sh"
TARGET="edge_controller.py"

test -f "$DOC"
test -f "$SMOKE"
test -f "$TARGET"

python3 -m py_compile "$TARGET"

grep -Fq "def _auth_current_user_from_request(request: Request):" "$TARGET"
grep -Fq "def _study_current_user_id(request: Request) -> int:" "$TARGET"
grep -Fq "Missing bearer token." "$TARGET"
grep -Fq "Stage 16 FC-O45-E-CL-H-R1: CL-F-R2 direct last_message branch is intentionally disabled" "$TARGET"

if grep -Fq "Stage 16 FC-O45-E-CL-F-R2: authenticated deterministic last_message branch after JSON body parse" "$TARGET"; then
  echo "REFUSE_UNSAFE_CL_F_R2_BRANCH_PRESENT"
  exit 1
fi

if grep -Fq "return _stage16_fc_o45_e_cl_f_companion_study_last_message_mvp" "$TARGET"; then
  echo "REFUSE_UNSAFE_HELPER_RETURN_PRESENT"
  exit 1
fi

check_doc() {
  local needle="$1"
  grep -Fq "$needle" "$DOC"
}

check_doc "Companion Auth Pinpoint Record"
check_doc "5bf148e"
check_doc "29f1cc92f9c6c7a6c1c89b8b8454c2d0118a820b0d9df58dc6cc947bc3c4d857"
check_doc "jobs_total=576"
check_doc "results_total=83"
check_doc "queued_companion=0"
check_doc "cleanup_rows=440"
check_doc "HTTP 400 unsupported_companion_study_action"
check_doc "HTTP 401 Missing bearer token"
check_doc "def _auth_current_user_from_request(request: Request):"
check_doc "_auth_get_bearer_token(request)"
check_doc "HTTPException(status_code=401, detail=\"Missing bearer token.\")"
check_doc "def _study_current_user_id(request: Request) -> int:"
check_doc "user_id = _study_current_user_id(request)"
check_doc "stage16_fc_o45_e_cl_f_last_message_contract"
check_doc "mode=deterministic_no_model"
check_doc "model=backend-deterministic/no-model"
check_doc "Stage 16 FC-O45-E-CL-H-R1: CL-F-R2 direct last_message branch is intentionally disabled"
check_doc "CL-M should be source-only"

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

echo "PASS stage-16-fc-o45-e-cl-l companion auth pinpoint record smoke"
