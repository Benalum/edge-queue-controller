#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r8a-buddieswhostudy-domain-source-prep-closed-beta-contract.md"
CONTRACT="docs/generated/stage-17k-z-r8a-buddieswhostudy-domain-source-prep-closed-beta-contract.json"

echo "=== Stage 17K-Z-R8A source prep smoke ==="

test -f "$DOC"
test -f "$CONTRACT"

grep -Fq "buddieswhostudy.com" "$DOC"
grep -Fq "Buddies Who Study" "$DOC"
grep -Fq "Beta testing is not open yet. Account creation is temporarily closed while we prepare Buddies Who Study." "$DOC"
grep -Fq "https://www.googleapis.com/auth/drive.appdata" "$DOC"
grep -Fq "appDataFolder" "$DOC"
grep -Fq "SPF" "$DOC"
grep -Fq "DKIM" "$DOC"
grep -Fq "DMARC" "$DOC"
grep -Fq "No DNS or Cloudflare mutation happens in R8A." "$DOC"

python3 - <<'PY'
import json
from pathlib import Path

contract = json.loads(Path("docs/generated/stage-17k-z-r8a-buddieswhostudy-domain-source-prep-closed-beta-contract.json").read_text())

assert contract["stage"] == "17K-Z-R8A"
assert contract["new_product_domain"] == "buddieswhostudy.com"
assert contract["brand_name"] == "Buddies Who Study"
assert contract["account_creation_policy"]["mode"] == "closed_beta"
assert contract["account_creation_policy"]["public_signup_enabled"] is False
assert contract["account_creation_policy"]["existing_user_signin_enabled"] is True
assert contract["domain_migration_policy"]["do_not_cut_dns_in_this_stage"] is True
assert contract["domain_migration_policy"]["do_not_change_cloudflare_in_this_stage"] is True
assert contract["domain_migration_policy"]["do_not_change_google_cloud_in_this_stage"] is True
assert contract["domain_migration_policy"]["do_not_change_email_provider_in_this_stage"] is True
assert contract["google_oauth_future_changes"]["scope"] == "https://www.googleapis.com/auth/drive.appdata"
assert contract["google_oauth_future_changes"]["storage"] == "appDataFolder"
assert "https://buddieswhostudy.com" in contract["google_oauth_future_changes"]["authorized_javascript_origins"]
assert contract["email_future_changes"]["requires_spf_dkim_dmarc"] is True

print("contract_ok")
PY

echo "PASS Stage 17K-Z-R8A source prep smoke"
