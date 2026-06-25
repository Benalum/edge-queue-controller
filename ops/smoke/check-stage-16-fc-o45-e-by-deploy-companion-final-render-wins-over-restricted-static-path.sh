#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-by-deploy-companion-final-render-wins-over-restricted-static-path.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O45-E-BY" "$DOC"
grep -Fq "APPROVE_FC_O45_E_BY_DEPLOY_COMPANION_FINAL_RENDER_WINS_OVER_RESTRICTED_STATIC_PATH" "$DOC"
grep -Fq "stage16FcO45EBsCompanionResultReaderRefreshRestore" "$DOC"
grep -Fq "stage16FcO45EBvCompanionStableResultPoller" "$DOC"
grep -Fq "stage16FcO45EBxCompanionFinalRenderWins" "$DOC"
grep -Fq "data-stage16-fc-o45-e-bx-render-signature" "$DOC"
grep -Fq "hasRenderedConversationRows" "$DOC"
grep -Fq "queued-chat-message" "$DOC"
grep -Fq "response_text" "$DOC"
grep -Fq "BY_STATIC_DEPLOY_RECORDED=PASS" "$DOC"
grep -Fq "public_static_verification=PASS" "$DOC"
grep -Fq "public_unauth_job572_http=401" "$DOC"
grep -Fq "20260624fc045eby" "$DOC"
grep -Fq "NO backend deploy" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO job mutation" "$DOC"
grep -Fq "NO model/helper/Ollama call" "$DOC"
grep -Fq "NO scheduler activation" "$DOC"
grep -Fq "NO persistent worker activation" "$DOC"

echo "PASS: Stage 16 FC-O45-E-BY deploy Companion final render wins over restricted static path smoke"
