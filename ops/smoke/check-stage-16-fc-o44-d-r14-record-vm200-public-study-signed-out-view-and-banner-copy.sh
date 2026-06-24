#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o44-d-r14-record-vm200-public-study-signed-out-view-and-banner-copy.md"
OLD_BANNER="Under construction tonight: platform migration work is paused safely. Some AI/data features may be offline until maintenance resumes."
NEW_BANNER="Under Construction: Some features do not work yet."
GUARD_MARKER="APC_PUBLIC_STUDY_SIGNED_OUT_GUARD_FC_O44_D"
CACHE_BUST="20260624fc044d"

test -f "$DOC"
grep -Fq "$NEW_BANNER" "$DOC"
grep -Fq "No live deploy" "$DOC"

grep -Fq "$GUARD_MARKER" frontend/wrapper-ui/app.js
if grep -Fq "$OLD_BANNER" frontend/wrapper-ui/app.js frontend/wrapper-ui/index.html frontend/study-ui/index.html; then
  echo "old banner still present in repo frontend"
  exit 1
fi

for url in \
  "https://alexhartel.com/?fc_o44_d_r14_repo_smoke=$(date -u +%s)" \
  "https://alexhartel.com/app.js?fc_o44_d_r14_repo_smoke=$(date -u +%s)" \
  "https://alexhartel.com/app.js?v=${CACHE_BUST}&fc_o44_d_r14_repo_smoke=$(date -u +%s)"
do
  tmp="$(mktemp)"
  code="$(curl -k -L -sS --max-time 15 -H 'cache-control: no-cache' -o "$tmp" -w '%{http_code}' "$url")"
  test "$code" = "200"
  if grep -Fq "$OLD_BANNER" "$tmp"; then
    echo "old banner visible in public fetch: $url"
    rm -f "$tmp"
    exit 1
  fi
  if echo "$url" | grep -Fq "app.js"; then
    grep -Fq "$GUARD_MARKER" "$tmp"
  else
    grep -Fq "$NEW_BANNER" "$tmp"
    grep -Fq "app.js?v=${CACHE_BUST}" "$tmp"
  fi
  rm -f "$tmp"
done

echo "stage-16-fc-o44-d-r14 smoke passed"
