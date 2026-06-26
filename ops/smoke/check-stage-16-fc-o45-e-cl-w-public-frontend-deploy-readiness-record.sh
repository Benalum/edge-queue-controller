#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cl-w-public-frontend-deploy-readiness-record.md"
SMOKE="ops/smoke/check-stage-16-fc-o45-e-cl-w-public-frontend-deploy-readiness-record.sh"
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
grep -Fq "mountCompanionLastMessageControl(panel);" "$APP"
grep -Fq '"/api/companion/study/action"' "$APP"
grep -Fq 'action: "last_message"' "$APP"
grep -Fq "Please sign in to use the Study Companion." "$APP"

check_doc() {
  local needle="$1"
  grep -Fq "$needle" "$DOC"
}

check_doc "Public Frontend Deploy Readiness Record"
check_doc "7e9911d"
check_doc "controller-stage-16-fc-o45-e-cl-u-r2-wrapper-ui-last-message-control-source-only-2026-06-26"
check_doc "c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835"
check_doc "APC_COMPANION_LAST_MESSAGE_CL_U"
check_doc "eaed8a3abea6c49b623a0dea3f22c26b9b0afaf3e120c9259a5bdd105c562d30"
check_doc "POST /api/companion/study/action action=last_message => HTTP 401 Missing bearer token"
check_doc "/var/www/apc-wrapper-local/app.js"
check_doc "bytes=547265"
check_doc "260756d06884743c4dbc3227e4e35920301d1411f1ec5ff681dedb63a1706f08"
check_doc "has CL-U marker=no"
check_doc "has Study auth cleanup marker=yes"
check_doc "/app.js?v=20260626clv"
check_doc "/var/www/apc-wrapper-local/index.html"
check_doc "0a22952302d2973c6911f7b051a695df7848e7c422d3aa4c08d51a9882cddfed"
check_doc "/app.js?v=20260624fc045eccmanual2"
check_doc "192.168.0.250:7070"
check_doc "The safe frontend deploy target for CL-X is:"
check_doc "Do not restart nginx or cloudflared"
check_doc "CL-X can deploy app.js first without mutating index.html"
check_doc "deploy frontend/wrapper-ui/app.js to VM200 /var/www/apc-wrapper-local/app.js only"

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

echo "PASS stage-16-fc-o45-e-cl-w public frontend deploy readiness record smoke"
