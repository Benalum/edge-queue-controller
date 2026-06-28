#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="$REPO/frontend/wrapper-ui/apc-wrapper-local/index.html"
COMPANION="$REPO/frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js"
STORE="$REPO/frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js"
DOC="$REPO/docs/stage-16-r3r-signed-in-tab-auth-gate-stabilization.md"

test -f "$INDEX"
test -f "$COMPANION"
test -f "$STORE"
test -f "$DOC"

if command -v node >/dev/null 2>&1; then
  node --check "$COMPANION"
  node --check "$STORE"
fi

grep -q "Stage 16 R3R signed-in auth gate" "$INDEX"
grep -q "APC_AUTH_GATE_STATUS" "$INDEX"
grep -q "apc-auth-checking" "$INDEX"
grep -q "Checking session" "$INDEX"
grep -q "/api/me" "$INDEX"
grep -q "auth-gate-r3r-20260628" "$INDEX"

grep -q "apcStableOwnerFallbackR3R" "$COMPANION"
grep -q "apcStableOwnerFallbackR3R" "$STORE"

if grep -q 'return user && user.email ? user.email : "local-user";' "$COMPANION"; then
  echo "old companion local-user conditional fallback remains"
  exit 1
fi

if grep -q 'return user && user.email ? user.email : "local-user";' "$STORE"; then
  echo "old study-store local-user conditional fallback remains"
  exit 1
fi

grep -q "Signed-In Tab Auth Gate Stabilization" "$DOC"

echo "signed-in tab auth gate R3R smoke PASS"
