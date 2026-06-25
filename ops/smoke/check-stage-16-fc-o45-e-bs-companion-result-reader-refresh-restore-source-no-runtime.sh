#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bs-companion-result-reader-refresh-restore-source-no-runtime.md"
APPJS="frontend/wrapper-ui/app.js"

test -f "$DOC"
test -f "$APPJS"

grep -Fq "Stage 16 FC-O45-E-BS" "$DOC"
grep -Fq "Companion Result-Reader Refresh Restore" "$DOC"
grep -Fq "job_id=571" "$DOC"
grep -Fq "qwen2.5:0.5b" "$DOC"
grep -Fq "result_rows=1" "$DOC"
grep -Fq "NO live deploy" "$DOC"
grep -Fq "NO public" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO job mutation" "$DOC"
grep -Fq "NO model/helper/Ollama call" "$DOC"
grep -Fq "FC-O45-E-BT" "$DOC"

grep -Fq "stage16FcO45EBsCompanionResultReaderRefreshRestore" "$APPJS"
grep -Fq "apcCompanionQueuedChatLastJobId" "$APPJS"
grep -Fq "fetchQueuedJob" "$APPJS"
grep -Fq "pollQueuedJob" "$APPJS"
grep -Fq "renderCachedConversation" "$APPJS"
grep -Fq "/api/chat/queued/" "$APPJS"
grep -Fq "response_text" "$APPJS"
grep -Fq "queuedChatMessages" "$APPJS"
grep -Fq "queuedChatForm" "$APPJS"

if command -v node >/dev/null 2>&1; then
  node --check "$APPJS"
fi

echo "PASS: Stage 16 FC-O45-E-BS Companion result-reader refresh restore source no-runtime smoke"
