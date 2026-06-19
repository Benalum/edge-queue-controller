#!/usr/bin/env bash
set -euo pipefail

PUBLIC_BASE="${PUBLIC_BASE:-https://alexhartel.com}"
PUBLIC_APP_PATH="${PUBLIC_APP_PATH:-/app.js?v=2026061814jlbr2}"
EXPECTED_APP_SHA="afc8e99b17e3bd76da364241bad19fd4290a6c02631b1b5802e411d25f004d8d"
OLD_PHRASE="laptop controller-owned"
NEW_PHRASE="CT203/controller-owned"

tmp_app="$(mktemp)"
trap 'rm -f "$tmp_app"' EXIT

curl -fsS --max-time 20 -H 'cache-control: no-cache' "$PUBLIC_BASE$PUBLIC_APP_PATH" -o "$tmp_app"
actual_sha="$(sha256sum "$tmp_app" | awk '{print $1}')"
echo "public_app_sha256=$actual_sha"
[ "$actual_sha" = "$EXPECTED_APP_SHA" ] || { echo "FAIL: public app sha mismatch"; exit 1; }
echo "PASS: public app sha matches expected"

if grep -Fq "$OLD_PHRASE" "$tmp_app"; then
  echo "FAIL: stale phrase present in public app"
  exit 1
fi
echo "PASS: stale phrase absent in public app"

grep -Fq "$NEW_PHRASE" "$tmp_app"
echo "PASS: replacement phrase present in public app"

for needle in ct-101 ct101 CT101 master-laptop llms-worker ct101-laptop-queue-worker edge-wrapper-ui 'old edge queue'; do
  if grep -Fq "$needle" "$tmp_app"; then
    echo "FAIL: legacy public text present: $needle"
    exit 1
  fi
done
echo "PASS: legacy public text absent"
