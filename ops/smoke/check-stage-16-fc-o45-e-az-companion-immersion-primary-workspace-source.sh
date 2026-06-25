#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-az-companion-immersion-primary-workspace-source.md"
APP_JS="frontend/wrapper-ui/app.js"
STYLE_CSS="frontend/wrapper-ui/styles.css"

test -f "$DOC"
test -f "$APP_JS"
test -f "$STYLE_CSS"

grep -Fq "Stage 16 FC-O45-E-AZ" "$DOC"
grep -Fq "NO live deploy" "$DOC"
grep -Fq "NO public \`/var/www\` mutation" "$DOC"
grep -Fq "Companion Immersion primary workspace" "$DOC"
grep -Fq "FC-O45-E-BA" "$DOC"

grep -Fq "Stage 16 FC-O45-E-AS Companion Immersion Mode scaffold" "$APP_JS"
grep -Fq "Stage 16 FC-O45-E-AT Companion Immersion visible panel source wiring" "$APP_JS"
grep -Fq "Stage 16 FC-O45-E-AZ Companion Immersion primary workspace placement" "$APP_JS"
grep -Fq "window.apcCompanionImmersionRuntime" "$APP_JS"
grep -Fq "apcCompanionImmersionObservedFetch" "$APP_JS"
grep -Fq "window.apcCompanionImmersionPrimaryWorkspace" "$APP_JS"
grep -Fq "companionImmersionPrimaryWorkspace" "$APP_JS"

grep -Fq "Stage 16 FC-O45-E-AT Companion Immersion visible panel CSS wiring" "$STYLE_CSS"
grep -Fq "Stage 16 FC-O45-E-AZ Companion Immersion primary workspace CSS" "$STYLE_CSS"
grep -Fq "#companionImmersionPrimaryWorkspace" "$STYLE_CSS"

if command -v node >/dev/null 2>&1; then
  node --check "$APP_JS"
fi

echo "PASS: Stage 16 FC-O45-E-AZ Companion Immersion primary workspace source smoke"
