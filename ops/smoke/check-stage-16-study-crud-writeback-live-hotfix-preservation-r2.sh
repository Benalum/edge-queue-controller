#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

EDGE="$REPO/edge_controller.py"
MIRROR="$REPO/frontend/wrapper-ui/apc-wrapper-local"
STORE="$MIRROR/privatepages/study-store.js"
STUDY="$MIRROR/privatepages/study.js"
COMPANION="$MIRROR/privatepages/companion.js"
SOL="$MIRROR/privatepages/sol.css"
SESSION_CSS="$MIRROR/privatepages/study-session.css"
INDEX="$MIRROR/index.html"

test -f "$EDGE"
test -f "$INDEX"
test -f "$STORE"
test -f "$STUDY"
test -f "$COMPANION"
test -f "$SOL"
test -f "$SESSION_CSS"
test -f "$MIRROR/README.md"

python3 -m py_compile "$EDGE"

grep -q '/api/study/session-writeback-lite' "$EDGE"
grep -q '/api/study/deck-writeback-lite' "$EDGE"
grep -q '/api/study/card-writeback-lite' "$EDGE"
grep -q 'archived_at = ?' "$EDGE"

grep -q 'crud-writeback-r2-ui-args-20260627' "$INDEX"
grep -q 'stop-study-session-command-fix-20260627' "$INDEX"
grep -q 'hide-companion-study-box-20260627' "$INDEX"

grep -q 'CT203 deck/card CRUD writeback block R2' "$STORE"
grep -q 'deck create writeback' "$STORE"
grep -q 'deck update writeback' "$STORE"
grep -q 'card create writeback' "$STORE"
grep -q 'card update writeback' "$STORE"
grep -q 'card delete writeback' "$STORE"
grep -q 'startSession: startSessionWithBackend' "$STORE"
grep -q 'answerCurrent: answerCurrentWithBackend' "$STORE"
grep -q 'stopSession: stopSessionWithBackend' "$STORE"

grep -q 'Total card reviews' "$STUDY"
grep -q 'Study session' "$STUDY"

grep -q 'stop study' "$COMPANION"
grep -q 'start study' "$COMPANION"

grep -q 'sol-study-box' "$SOL"

echo "study CRUD writeback live hotfix preservation R2 smoke PASS"
