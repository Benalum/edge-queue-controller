#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$REPO"

PHASE="stage-16-fc-o45-e-s-companion-ui-auth-validation-test"
DOC="docs/${PHASE}.md"
APP_JS="frontend/wrapper-ui/app.js"
APP_HTML="frontend/wrapper-ui/index.html"
MARKER="APC_COMPANION_AUTH_VALIDATE_UI_FC_O45_E_S"

echo "=== ${PHASE} static smoke ==="

test -s "$DOC"
test -s "$APP_JS"
test -s "$APP_HTML"

grep -q "Companion UI Auth Validation Test" "$DOC"
grep -q "queue_write: false" "$DOC"
grep -q "Study tools box" "$DOC"

grep -q "$MARKER" "$APP_JS"
grep -q "Run Companion auth test" "$APP_JS"
grep -q "X-APC-Companion-Auth-Validate-Only" "$APP_JS"
grep -q "FC-O45-E-Q" "$APP_JS"
grep -q "queue_write=false" "$APP_JS"
grep -q "removeStudyToolsBox" "$APP_JS"

grep -q "app.js?v=20260624fc045esr20" "$APP_HTML"

# Do not allow accidental cache-bust commits from cleanup archives or Study UI.
if git status --short -- .cleanup-archive frontend/study-ui/index.html | grep -q .; then
  echo "unexpected_dirty_cleanup_archive_or_study_ui=1"
  git status --short -- .cleanup-archive frontend/study-ui/index.html
  exit 1
fi

echo "RESULT=PASS ${PHASE} static smoke"
