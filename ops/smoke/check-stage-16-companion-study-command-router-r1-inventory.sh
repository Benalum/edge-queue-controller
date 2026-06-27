#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIRROR="$REPO/frontend/wrapper-ui/apc-wrapper-local"
COMPANION="$MIRROR/privatepages/companion.js"
STORE="$MIRROR/privatepages/study-store.js"

test -f "$COMPANION"
test -f "$STORE"

grep -q "APC_STUDY_STORE" "$COMPANION"
grep -q "normalReply" "$COMPANION"
grep -q "start study" "$COMPANION"
grep -q "stop study" "$COMPANION"

grep -q "createDeck: createDeckWithBackend" "$STORE"
grep -q "editDeck: editDeckWithBackend" "$STORE"
grep -q "createCard: createCardWithBackend" "$STORE"
grep -q "editCard: editCardWithBackend" "$STORE"
grep -q "deleteCard: deleteCardWithBackend" "$STORE"
grep -q "startSession: startSessionWithBackend" "$STORE"
grep -q "answerCurrent: answerCurrentWithBackend" "$STORE"

echo "companion study command router R1 inventory smoke PASS"
