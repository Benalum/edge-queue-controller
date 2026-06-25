#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bw-deploy-companion-stable-result-poller-over-restricted-static-path.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O45-E-BW" "$DOC"
grep -Fq "APPROVE_FC_O45_E_BW_DEPLOY_COMPANION_STABLE_RESULT_POLLER_OVER_RESTRICTED_STATIC_PATH" "$DOC"
grep -Fq "stage16FcO45EBsCompanionResultReaderRefreshRestore" "$DOC"
grep -Fq "stage16FcO45EBvCompanionStableResultPoller" "$DOC"
grep -Fq "activePollJobId" "$DOC"
grep -Fq "lastRenderSignature" "$DOC"
grep -Fq "scheduleRestoreLastQueuedJob" "$DOC"
grep -Fq "response_text" "$DOC"
grep -Fq "BW_STATIC_DEPLOY_RECORDED=PASS" "$DOC"
grep -Fq "public_static_verification=PASS" "$DOC"
grep -Fq "public_unauth_job572_http=401" "$DOC"
grep -Fq "20260624fc045ebw" "$DOC"
grep -Fq "NO backend deploy" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO job mutation" "$DOC"
grep -Fq "NO model/helper/Ollama call" "$DOC"
grep -Fq "NO scheduler activation" "$DOC"
grep -Fq "NO persistent worker activation" "$DOC"

echo "PASS: Stage 16 FC-O45-E-BW deploy Companion stable result poller over restricted static path smoke"
