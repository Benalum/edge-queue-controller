#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-5h2-companion-queued-route-ownership.md"
CONTROLLER="edge_controller.py"
WRAPPER="frontend/wrapper-ui/dev_server.py"
GUARD="edge_modules/chat_queue_real_user_guard.py"
CREATION="edge_modules/chat_queue_real_user_creation.py"
CONFIG="frontend/wrapper-ui/queued_chat_config.js"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

pass() {
  echo "PASS: $*"
}

[[ -f "$DOC" ]] || fail "missing $DOC"
[[ -f "$CONTROLLER" ]] || fail "missing $CONTROLLER"
[[ -f "$WRAPPER" ]] || fail "missing $WRAPPER"
[[ -f "$GUARD" ]] || fail "missing $GUARD"
[[ -f "$CREATION" ]] || fail "missing $CREATION"
[[ -f "$CONFIG" ]] || fail "missing $CONFIG"

grep -Fq "Stage 5H-2" "$DOC" || fail "doc missing Stage 5H-2 title"
grep -Fq "does not make queued chat globally default-on" "$DOC" || fail "doc missing default-off invariant"
grep -Fq "does not increase worker concurrency" "$DOC" || fail "doc missing concurrency invariant"
grep -Fq 'does not accept client-provided `user_id`' "$DOC" || fail "doc missing user_id invariant"
grep -Fq "CT101 frontend companion queue is not enabled" "$DOC" || fail "doc missing frontend-not-enabled invariant"

grep -Fq "STAGE_5H2_COMPANION_MODE_OWNERSHIP_V1" "$CONTROLLER" || fail "controller missing Stage 5H-2 marker"
grep -Fq "mode: str | None = None" "$CONTROLLER" || fail "controller request model missing optional mode"
grep -Fq 'clean_mode not in {"chat", "companion"}' "$CONTROLLER" || fail "controller missing mode allowlist"
grep -Fq 'mode=guard_payload.get("mode")' "$CONTROLLER" || fail "controller mirror call missing mode propagation"
grep -Fq "mode = EXCLUDED.mode" "$CONTROLLER" || fail "controller mirror upsert does not preserve mode"

grep -Fq "declared_mode" "$WRAPPER" || fail "wrapper missing declared_mode"
grep -Fq 'declared_mode in {"chat", "companion"}' "$WRAPPER" || fail "wrapper missing mode allowlist"
grep -Fq 'laptop_payload["mode"] = declared_mode' "$WRAPPER" || fail "wrapper does not forward mode"

grep -Fq "mode must be chat or companion" "$GUARD" || fail "guard missing mode validation"
grep -Fq 'mode: str = "chat"' "$GUARD" || fail "guard result missing mode field"
grep -Fq '"mode": validated.mode' "$CREATION" || fail "creation helper payload does not preserve mode"
grep -Fq "Stage 5H-2 Queued Companion" "$CREATION" || fail "creation helper missing companion title"

grep -Fq "enabled: false" "$CONFIG" || fail "queued chat browser config no longer default-off"
grep -Fq "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" "$CONFIG" || fail "global queued chat flag no longer default-off"

if grep -RInE "LAPTOP_QUEUE_INTERNAL_TOKEN=.*|EDGE_TRUSTED_PROXY_SECRET=.*|EDGE_PUBLIC_API_KEY=.*|Authorization: Bearer|X-Worker-Token:|X-Edge-Auth-Secret: [^<]" "$DOC" "$CONTROLLER" "$WRAPPER" "$GUARD" "$CREATION" >/dev/null 2>&1; then
  fail "raw secret/token/header value appears in Stage 5H-2 files"
fi

python3 -m py_compile "$CONTROLLER" "$WRAPPER" "$GUARD" "$CREATION"

pass "Stage 5H-2 mode-aware queued ownership markers verified"
pass "Stage 5H-2 syntax check passed"
