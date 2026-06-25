#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bt-r2-deploy-companion-result-reader-refresh-restore-over-restricted-static-path.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O45-E-BT-R2" "$DOC"
grep -Fq "APPROVE_FC_O45_E_BT_DEPLOY_COMPANION_RESULT_READER_REFRESH_RESTORE_OVER_RESTRICTED_STATIC_PATH" "$DOC"
grep -Fq "REFUSE_PACKAGE_STYLES_CSS_MISSING" "$DOC"
grep -Fq "app.js" "$DOC"
grep -Fq "styles.css" "$DOC"
grep -Fq "stage16FcO45EBsCompanionResultReaderRefreshRestore" "$DOC"
grep -Fq "apcCompanionQueuedChatLastJobId" "$DOC"
grep -Fq "pollQueuedJob" "$DOC"
grep -Fq "response_text" "$DOC"
grep -Fq "BT_R2_STATIC_DEPLOY_RECORDED=PASS" "$DOC"
grep -Fq "public_static_verification=PASS" "$DOC"
grep -Fq "public_unauth_job571_http=401" "$DOC"
grep -Fq "20260624fc045ebtr2" "$DOC"
grep -Fq "NO backend deploy" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO job mutation" "$DOC"
grep -Fq "NO model/helper/Ollama call" "$DOC"
grep -Fq "NO scheduler activation" "$DOC"
grep -Fq "NO persistent worker activation" "$DOC"

echo "PASS: Stage 16 FC-O45-E-BT-R2 deploy Companion result-reader refresh restore over restricted static path smoke"
