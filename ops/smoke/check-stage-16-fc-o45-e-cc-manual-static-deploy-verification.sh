#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

CACHE_BUST="20260624fc045eccmanual2"
PUBLIC_BASE="https://alexhartel.com"
APP_JS="frontend/wrapper-ui/app.js"
DOC="docs/stage-16-fc-o45-e-cc-manual-static-deploy-verification.md"

test -f "$APP_JS"
test -f "$DOC"

local_app_sha="$(sha256sum "$APP_JS" | awk '{print $1}')"

root_tmp="$(mktemp)"
app_tmp="$(mktemp)"
trap 'rm -f "$root_tmp" "$app_tmp"' EXIT

curl -k -L -sS --max-time 10 "$PUBLIC_BASE/" -o "$root_tmp"
curl -k -L -sS --max-time 10 "$PUBLIC_BASE/app.js?v=$CACHE_BUST" -o "$app_tmp"

root_http="$(curl -k -L -sS -o /dev/null -w '%{http_code}' --max-time 10 "$PUBLIC_BASE/")"
app_http="$(curl -k -L -sS -o /dev/null -w '%{http_code}' --max-time 10 "$PUBLIC_BASE/app.js?v=$CACHE_BUST")"
public_app_sha="$(sha256sum "$app_tmp" | awk '{print $1}')"

test "$root_http" = "200"
test "$app_http" = "200"
test "$public_app_sha" = "$local_app_sha"

grep -Fq "app.js?v=$CACHE_BUST" "$root_tmp"
grep -Fq "APC_STAGE16_FC_O45_E_CA_STUDY_COMPANION_MVP_START" "$app_tmp"
grep -Fq "Last AI answer" "$app_tmp"
grep -Fq "Check status once" "$app_tmp"
grep -Fq "Copy answer" "$app_tmp"
grep -Fq "Use in Study" "$app_tmp"
grep -Fq "Make flashcards" "$app_tmp"
grep -Fq "Quiz me" "$app_tmp"

grep -Fq "manual static install touched only public static files" "$DOC"
grep -Fq "$CACHE_BUST" "$DOC"
grep -Fq "$local_app_sha" "$DOC"

echo "PASS stage-16-fc-o45-e-cc manual static deploy verification"
