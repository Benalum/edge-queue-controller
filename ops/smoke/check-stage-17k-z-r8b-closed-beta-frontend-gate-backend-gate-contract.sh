#!/usr/bin/env bash
set -euo pipefail

INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
GUARD="frontend/wrapper-ui/apc-wrapper-local/privatepages/closed-beta-signup-guard.js"
DOC="docs/stage-17k-z-r8b-closed-beta-frontend-gate-backend-gate-contract.md"
CONTRACT="docs/generated/stage-17k-z-r8b-closed-beta-frontend-gate-backend-gate-contract.json"

echo "=== Stage 17K-Z-R8B closed beta frontend gate smoke ==="

test -f "$INDEX"
test -f "$GUARD"
test -f "$DOC"
test -f "$CONTRACT"

grep -Fq "APC_CLOSED_BETA_BANNER_STAGE_17K_Z_R8B_START" "$INDEX"
grep -Fq "Beta testing is not open yet. Account creation is temporarily closed while we prepare Buddies Who Study." "$INDEX"
grep -Fq '/privatepages/closed-beta-signup-guard.js?v=20260629-stage17k-z-r8b-closed-beta' "$INDEX"
grep -Fq 'id="registerTabBtn"' "$INDEX"
grep -Fq 'disabled hidden aria-disabled="true"' "$INDEX"

grep -Fq "APC_CLOSED_BETA_SIGNUP_GUARD_STAGE_17K_Z_R8B" "$GUARD"
grep -Fq "publicSignupEnabled: false" "$GUARD"
grep -Fq "Buddies Who Study" "$GUARD"
grep -Fq "buddieswhostudy.com" "$GUARD"
grep -Fq "closed_beta_signup_disabled" "$GUARD"
grep -Fq "window.fetch" "$GUARD"

python3 - <<'PYSMOKE'
import json
from pathlib import Path

contract = json.loads(Path("docs/generated/stage-17k-z-r8b-closed-beta-frontend-gate-backend-gate-contract.json").read_text())
assert contract["stage"] == "17K-Z-R8B"
assert contract["product_domain"] == "buddieswhostudy.com"
assert contract["brand_name"] == "Buddies Who Study"
assert contract["public_signup_enabled"] is False
assert contract["existing_user_signin_enabled"] is True
assert contract["frontend_gate"]["register_button_disabled"] is True
assert contract["frontend_gate"]["browser_fetch_register_guard"] is True
assert contract["backend_gate"]["required_before_dns_cutover"] is True
assert contract["backend_gate"]["cutover_blocked_until_confirmed"] is True
assert contract["migration_boundary"]["deploy_allowed_in_this_stage"] is False
print("contract_ok")
PYSMOKE

echo "PASS Stage 17K-Z-R8B closed beta frontend gate smoke"
