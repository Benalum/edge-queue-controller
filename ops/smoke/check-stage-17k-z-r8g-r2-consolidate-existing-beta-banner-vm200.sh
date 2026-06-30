#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r8g-r2-consolidate-existing-beta-banner-vm200.md"
ROOT="frontend/wrapper-ui/apc-wrapper-local"
GUARD="$ROOT/privatepages/closed-beta-signup-guard.js"
NEW_COPY="Beta testing is not open yet. Account creation is temporarily closed while we prepare Buddies Who Study."
OLD_EXACT="Anki + Companion update: Anki decks can be read locally in your browser for deck and card counts. Companion study integration is in progress. Google sync for personal data is planned and not yet enabled."
OLD_PREFIX="Anki + Companion update:"
UNDER_CONSTRUCTION="Under Construction: Some features do not work yet."

echo "=== Stage 17K-Z-R8G-R2 consolidated existing banner smoke ==="

test -f "$DOC"
test -f "$ROOT/index.html"
test -f "$GUARD"

grep -Fq "Stage 17K-Z-R8G-R2" "$DOC"
grep -Fq "PASS_VM200_R8G_R2_CONSOLIDATED_EXISTING_BANNER_INSTALL" "$DOC"
grep -R -Fq "$NEW_COPY" "$ROOT/index.html" "$ROOT/app.js" "$ROOT/privatepages" 2>/dev/null
grep -Fq "/privatepages/closed-beta-signup-guard.js?v=20260629-stage17k-z-r8b-closed-beta" "$ROOT/index.html"
grep -Fq "APC_CLOSED_BETA_SIGNUP_GUARD_STAGE_17K_Z_R8B" "$GUARD"

if grep -Fq "APC_CLOSED_BETA_BANNER_STAGE_17K_Z_R8B_START" "$ROOT/index.html"; then
  echo "REFUSE: extra R8B banner still present"
  exit 1
fi

if grep -R -Fq "$OLD_EXACT" "$ROOT/index.html" "$ROOT/app.js" "$ROOT/privatepages" 2>/dev/null; then
  echo "REFUSE: old exact banner still present"
  exit 1
fi

if grep -R -Fq "$OLD_PREFIX" "$ROOT/index.html" "$ROOT/app.js" "$ROOT/privatepages" 2>/dev/null; then
  echo "REFUSE: old Anki prefix still present"
  exit 1
fi

if grep -R -Fq "$UNDER_CONSTRUCTION" "$ROOT/index.html" "$ROOT/app.js" "$ROOT/privatepages" 2>/dev/null; then
  echo "REFUSE: old Under Construction banner still present"
  exit 1
fi

echo "PASS Stage 17K-Z-R8G-R2 consolidated existing banner smoke"
