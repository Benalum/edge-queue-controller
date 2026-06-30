#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r8f-deploy-closed-beta-frontend-gate-vm200.md"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
GUARD="frontend/wrapper-ui/apc-wrapper-local/privatepages/closed-beta-signup-guard.js"

echo "=== Stage 17K-Z-R8F deploy record smoke ==="

test -f "$DOC"
test -f "$INDEX"
test -f "$GUARD"

grep -Fq "Stage 17K-Z-R8F" "$DOC"
grep -Fq "PASS_VM200_R8F_QGA_TARGETED_INSTALL" "$DOC"
grep -Fq "closed_beta_signup_disabled" "$DOC"
grep -Fq "Buddies Who Study" "$DOC"
grep -Fq "APC_CLOSED_BETA_BANNER_STAGE_17K_Z_R8B_START" "$INDEX"
grep -Fq "APC_CLOSED_BETA_SIGNUP_GUARD_STAGE_17K_Z_R8B" "$GUARD"

echo "PASS Stage 17K-Z-R8F deploy record smoke"
