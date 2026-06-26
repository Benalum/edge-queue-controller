#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cm-a-signed-out-public-ui-verification-record.md"
SMOKE="ops/smoke/check-stage-16-fc-o45-e-cm-a-signed-out-public-ui-verification-record.sh"
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
grep -Fq "apcCompanionLastMessageClU" "$APP"
grep -Fq "Please sign in to use the Study Companion." "$APP"
grep -Fq '"/api/companion/study/action"' "$APP"
grep -Fq 'action: "last_message"' "$APP"
grep -Fq "result.status === 401" "$APP"

check_doc() {
  local needle="$1"
  grep -Fq "$needle" "$DOC"
}

check_doc "Signed-Out Public UI Verification Record"
check_doc "afc576c"
check_doc "controller-stage-16-fc-o45-e-cl-y-record-wrapper-app-js-deploy-public-cache-proof-2026-06-26"
check_doc "c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835"
check_doc "APC_COMPANION_LAST_MESSAGE_CL_U"
check_doc "eaed8a3abea6c49b623a0dea3f22c26b9b0afaf3e120c9259a5bdd105c562d30"
check_doc "GET / => HTTP 200"
check_doc "/app.js?v=20260624fc045eccmanual2"
check_doc "bytes=571050"
check_doc "Please sign in to use the Study Companion."
check_doc "GET /app.js?v=20260626clz => HTTP 200"
check_doc "GET /api/system/status => HTTP 200"
check_doc "GET /api/companion/voice/status => HTTP 200"
check_doc "POST /api/companion/study/action action=last_message => HTTP 401"
check_doc "POST /api/companion/study/action action=status => HTTP 401"
check_doc "No deterministic no-model response was exposed to unauthenticated requests."
check_doc "temporary session revoked"

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

echo "PASS stage-16-fc-o45-e-cm-a signed-out public UI verification record smoke"
