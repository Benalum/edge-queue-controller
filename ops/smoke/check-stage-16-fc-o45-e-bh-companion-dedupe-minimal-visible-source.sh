#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bh-companion-dedupe-minimal-visible-source.md"
APP_JS="frontend/wrapper-ui/app.js"
STYLE_CSS="frontend/wrapper-ui/styles.css"

test -f "$DOC"
test -f "$APP_JS"
test -f "$STYLE_CSS"

grep -Fq "Stage 16 FC-O45-E-BH" "$DOC"
grep -Fq "NO live deploy" "$DOC"
grep -Fq "NO public \`/var/www\` mutation" "$DOC"
grep -Fq "deduplicate repeated visible message rows" "$DOC"
grep -Fq "FC-O45-E-BI" "$DOC"

grep -Fq "Stage 16 FC-O45-E-BF Companion minimal chat source" "$APP_JS"
grep -Fq "Stage 16 FC-O45-E-BH Companion dedupe minimal visible source" "$APP_JS"
grep -Fq "window.apcCompanionDedupeMinimalVisible" "$APP_JS"
grep -Fq "dedupeVisibleMessages" "$APP_JS"
grep -Fq "hideRemainingChrome" "$APP_JS"
grep -Fq "companion-dedupe-minimal-hidden" "$APP_JS"
grep -Fq "installEnterToSend" "$APP_JS"

grep -Fq "Stage 16 FC-O45-E-BH Companion dedupe minimal visible CSS" "$STYLE_CSS"
grep -Fq ".companion-dedupe-minimal-hidden" "$STYLE_CSS"

if command -v node >/dev/null 2>&1; then
  node --check "$APP_JS"
fi

echo "PASS: Stage 16 FC-O45-E-BH Companion dedupe minimal visible source smoke"
