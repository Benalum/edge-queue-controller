#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-5h4-companion-browser-queued-completion-regression.md"
CONFIG="frontend/wrapper-ui/queued_chat_config.js"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

pass() {
  echo "PASS: $*"
}

[[ -f "$DOC" ]] || fail "missing $DOC"
[[ -f "$CONFIG" ]] || fail "missing $CONFIG"

grep -Fq "Stage 5H-4" "$DOC" || fail "doc missing Stage 5H-4 title"
grep -Fq "/opt/ai-platform/frontend/components/ChatPage.tsx" "$DOC" || fail "doc missing CT101 frontend source path"
grep -Fq "Queued chat is not globally default-on" "$DOC" || fail "doc missing default-off invariant"
grep -Fq "Worker concurrency remains unchanged" "$DOC" || fail "doc missing concurrency invariant"
grep -Fq "must not send client-provided" "$DOC" || fail "doc missing user_id invariant"

grep -Fq "enabled: false" "$CONFIG" || fail "queued chat browser config no longer default-off"
grep -Fq "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" "$CONFIG" || fail "global queued chat flag no longer default-off"

ssh root@100.88.194.19 'pct exec 101 -- bash -s' <<'REMOTE'
set -euo pipefail

cd /opt/ai-platform

FILE="frontend/components/ChatPage.tsx"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$FILE" ]] || fail "missing CT101 $FILE"

grep -Fq "STAGE_5H4_COMPANION_BROWSER_QUEUED_SUBMIT_V1" "$FILE" || fail "CT101 ChatPage missing Stage 5H-4 marker"
grep -Fq "const queuedChatEnabled = useQueuedChat;" "$FILE" || fail "CT101 ChatPage queuedChatEnabled does not use useQueuedChat directly"
grep -Fq "messages/queued" "$FILE" || fail "CT101 ChatPage missing queued create route"
grep -Fq "messages/jobs" "$FILE" || fail "CT101 ChatPage missing queued status route"
grep -Fq "assistant_message" "$FILE" || fail "CT101 ChatPage missing assistant_message render handling"

if grep -Fq "const queuedChatEnabled = !isCompanion && useQueuedChat;" "$FILE"; then
  fail "CT101 ChatPage still blocks companion queued submit"
fi

if grep -nE "user_id\s*:|userId\s*:" "$FILE" | grep -E "queued|message|payload|body" >/dev/null 2>&1; then
  fail "CT101 ChatPage appears to send client-provided user_id/userId near queued payload"
fi

echo "PASS: CT101 ChatPage Stage 5H-4 companion queued marker verified"
REMOTE

if grep -RInE "LAPTOP_QUEUE_INTERNAL_TOKEN=.*|EDGE_TRUSTED_PROXY_SECRET=.*|EDGE_PUBLIC_API_KEY=.*|Authorization: Bearer|X-Worker-Token:|X-Edge-Auth-Secret: [^<]" "$DOC" >/dev/null 2>&1; then
  fail "doc appears to contain raw secret/token/header value"
fi

pass "Stage 5H-4 laptop doc and default-off invariants verified"
pass "Stage 5H-4 remote CT101 frontend queued companion gate verified"
