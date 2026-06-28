#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$REPO/docs/stage-16-r3q-signed-in-tab-auth-race-diagnostic.md"

test -f "$DOC"

grep -q "Signed-In Tab Auth Race Diagnostic" "$DOC"
grep -q "front-end auth routing race" "$DOC"
grep -q "checking" "$DOC"
grep -q "signed_in" "$DOC"
grep -q "signed_out" "$DOC"
grep -q "local-user" "$DOC"
grep -q "Stage 16 R3R Signed-In Tab Auth Gate Stabilization" "$DOC"
grep -q "No source app patch" "$DOC"

echo "signed-in tab auth race diagnostic R3Q source-only smoke PASS"
