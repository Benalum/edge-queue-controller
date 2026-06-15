#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Phase 14I-AJ router shadow contract validation and evidence plan ==="

DOC="docs/phase-14i-aj-router-shadow-contract-validation-and-evidence-plan.md"
SMOKE="ops/smoke/check-phase-14i-aj-router-shadow-contract-validation-and-evidence-plan.sh"
AI_DOC="docs/phase-14i-ai-wire-disabled-router-shadow-helper-into-queued-chat.md"
AI_SMOKE="ops/smoke/check-phase-14i-ai-wire-disabled-router-shadow-helper-into-queued-chat.sh"

echo
echo "=== required files ==="
test -f edge_controller.py
test -f "$DOC"
test -f "$SMOKE"
test -f "$AI_DOC"
test -f "$AI_SMOKE"
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
echo "=== post-AI queued-chat shadow contract ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

route_start = text.index('@app.post("/api/chat/queued")')
route_end = text.index('@app.get("/api/chat/queued/{job_id}")', route_start)
route = text[route_start:route_end]

helper_start = text.index("def _phase14iag_queued_chat_router_shadow_enabled")
helper_end = text.index("@app.get", helper_start) if "@app.get" in text[helper_start:] else len(text)
helper_region = text[helper_start:helper_end]

call = "_phase14iag_queued_chat_router_shadow_decision(guard_payload)"

required_route_markers = [
    "# STAGE_14I_AI_QUEUED_CHAT_ROUTER_SHADOW_WIRING_START",
    call,
    "# STAGE_14I_AI_QUEUED_CHAT_ROUTER_SHADOW_WIRING_END",
    "payload=guard_payload",
    'requested_model=request.requested_model or "synthetic"',
]

for marker in required_route_markers:
    if marker not in route:
        raise SystemExit(f"FAIL: missing queued-chat route contract marker: {marker}")

if route.count(call) != 1:
    raise SystemExit(f"FAIL: expected exactly one queued-chat shadow call, found {route.count(call)}")

call_line = [line.strip() for line in route.splitlines() if call in line]
if call_line != [call]:
    raise SystemExit("FAIL: shadow helper return value must be discarded")

call_idx = route.index(call)
creation_idx = route.index("if _s5f19_real_user_creation_helper_enabled():")

if route.rfind("auth_user =", 0, call_idx) == -1:
    raise SystemExit("FAIL: shadow call appears before auth resolution")
if call_idx >= creation_idx:
    raise SystemExit("FAIL: shadow call appears after real-user job creation gate")

required_helper_markers = [
    'return _phase14ik_env_bool("EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED", False)',
    "live_model_selection_changed",
    "model_call_allowed",
    "job_enqueue_allowed",
    "browser_exposure_allowed",
]

for marker in required_helper_markers:
    if marker not in helper_region:
        raise SystemExit(f"FAIL: missing helper default-off/safety marker: {marker}")

forbidden_route_keys = [
    '"router_shadow"',
    "'router_shadow'",
    '"router_decision"',
    "'router_decision'",
    '"shadow_decision"',
    "'shadow_decision'",
]

for key in forbidden_route_keys:
    if key in route:
        raise SystemExit(f"FAIL: queued-chat route exposes forbidden router key: {key}")

print("PASS: post-AI queued-chat shadow contract remains intact")
PY

echo
echo "=== evidence remains plan-only ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

route_start = text.index('@app.post("/api/chat/queued")')
route_end = text.index('@app.get("/api/chat/queued/{job_id}")', route_start)
route = text[route_start:route_end]

forbidden_runtime_markers = [
    "router_shadow_evidence",
    "shadow_evidence",
    "persist_shadow",
    "insert_router_shadow",
    "record_router_shadow",
    "shadow_payload_json",
    "router_shadow_json",
]

for marker in forbidden_runtime_markers:
    if marker in route:
        raise SystemExit(f"FAIL: evidence persistence marker found in queued-chat route: {marker}")

print("PASS: no queued-chat shadow evidence persistence implementation found")
PY

echo
echo "=== documentation markers ==="
grep -q "Evidence Collection Plan" "$DOC"
grep -q "This phase does not patch runtime code" "$DOC"
grep -q "raw prompt" "$DOC"
grep -q "cookies" "$DOC"
grep -q "auth headers" "$DOC"
grep -q "full job payload" "$DOC"
grep -q "shadow helper call exists exactly once" "$DOC"
grep -q "helper return value is intentionally discarded" "$DOC"
grep -q "No live model endpoints are called by smoke tests" "$DOC"
echo "PASS: required documentation markers found"

echo
echo "=== read-only/privacy guard for this smoke script ==="
python3 - <<'PY'
from pathlib import Path

path = Path("ops/smoke/check-phase-14i-aj-router-shadow-contract-validation-and-evidence-plan.sh")
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
    "Authorization:",
]

for term in forbidden_terms:
    if term in scan_text:
        raise SystemExit(f"FAIL: smoke script contains forbidden live-call or secret marker before guard: {term}")

print("PASS: read-only/privacy guard passed")
PY

echo
echo "=== done: Phase 14I-AJ router shadow contract validation and evidence plan smoke complete ==="
