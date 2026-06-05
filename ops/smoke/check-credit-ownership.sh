#!/usr/bin/env bash
set -euo pipefail

CT_HOST="${CT_HOST:-root@100.88.194.19}"
CT_ID="${CT_ID:-101}"
CT_PATH="${CT_PATH:-/opt/ai-platform}"

echo "=== local controller credit routes ==="
python3 - <<'PY'
from edge_controller import app

expected = {
    "/system/account/credits",
    "/system/account/credit-pools",
    "/system/credits/reserve",
    "/system/credits/commit",
    "/system/credits/refund",
    "/system/credits/grant",
    "/system/credits/reserve-v2",
    "/system/credits/commit-v2",
    "/system/credits/refund-v2",
    "/system/credits/grant-free",
    "/system/credits/grant-paid",
    "/system/ads/reward/status",
    "/system/ads/reward/claim",
}

seen = set()

for r in app.routes:
    path = getattr(r, "path", "")
    methods = ",".join(sorted(getattr(r, "methods", []) or []))
    if "credits" in path or "credit-pools" in path or "ads/reward" in path:
        print(f"{methods:20} {path}")
        seen.add(path)

missing = sorted(expected - seen)
if missing:
    print("ERROR: missing expected controller credit routes:")
    for path in missing:
        print(" -", path)
    raise SystemExit(1)

print("OK: controller owns expected credit routes")
PY

echo
echo "=== CT101 must not expose /api/credits routes ==="
ssh "$CT_HOST" "pct exec $CT_ID -- docker exec -i ai-platform-api python - <<'PY'
from app.main import app

bad = []
for r in app.routes:
    path = getattr(r, 'path', '')
    methods = ','.join(sorted(getattr(r, 'methods', []) or []))
    if path.startswith('/api/credits') or 'credits/rewarded' in path:
        bad.append((methods, path))

if bad:
    print('ERROR: CT101 exposes forbidden credit routes:')
    for methods, path in bad:
        print(methods, path)
    raise SystemExit(1)

print('OK: CT101 exposes no /api/credits routes')
PY"

echo
echo "=== CT101 Postgres must not contain duplicate credit tables ==="
ssh "$CT_HOST" "pct exec $CT_ID -- docker exec -i ai-platform-api python - <<'PY'
from sqlalchemy import inspect
from app.db.session import engine

forbidden = {
    'user_credit_wallets',
    'credit_ledger',
    'rewarded_ad_sessions',
}

tables = set(inspect(engine).get_table_names())
bad = sorted(forbidden & tables)

if bad:
    print('ERROR: forbidden CT101 credit tables exist:')
    for table in bad:
        print(' -', table)
    raise SystemExit(1)

print('OK: CT101 duplicate credit tables are absent')
PY"

echo
echo "=== CT101 source must not contain duplicate credit system remnants ==="
ssh "$CT_HOST" "pct exec $CT_ID -- bash -lc '
cd \"$CT_PATH\"

if grep -RInE \"rewarded_credits|/api/credits|credits/rewarded|user_credit_wallets|rewarded_ad_sessions|credit_ledger\" backend frontend 2>/dev/null; then
  echo \"ERROR: CT101 source still contains forbidden credit remnants\"
  exit 1
fi

echo \"OK: CT101 source has no duplicate credit remnants\"
'"

echo
echo "=== HTTP check: CT101 /api/credits/balance should be 404 ==="
STATUS="$(ssh "$CT_HOST" "pct exec $CT_ID -- bash -lc 'curl -sS -o /tmp/ct101-credit-check.out -w \"%{http_code}\" http://100.88.245.33:8088/api/credits/balance'")"
cat <(echo "HTTP $STATUS")
if [ "$STATUS" != "404" ]; then
  echo "ERROR: expected HTTP 404 from CT101 /api/credits/balance"
  exit 1
fi

echo
echo "PASS: credit ownership is clean"
