#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bx-companion-final-render-wins-source-no-runtime.md"
APPJS="frontend/wrapper-ui/app.js"

test -f "$DOC"
test -f "$APPJS"

grep -Fq "Stage 16 FC-O45-E-BX" "$DOC"
grep -Fq "Final Render Wins" "$DOC"
grep -Fq "NO live deploy" "$DOC"
grep -Fq "NO public" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO job mutation" "$DOC"
grep -Fq "NO model/helper/Ollama call" "$DOC"
grep -Fq "FC-O45-E-BY" "$DOC"

grep -Fq "stage16FcO45EBvCompanionStableResultPoller" "$APPJS"
grep -Fq "stage16FcO45EBxCompanionFinalRenderWins" "$APPJS"
grep -Fq "data-stage16-fc-o45-e-bx-render-signature" "$APPJS"
grep -Fq "hasRenderedConversationRows" "$APPJS"
grep -Fq "queued-chat-message" "$APPJS"
grep -Fq "response_text" "$APPJS"
grep -Fq "queuedChatMessages" "$APPJS"

if command -v node >/dev/null 2>&1; then
  node --check "$APPJS"
fi

echo "PASS: Stage 16 FC-O45-E-BX Companion final render wins source no-runtime smoke"
