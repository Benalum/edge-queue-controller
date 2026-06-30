#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r8g-r7-browser-validation-login-good-clean-failed-r6.md"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
GUARD="frontend/wrapper-ui/apc-wrapper-local/privatepages/closed-beta-signup-guard.js"

echo "=== Stage 17K-Z-R8G-R7 validation record smoke ==="

test -f "$DOC"
test -f "$INDEX"
test -f "$GUARD"

grep -Fq "Stage 17K-Z-R8G-R7" "$DOC"
grep -Fq "Login / Register" "$DOC"
grep -Fq "Forgot password" "$DOC"
grep -Fq "closed_beta_signup_disabled" "$DOC"
grep -Fq "disabled/hidden" "$DOC"
grep -Fq "Beta testing is not open yet. Account creation is temporarily closed while we prepare Buddies Who Study." "$INDEX"
grep -Fq "closed_beta_signup_disabled" "$GUARD"

if grep -Fq "APC_LOGIN_REGISTER_HEADER_OPENER_STAGE_17K_Z_R8G_R6" "$INDEX"; then
  echo "REFUSE: failed R8G-R6 opener marker still present in source"
  exit 1
fi

echo "PASS Stage 17K-Z-R8G-R7 validation record smoke"
