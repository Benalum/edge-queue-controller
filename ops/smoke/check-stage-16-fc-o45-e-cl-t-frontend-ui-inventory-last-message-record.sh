#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cl-t-frontend-ui-inventory-last-message-record.md"
SMOKE="ops/smoke/check-stage-16-fc-o45-e-cl-t-frontend-ui-inventory-last-message-record.sh"

test -f "$DOC"
test -f "$SMOKE"
test -f edge_controller.py
test -f frontend/wrapper-ui/app.js
test -f frontend/wrapper-ui/dev_server.py
test -f frontend/study-ui/study-dashboard.partial.html
test -f frontend/study-ui/styles.css

python3 -m py_compile edge_controller.py
python3 -m py_compile frontend/wrapper-ui/dev_server.py

grep -Fq "Stage 16 FC-O45-E-CL-M: auth-gated deterministic last_message branch" edge_controller.py
grep -Fq "_stage16_cl_m_user_id = _study_current_user_id(request)" edge_controller.py
grep -Fq "stage16_fc_o45_e_cl_f_last_message_contract" edge_controller.py

grep -Fq "/api/companion/" frontend/wrapper-ui/dev_server.py
grep -Fq "/api/study/" frontend/wrapper-ui/dev_server.py
grep -Fq "apiJson" frontend/wrapper-ui/app.js
grep -Fq "APC_STUDY_TOOLS_AUTH_CLEANUP_FC_O45_C_K" frontend/wrapper-ui/app.js

check_doc() {
  local needle="$1"
  grep -Fq "$needle" "$DOC"
}

check_doc "Frontend/Public UI Inventory for Last-Message Control"
check_doc "80c57f1"
check_doc "eaed8a3abea6c49b623a0dea3f22c26b9b0afaf3e120c9259a5bdd105c562d30"
check_doc "frontend/wrapper-ui/app.js"
check_doc "frontend/wrapper-ui/dev_server.py"
check_doc "frontend/study-ui/study-dashboard.partial.html"
check_doc "frontend/study-ui/styles.css"
check_doc "The safest first source-only UI target is:"
check_doc "frontend/wrapper-ui/app.js"
check_doc "APC_STUDY_EARLY_REPAIR_BOOTSTRAP_FC_O45_C_G"
check_doc "APC_STUDY_TOOLS_AUTH_CLEANUP_FC_O45_C_K"
check_doc "/api/study/decks"
check_doc "/api/study/progress"
check_doc "/api/companion/study/action"
check_doc "POST /api/companion/study/action"
check_doc "POST /api/companion/study/action action=last_message => HTTP 401"
check_doc "CL-U should be source-only"
check_doc "patch frontend/wrapper-ui/app.js only"
check_doc "signed-out/401 handling is present"
check_doc "no token literals are introduced"
check_doc "no backend files changed"

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

echo "PASS stage-16-fc-o45-e-cl-t frontend UI inventory last_message record smoke"
