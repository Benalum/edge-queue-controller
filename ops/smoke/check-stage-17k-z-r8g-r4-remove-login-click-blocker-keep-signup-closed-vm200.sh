#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r8g-r4-remove-login-click-blocker-keep-signup-closed-vm200.md"
GUARD="frontend/wrapper-ui/apc-wrapper-local/privatepages/closed-beta-signup-guard.js"

echo "=== Stage 17K-Z-R8G-R4 guard hotfix smoke ==="

test -f "$DOC"
test -f "$GUARD"

grep -Fq "Stage 17K-Z-R8G-R4" "$DOC"
grep -Fq "PASS_VM200_R8G_R4_REMOVE_LOGIN_CLICK_BLOCKER_INSTALL" "$DOC"
grep -Fq "closed_beta_signup_disabled" "$GUARD"
grep -Fq "btn.disabled = true" "$GUARD"
grep -Fq "btn.hidden = true" "$GUARD"

if grep -Fq 'document.addEventListener("click"' "$GUARD"; then
  echo "REFUSE: document click blocker still present"
  exit 1
fi

echo "PASS Stage 17K-Z-R8G-R4 guard hotfix smoke"
