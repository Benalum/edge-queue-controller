#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-5h6-companion-queued-final-readiness-report.md"
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

grep -Fq "Stage 5H-6" "$DOC" || fail "doc missing Stage 5H-6 title"
grep -Fq "documentation and verification stage only" "$DOC" || fail "doc missing docs-only invariant"
grep -Fq "does not change runtime behavior" "$DOC" || fail "doc missing no-runtime-change invariant"
grep -Fq "does not make queued chat globally default-on" "$DOC" || fail "doc missing default-off invariant"
grep -Fq "does not increase worker concurrency" "$DOC" || fail "doc missing concurrency invariant"
grep -Fq 'does not accept client-provided `user_id`' "$DOC" || fail "doc missing user_id invariant"
grep -Fq "assistant_message.content" "$DOC" || fail "doc missing final assistant_message render path"
grep -Fq "opt-in queued mode path" "$DOC" || fail "doc missing opt-in readiness conclusion"

grep -Fq "enabled: false" "$CONFIG" || fail "queued chat browser config no longer default-off"
grep -Fq "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" "$CONFIG" || fail "global queued chat flag no longer default-off"

for tag in \
  controller-stage-5h3-companion-queued-create-status-lifecycle-smoke-corrected2-2026-06-08 \
  controller-stage-5h4-companion-browser-queued-completion-regression-2026-06-08 \
  controller-stage-5h5-companion-html-error-response-regression-smoke-2026-06-08
do
  git rev-parse -q --verify "refs/tags/$tag" >/dev/null || fail "missing local controller tag $tag"
done

git ls-remote --tags origin controller-stage-5h5-companion-html-error-response-regression-smoke-2026-06-08 | grep -Fq controller-stage-5h5-companion-html-error-response-regression-smoke-2026-06-08 || fail "missing remote Stage 5H-5 controller tag"

ssh root@100.88.194.19 'pct exec 101 -- bash -s' <<'REMOTE'
set -euo pipefail

cd /opt/ai-platform

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

FILE="frontend/components/ChatPage.tsx"
TAG="ai-platform-stage-5h4-companion-browser-queued-completion-regression-2026-06-08"

[[ -f "$FILE" ]] || fail "missing CT101 ChatPage"
grep -Fq "STAGE_5H4_COMPANION_BROWSER_QUEUED_SUBMIT_V1" "$FILE" || fail "CT101 ChatPage missing Stage 5H-4 marker"
grep -Fq "const queuedChatEnabled = useQueuedChat;" "$FILE" || fail "CT101 ChatPage does not allow companion queued path through useQueuedChat"
grep -Fq "messages/queued" "$FILE" || fail "CT101 ChatPage missing queued create route"
grep -Fq "messages/jobs" "$FILE" || fail "CT101 ChatPage missing queued status route"
grep -Fq "assistant_message" "$FILE" || fail "CT101 ChatPage missing assistant_message render handling"

if grep -Fq "const queuedChatEnabled = !isCompanion && useQueuedChat;" "$FILE"; then
  fail "CT101 ChatPage still blocks companion queued submit"
fi

git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || fail "missing local CT101 Stage 5H-4 tag"
git ls-remote --tags origin "$TAG" | grep -Fq "$TAG" || fail "missing remote CT101 Stage 5H-4 tag"

echo "PASS: CT101 Stage 5H-4 frontend patch and tag verified"
REMOTE

# Re-run the most important companion readiness smokes.
bash ops/smoke/check-stage-5h5-companion-html-error-response-regression-smoke.sh
bash ops/smoke/check-stage-5h4-companion-browser-queued-completion-regression.sh
bash ops/smoke/check-stage-5h3-companion-queued-create-status-lifecycle-smoke.sh
bash ops/smoke/check-stage-5g28-runtime-invariant-smoke.sh

if grep -RInE "LAPTOP_QUEUE_INTERNAL_TOKEN=.*|EDGE_TRUSTED_PROXY_SECRET=.*|EDGE_PUBLIC_API_KEY=.*|Authorization: Bearer|X-Worker-Token:|X-Edge-Auth-Secret: [^<]" "$DOC" >/dev/null 2>&1; then
  fail "doc appears to contain raw secret/token/header value"
fi

pass "Stage 5H-6 companion queued final readiness report smoke passed"
