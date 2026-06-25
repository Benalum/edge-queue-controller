#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bv-companion-stable-result-poller-source-no-runtime.md"
APPJS="frontend/wrapper-ui/app.js"

test -f "$DOC"
test -f "$APPJS"

grep -Fq "Stage 16 FC-O45-E-BV" "$DOC"
grep -Fq "Companion Stable Result Poller" "$DOC"
grep -Fq "single-flight poller" "$DOC"
grep -Fq "NO live deploy" "$DOC"
grep -Fq "NO public" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO job mutation" "$DOC"
grep -Fq "NO model/helper/Ollama call" "$DOC"
grep -Fq "FC-O45-E-BW" "$DOC"

grep -Fq "stage16FcO45EBsCompanionResultReaderRefreshRestore" "$APPJS"
grep -Fq "stage16FcO45EBvCompanionStableResultPoller" "$APPJS"
grep -Fq "activePollJobId" "$APPJS"
grep -Fq "lastRenderSignature" "$APPJS"
grep -Fq "scheduleRestoreLastQueuedJob" "$APPJS"
grep -Fq "maxPolls: 120" "$APPJS"
grep -Fq "intervalMs: 2000" "$APPJS"
grep -Fq "force: true" "$APPJS"
grep -Fq "Still queued. The worker may not be running yet." "$APPJS"
grep -Fq "response_text" "$APPJS"
grep -Fq "queuedChatMessages" "$APPJS"

if command -v node >/dev/null 2>&1; then
  node --check "$APPJS"
fi

echo "PASS: Stage 16 FC-O45-E-BV Companion stable result poller source no-runtime smoke"
