#!/usr/bin/env bash
set -euo pipefail
APP_ROOT="frontend/wrapper-ui/apc-wrapper-local"
paths=(
  "header/header.css"
  "auth/auth.css"
  "publicpages/publicpages.css"
  "auth/recover.js"
  "privatepages/google-sync-config.js"
  "header/header.nav"
  "publicpages/pages/home.html"
  "publicpages/pages/study.html"
  "publicpages/pages/companion.html"
  "publicpages/pages/profile.html"
  "publicpages/pages/support.html"
  "publicpages/pages/system.html"
)
js_paths=(
  "auth/recover.js"
  "privatepages/google-sync-config.js"
)
css_paths=(
  "header/header.css"
  "auth/auth.css"
  "publicpages/publicpages.css"
)
html_paths=(
  "publicpages/pages/home.html"
  "publicpages/pages/study.html"
  "publicpages/pages/companion.html"
  "publicpages/pages/profile.html"
  "publicpages/pages/support.html"
  "publicpages/pages/system.html"
)
for rel in "${paths[@]}"; do
  test -s "$APP_ROOT/$rel" || { echo "FAIL: missing reconciled asset $APP_ROOT/$rel" >&2; exit 1; }
done
for rel in "${css_paths[@]}"; do
  if grep -qi '<!doctype\|<html\|<script' "$APP_ROOT/$rel"; then
    echo "FAIL: CSS asset looks invalid: $rel" >&2
    exit 1
  fi
done
for rel in "${js_paths[@]}"; do
  node --check "$APP_ROOT/$rel"
done
for rel in "${html_paths[@]}"; do
  grep -qi '<' "$APP_ROOT/$rel" || { echo "FAIL: HTML fragment lacks markup: $rel" >&2; exit 1; }
done
printf 'PASS stage-17k-r16bt-reconcile-live-public-static-assets-for-local-dev smoke\n'
