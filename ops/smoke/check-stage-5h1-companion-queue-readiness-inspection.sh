#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-5h1-companion-queue-readiness-inspection.md"
WRAPPER="frontend/wrapper-ui/dev_server.py"
CONTROLLER="edge_controller.py"
REAL_USER_HELPER="edge_modules/chat_queue_real_user_creation.py"
GUARD_HELPER="edge_modules/chat_queue_real_user_guard.py"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

pass() {
  echo "PASS: $*"
}

[[ -f "$DOC" ]] || fail "missing $DOC"
[[ -f "$WRAPPER" ]] || fail "missing $WRAPPER"
[[ -f "$CONTROLLER" ]] || fail "missing $CONTROLLER"
[[ -f "$REAL_USER_HELPER" ]] || fail "missing $REAL_USER_HELPER"
[[ -f "$GUARD_HELPER" ]] || fail "missing $GUARD_HELPER"

grep -Fq "Stage 5H-1" "$DOC" || fail "doc missing stage title"
grep -Fq "No runtime code is changed" "$DOC" || fail "doc missing no-runtime-change statement"
grep -Fq "CT101 backend currently blocks queued companion directly" "$DOC" || fail "doc missing CT101 queued companion blocker"
grep -Fq "frontend currently disables queue mode for companion" "$DOC" || fail "doc missing frontend companion queue blocker"
grep -Fq "Wrapper bridge already transforms queued jobs into CT101-compatible shape" "$DOC" || fail "doc missing wrapper assistant_message shape finding"
grep -Fq "Current wrapper bridge is URL-compatible but not companion-aware" "$DOC" || fail "doc missing mode propagation concern"
grep -Fq "mirror currently writes bridged chats as normal chat" "$DOC" || fail "doc missing laptop mirror mode finding"
grep -Fq "should not simply flip" "$DOC" || fail "doc missing Stage 5H-2 safety warning"
grep -Fq "Do not accept client-provided user_id" "$DOC" || fail "doc missing user_id constraint"

grep -Fq "WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED" "$WRAPPER" || fail "wrapper missing queued bridge env gate"
grep -Fq "STAGE_5G9_CT101_QUEUED_CHAT_BRIDGE_V1" "$WRAPPER" || fail "wrapper missing Stage 5G9 bridge marker"
grep -Fq "/api/backend/chats/([^/]+)/messages/queued" "$WRAPPER" || fail "wrapper missing queued create bridge regex"
grep -Fq "/api/backend/chats/([^/]+)/messages/jobs/([^/]+)" "$WRAPPER" || fail "wrapper missing queued status bridge regex"
grep -Fq "/api/chat/queued" "$WRAPPER" || fail "wrapper missing controller queued create mapping"
grep -Fq "/api/chat/queued/{job_id}" "$CONTROLLER" || fail "controller missing queued status route"
grep -Fq "assistant_message" "$WRAPPER" || fail "wrapper missing assistant_message transform"

grep -Fq "STAGE_5G14_TRUSTED_CT101_IDENTITY_BRIDGE_V1" "$CONTROLLER" || fail "controller missing trusted CT101 identity bridge marker"
grep -Fq "client-provided user_id is refused" "$GUARD_HELPER" || fail "guard helper missing client user_id refusal"
grep -Fq "payload_json" "$REAL_USER_HELPER" || fail "real-user helper missing payload_json creation"

if grep -RInE "LAPTOP_QUEUE_INTERNAL_TOKEN=.*|EDGE_TRUSTED_PROXY_SECRET=.*|EDGE_PUBLIC_API_KEY=.*|Authorization: Bearer|X-Worker-Token:|X-Edge-Auth-Secret: [^<]" "$DOC" >/dev/null 2>&1; then
  fail "doc appears to contain a raw secret/token/header value"
fi

pass "Stage 5H-1 inspection doc exists and captures companion queued-readiness findings"
pass "Stage 5H-1 smoke verified wrapper/controller/helper markers without runtime changes"
