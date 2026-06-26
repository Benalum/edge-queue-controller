#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cl-y-wrapper-app-js-deploy-public-cache-proof.md"
SMOKE="ops/smoke/check-stage-16-fc-o45-e-cl-y-wrapper-app-js-deploy-public-cache-proof.sh"
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

check_doc "Wrapper App.js Deploy and Public Cache Proof"
check_doc "81e1bbd"
check_doc "7e9911d"
check_doc "c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835"
check_doc "APC_COMPANION_LAST_MESSAGE_CL_U"
check_doc "eaed8a3abea6c49b623a0dea3f22c26b9b0afaf3e120c9259a5bdd105c562d30"
check_doc "action=last_message => HTTP 401 Missing bearer token"
check_doc "/var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-stage-16-fc-o45-e-cl-x-r2-wrapper-app-js-deploy-20260626T162939Z"
check_doc "/var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-stage-16-fc-o45-e-cl-x-r3-wrapper-app-js-deploy-20260626T163536Z"
check_doc "http://100.127.73.75:18765"
check_doc "The temporary PVEW HTTP server was stopped."
check_doc "No nginx restart occurred."
check_doc "No cloudflared restart occurred."
check_doc "No index.html mutation occurred."
check_doc "bytes=571050"
check_doc "0a22952302d2973c6911f7b051a695df7848e7c422d3aa4c08d51a9882cddfed"
check_doc "GET /app.js => HTTP 200"
check_doc "cf-cache-status=HIT"
check_doc "GET /app.js?v=20260624fc045eccmanual2 => HTTP 200"
check_doc "CL-U marker present=yes"
check_doc "cf-cache-status=EXPIRED"
check_doc "GET /app.js?v=20260626clxr3r1 => HTTP 200"
check_doc "cf-cache-status=MISS"
check_doc "POST /api/companion/study/action action=last_message without bearer => HTTP 401"
check_doc "Therefore no index.html mutation is required immediately."
check_doc "direct /app.js URL remains stale only due to Cloudflare cache HIT"
check_doc "Next stage should be CL-Z read-only signed-out public UI behavior verification."

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

echo "PASS stage-16-fc-o45-e-cl-y wrapper app.js deploy public cache proof smoke"
