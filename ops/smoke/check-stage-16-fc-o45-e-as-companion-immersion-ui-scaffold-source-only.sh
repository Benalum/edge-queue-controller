#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-as-companion-immersion-ui-scaffold-source-only.md"
APP_JS="frontend/wrapper-ui/app.js"
STYLE_CSS="frontend/wrapper-ui/styles.css"

test -f "$DOC"
test -f "$APP_JS"
test -f "$STYLE_CSS"

grep -Fq "Stage 16 FC-O45-E-AS" "$DOC"
grep -Fq "Companion Immersion UI Scaffold Source-Only" "$DOC"
grep -Fq "NO backend/frontend deploy" "$DOC"
grep -Fq "NO public \`/var/www\` mutation" "$DOC"
grep -Fq "FC-O45-E-AT" "$DOC"

grep -Fq "Stage 16 FC-O45-E-AS Companion Immersion Mode scaffold" "$APP_JS"
grep -Fq "COMPANION_IMMERSION_STATES" "$APP_JS"
grep -Fq "LISTENING: \"listening\"" "$APP_JS"
grep -Fq "THINKING: \"thinking\"" "$APP_JS"
grep -Fq "SPEAKING: \"speaking\"" "$APP_JS"
grep -Fq "NEEDS_ATTENTION: \"needs_attention\"" "$APP_JS"
grep -Fq "function companionImmersionStateFromJob" "$APP_JS"
grep -Fq "function renderCompanionImmersionPanel" "$APP_JS"
grep -Fq "window.apcCompanionImmersion" "$APP_JS"
grep -Fq "/api/chat/queued" "$APP_JS"

grep -Fq "Stage 16 FC-O45-E-AS Companion Immersion Mode CSS scaffold" "$STYLE_CSS"
grep -Fq ".companion-immersion-panel" "$STYLE_CSS"
grep -Fq ".companion-immersion-state-thinking" "$STYLE_CSS"
grep -Fq ".companion-immersion-state-speaking" "$STYLE_CSS"
grep -Fq ".companion-immersion-debug" "$STYLE_CSS"

echo "PASS: Stage 16 FC-O45-E-AS Companion Immersion UI scaffold source-only smoke"
