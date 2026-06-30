#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r8g-r3-fix-beta-banner-login-opener-vm200.md"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
GUARD="frontend/wrapper-ui/apc-wrapper-local/privatepages/closed-beta-signup-guard.js"

NEW_COPY="Beta testing is not open yet. Account creation is temporarily closed while we prepare Buddies Who Study."
OLD_TAIL_1="Anki decks can be read locally in your browser for deck and card counts."
OLD_TAIL_2="Companion study integration is in progress."
OLD_TAIL_3="Google sync for personal data is planned and not yet enabled."

echo "=== Stage 17K-Z-R8G-R3 banner/login hotfix smoke ==="

test -f "$DOC"
test -f "$INDEX"
test -f "$GUARD"

grep -Fq "Stage 17K-Z-R8G-R3" "$DOC"
grep -Fq "PASS_VM200_R8G_R3_BANNER_LOGIN_HOTFIX_INSTALL" "$DOC"
grep -Fq "$NEW_COPY" "$INDEX"
grep -Fq "/privatepages/closed-beta-signup-guard.js?v=20260629-stage17k-z-r8b-closed-beta" "$INDEX"
grep -Fq 'closest("#registerTabBtn")' "$GUARD"
grep -Fq "closed_beta_signup_disabled" "$GUARD"

if grep -Fq "$OLD_TAIL_1" "$INDEX"; then exit 1; fi
if grep -Fq "$OLD_TAIL_2" "$INDEX"; then exit 1; fi
if grep -Fq "$OLD_TAIL_3" "$INDEX"; then exit 1; fi
if grep -Fq "APC_CLOSED_BETA_BANNER_STAGE_17K_Z_R8B_START" "$INDEX"; then exit 1; fi
if grep -Fq 'text.includes("register")' "$GUARD"; then exit 1; fi

echo "PASS Stage 17K-Z-R8G-R3 banner/login hotfix smoke"
