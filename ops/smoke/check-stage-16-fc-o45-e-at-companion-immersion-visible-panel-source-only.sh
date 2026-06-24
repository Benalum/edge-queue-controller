#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-at-companion-immersion-visible-panel-source-only.md"
APP_JS="frontend/wrapper-ui/app.js"
STYLE_CSS="frontend/wrapper-ui/styles.css"

test -f "$DOC"
test -f "$APP_JS"
test -f "$STYLE_CSS"

grep -Fq "Stage 16 FC-O45-E-AT" "$DOC"
grep -Fq "Companion Immersion Visible Panel Source-Only" "$DOC"
grep -Fq "NO backend/frontend deploy" "$DOC"
grep -Fq "NO public \`/var/www\` mutation" "$DOC"
grep -Fq "FC-O45-E-AU" "$DOC"

grep -Fq "Stage 16 FC-O45-E-AS Companion Immersion Mode scaffold" "$APP_JS"
grep -Fq "Stage 16 FC-O45-E-AT Companion Immersion visible panel source wiring" "$APP_JS"
grep -Fq "function stage16FcO45EAtWireCompanionImmersionPanel" "$APP_JS"
grep -Fq "companionImmersionEnsureMount" "$APP_JS"
grep -Fq "companionImmersionSetRuntime" "$APP_JS"
grep -Fq "companionImmersionRenderVisiblePanel" "$APP_JS"
grep -Fq "companionImmersionProcessQueuedChatResponse" "$APP_JS"
grep -Fq "apcCompanionImmersionObservedFetch" "$APP_JS"
grep -Fq "window.apcCompanionImmersionRuntime" "$APP_JS"
grep -Fq "/api/chat/queued" "$APP_JS"
grep -Fq "listening" "$APP_JS"
grep -Fq "thinking" "$APP_JS"
grep -Fq "speaking" "$APP_JS"
grep -Fq "needs_attention" "$APP_JS"

grep -Fq "Stage 16 FC-O45-E-AT Companion Immersion visible panel CSS wiring" "$STYLE_CSS"
grep -Fq "#companionImmersionVisiblePanel" "$STYLE_CSS"
grep -Fq ".companion-immersion-response" "$STYLE_CSS"
grep -Fq ".companion-immersion-debug summary" "$STYLE_CSS"

if command -v node >/dev/null 2>&1; then
  node --check "$APP_JS" >/dev/null
fi

echo "PASS: Stage 16 FC-O45-E-AT Companion Immersion visible panel source-only smoke"
