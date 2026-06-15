#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Phase 14I-AI wire disabled router shadow helper into queued-chat ==="

DOC="docs/phase-14i-ai-wire-disabled-router-shadow-helper-into-queued-chat.md"
SMOKE="ops/smoke/check-phase-14i-ai-wire-disabled-router-shadow-helper-into-queued-chat.sh"

echo
echo "=== required files ==="
test -f edge_controller.py
test -f "$DOC"
test -f "$SMOKE"
echo "PASS: required docs/smoke/source files exist"

echo
echo "=== compile and optional frontend syntax ==="
python3 -m py_compile edge_controller.py
for js in public/app.js public/queued_chat_config.js public/queued_chat_status.js; do
  if [ -f "$js" ]; then
    node --check "$js" >/dev/null
  fi
done
echo "PASS: compile/frontend syntax check complete"

echo
echo "=== queued-chat router shadow wiring markers ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

route_start = text.index('@app.post("/api/chat/queued")')
route_end = text.index('@app.get("/api/chat/queued/{job_id}")', route_start)
route = text[route_start:route_end]

required = [
    "# STAGE_14I_AI_QUEUED_CHAT_ROUTER_SHADOW_WIRING_START",
    "_phase14iag_queued_chat_router_shadow_decision(guard_payload)",
    "# STAGE_14I_AI_QUEUED_CHAT_ROUTER_SHADOW_WIRING_END",
    "payload=guard_payload",
    'requested_model=request.requested_model or "synthetic"',
]

for marker in required:
    if marker not in route:
        raise SystemExit(f"FAIL: missing route marker: {marker}")

call = "_phase14iag_queued_chat_router_shadow_decision(guard_payload)"
if route.count(call) != 1:
    raise SystemExit(f"FAIL: expected exactly one queued-chat shadow call, found {route.count(call)}")

auth_marker = "auth_user = _s5g14_trusted_queued_auth_user(trusted_user)"
creation_marker = "if _s5f19_real_user_creation_helper_enabled():"
if route.index(call) <= route.index(auth_marker):
    raise SystemExit("FAIL: shadow call appears before trusted auth fallback resolution")
if route.index(call) >= route.index(creation_marker):
    raise SystemExit("FAIL: shadow call appears after real-user job creation gate")

call_line = [line.strip() for line in route.splitlines() if call in line]
if call_line != [call]:
    raise SystemExit("FAIL: shadow helper return value should be discarded")

browser_exposure_keys = [
    '"router_shadow"',
    "'router_shadow'",
    '"shadow"',
    "'shadow'",
    '"router_decision"',
    "'router_decision'",
    '"shadow_decision"',
    "'shadow_decision'",
]
for key in browser_exposure_keys:
    if key in route:
        raise SystemExit(f"FAIL: browser exposure key found in queued-chat route: {key}")

real_return_marker = 'return {\n                "ok": True,\n                "stage": "5f19"'
synthetic_return_marker = 'return {\n        "ok": True,\n        "stage": "5f9"'

if real_return_marker not in route:
    raise SystemExit("FAIL: real-user queued-chat return shape marker missing")
if synthetic_return_marker not in route:
    raise SystemExit("FAIL: synthetic queued-chat return shape marker missing")

real_return = route[route.index(real_return_marker):route.index("        raise _S5F9_HTTPException(", route.index(real_return_marker))]
synthetic_return = route[route.index(synthetic_return_marker):]

if '"payload_json": queued.payload_json' not in real_return:
    raise SystemExit("FAIL: real-user queued-chat payload_json return field missing")
if '"payload_json": queued.payload_json' not in synthetic_return:
    raise SystemExit("FAIL: synthetic queued-chat payload_json return field missing")

for label, block in [("real-user", real_return), ("synthetic", synthetic_return)]:
    for key in browser_exposure_keys:
        if key in block:
            raise SystemExit(f"FAIL: {label} browser exposure key found in return shape: {key}")

print("PASS: queued-chat shadow hook is wired without live behavior exposure")
PY

echo
echo "=== helper safety text ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED",
    "live_model_selection_changed",
    "model_call_allowed",
    "job_enqueue_allowed",
    "browser_exposure_allowed",
    "persist shadow output",
    "expose router internals to the browser",
]

for marker in required:
    if marker not in text:
        raise SystemExit(f"FAIL: missing helper safety marker: {marker}")

print("PASS: helper safety markers verified")
PY

echo
echo "=== documentation markers ==="
grep -q "returned shadow decision is intentionally discarded" "$DOC"
grep -q "Default behavior remains unchanged" "$DOC"
grep -q "Live model selection remains unchanged" "$DOC"
grep -q "No shadow output is returned to the browser" "$DOC"
grep -q "No shadow output is persisted" "$DOC"
grep -q "No model calls are made by smoke tests" "$DOC"
echo "PASS: required documentation markers found"

echo
echo "=== read-only/privacy guard for this smoke script ==="
python3 - <<'INNERPY'
from pathlib import Path

path = Path("ops/smoke/check-phase-14i-ai-wire-disabled-router-shadow-helper-into-queued-chat.sh")
text = path.read_text()

guard_marker = 'echo "=== read-only/privacy guard for this smoke script ==="'
scan_text = text.split(guard_marker, 1)[0]

forbidden_terms = [
    "curl",
    "wget",
    "http://",
    "https://",
    "ollama",
    "/api/generate",
    "/api/chat/completions",
    "X-Edge-Auth-Secret",
    "cookie",
    "Authorization:",
]

for term in forbidden_terms:
    if term in scan_text:
        raise SystemExit(f"FAIL: smoke script contains forbidden live-call or secret marker before guard: {term}")

print("PASS: read-only/privacy guard passed")
INNERPY

echo
echo "=== done: Phase 14I-AI queued-chat router shadow wiring smoke complete ==="
