#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

APP="frontend/wrapper-ui/app.js"
DOC="docs/stage-16-fc-o45-e-cl-u-wrapper-ui-last-message-control-source-only.md"
SMOKE="ops/smoke/check-stage-16-fc-o45-e-cl-u-wrapper-ui-last-message-control-source-only.sh"

test -f "$APP"
test -f "$DOC"
test -f "$SMOKE"
test -f edge_controller.py

python3 -m py_compile edge_controller.py

if command -v node >/dev/null 2>&1; then
  node --check "$APP"
else
  echo "NODE_NOT_FOUND_SKIP_JS_PARSE_CHECK=yes"
fi

grep -Fq "APC_COMPANION_LAST_MESSAGE_CL_U" "$APP"
grep -Fq "COMPANION_LAST_MESSAGE_PANEL_ID_CL_U" "$APP"
grep -Fq "mountCompanionLastMessageControl(panel);" "$APP"
grep -Fq '"/api/companion/study/action"' "$APP"
grep -Fq 'action: "last_message"' "$APP"
grep -Fq "input_text: inputText" "$APP"
grep -Fq "credentials: \"include\"" "$APP"
grep -Fq "result.status === 401" "$APP"
grep -Fq "Please sign in to use the Study Companion." "$APP"
grep -Fq "deterministic" "$APP"

grep -Fq "Stage 16 FC-O45-E-CL-M: auth-gated deterministic last_message branch" edge_controller.py
grep -Fq "_stage16_cl_m_user_id = _study_current_user_id(request)" edge_controller.py
grep -Fq "stage16_fc_o45_e_cl_f_last_message_contract" edge_controller.py

if grep -Fq "Stage 16 FC-O45-E-CL-F-R2: authenticated deterministic last_message branch after JSON body parse" edge_controller.py; then
  echo "REFUSE_UNSAFE_CL_F_R2_BRANCH_PRESENT"
  exit 1
fi

if grep -E 'Bearer [A-Za-z0-9._~+/=-]{12,}' "$APP"; then
  echo "REFUSE_LITERAL_BEARER_TOKEN_IN_FRONTEND_SOURCE"
  exit 1
fi

if grep -E '(password|secret|token)[A-Za-z0-9_ -]*[:=][[:space:]]*["'\''][A-Za-z0-9._~+/=-]{12,}["'\'']' "$APP"; then
  echo "REFUSE_SECRETISH_LITERAL_IN_FRONTEND_SOURCE"
  exit 1
fi

python3 - <<'PY_VALIDATE'
from pathlib import Path

app = Path("frontend/wrapper-ui/app.js").read_text()

assert app.count("APC_COMPANION_LAST_MESSAGE_CL_U") == 1
assert app.count("function companionLastMessageHeadersClU()") == 1
assert app.count("async function companionLastMessagePostClU(inputText)") == 1
assert app.count("function mountCompanionLastMessageControl(panel)") == 1
assert app.count("mountCompanionLastMessageControl(panel);") == 1
assert app.count('"/api/companion/study/action"') == 1
assert app.count('action: "last_message"') == 1

headers_idx = app.index("function companionLastMessageHeadersClU()")
post_idx = app.index("async function companionLastMessagePostClU(inputText)")
endpoint_idx = app.index('"/api/companion/study/action"', post_idx)
action_idx = app.index('action: "last_message"', endpoint_idx)
mount_func_idx = app.index("function mountCompanionLastMessageControl(panel)")
status_idx = app.index("result.status === 401", mount_func_idx)
signin_idx = app.index("Please sign in to use the Study Companion.", status_idx)

assert headers_idx < post_idx < endpoint_idx < action_idx < mount_func_idx < status_idx < signin_idx

load_idx = app.index("async function loadTools(deckIdOverride)")
panel_idx = app.index("const panel = mountPanel();", load_idx)
return_idx = app.index("if (!panel) return;", panel_idx)
mount_call_idx = app.index("mountCompanionLastMessageControl(panel);", return_idx)
deck_idx = app.index('const decksResult = await apiJson("/api/study/decks");', mount_call_idx)

assert load_idx < panel_idx < return_idx < mount_call_idx < deck_idx

print("CL_U_R2_STATIC_JS_VALIDATION_DONE=yes")
PY_VALIDATE

check_doc() {
  local needle="$1"
  grep -Fq "$needle" "$DOC"
}

check_doc "Wrapper UI Last-Message Control Source-Only Patch"
check_doc "89edbd8"
check_doc "frontend/wrapper-ui/app.js"
check_doc "APC_COMPANION_LAST_MESSAGE_CL_U"
check_doc "/api/companion/study/action"
check_doc "action last_message"
check_doc "authenticated HTTP 200"
check_doc "unauthenticated HTTP 401"
check_doc "credentials: include"
check_doc "No token values are hardcoded."
check_doc "No frontend deploy or public /var/www mutation occurs in CL-U."
check_doc "CL-V should be read-only or deploy-plan only unless explicitly approved."

changed_paths="$(git status --porcelain | awk '{print $2}')"
echo "$changed_paths"

for required in "$APP" "$DOC" "$SMOKE"; do
  grep -Fxq "$required" <<<"$changed_paths"
done

unexpected="$(
  printf '%s\n' "$changed_paths" |
    grep -v -Fx "$APP" |
    grep -v -Fx "$DOC" |
    grep -v -Fx "$SMOKE" || true
)"

if [ -n "$unexpected" ]; then
  echo "REFUSE_UNEXPECTED_CHANGED_PATHS"
  echo "$unexpected"
  exit 1
fi

if grep -E '^(edge_controller.py|frontend/wrapper-ui/dev_server.py|frontend/study-ui/|public/|static/|web/)' <<<"$changed_paths"; then
  echo "REFUSE_UNEXPECTED_BACKEND_OR_PUBLIC_CHANGE"
  exit 1
fi

echo "PASS stage-16-fc-o45-e-cl-u-r2 wrapper UI last_message source-only smoke"
