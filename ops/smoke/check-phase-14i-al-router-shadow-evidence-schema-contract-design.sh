#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Phase 14I-AL router shadow evidence schema contract design ==="

DOC="docs/phase-14i-al-router-shadow-evidence-schema-contract-design.md"
SMOKE="ops/smoke/check-phase-14i-al-router-shadow-evidence-schema-contract-design.sh"
AI_SMOKE="ops/smoke/check-phase-14i-ai-wire-disabled-router-shadow-helper-into-queued-chat.sh"
AJ_SMOKE="ops/smoke/check-phase-14i-aj-router-shadow-contract-validation-and-evidence-plan.sh"
AK_SMOKE="ops/smoke/check-phase-14i-ak-router-shadow-evidence-storage-surface-inspection.sh"

echo
echo "=== required files ==="
test -f edge_controller.py
test -f "$DOC"
test -f "$SMOKE"
test -f "$AI_SMOKE"
test -f "$AJ_SMOKE"
test -f "$AK_SMOKE"
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
echo "=== queued-chat route still has no evidence persistence ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

route_start = text.index('@app.post("/api/chat/queued")')
route_end = text.index('@app.get("/api/chat/queued/{job_id}")', route_start)
route = text[route_start:route_end]

required_route_markers = [
    "_phase14iag_queued_chat_router_shadow_decision(guard_payload)",
    "payload=guard_payload",
    'requested_model=request.requested_model or "synthetic"',
]

for marker in required_route_markers:
    if marker not in route:
        raise SystemExit(f"FAIL: missing queued-chat route marker: {marker}")

forbidden_route_markers = [
    "queued_chat_router_shadow_evidence",
    "router_shadow_evidence",
    "shadow_evidence",
    "persist_shadow",
    "insert_router_shadow",
    "record_router_shadow",
    "shadow_payload_json",
    "router_shadow_json",
    "EDGE_QUEUED_CHAT_ROUTER_SHADOW_EVIDENCE_ENABLED",
    "CREATE TABLE",
    "INSERT INTO",
]

for marker in forbidden_route_markers:
    if marker in route:
        raise SystemExit(f"FAIL: queued-chat route contains forbidden schema/persistence marker: {marker}")

print("PASS: queued-chat route still has no evidence schema or persistence")
PY

echo
echo "=== no runtime/schema implementation introduced ==="
python3 - <<'PY'
from pathlib import Path

source_paths = [Path("edge_controller.py")]

for directory in ["ops/db", "ops/stage"]:
    d = Path(directory)
    if d.exists():
        source_paths.extend(sorted(p for p in d.rglob("*") if p.is_file()))

forbidden_markers = [
    "queued_chat_router_shadow_evidence",
    "EDGE_QUEUED_CHAT_ROUTER_SHADOW_EVIDENCE_ENABLED",
    "insert_router_shadow_evidence",
    "record_router_shadow_evidence",
    "persist_router_shadow_evidence",
    "router_shadow_evidence_table",
]

for path in source_paths:
    try:
        text = path.read_text(errors="replace")
    except Exception:
        continue

    for marker in forbidden_markers:
        if marker in text:
            raise SystemExit(f"FAIL: runtime/schema implementation marker found in {path}: {marker}")

print("PASS: no runtime/schema implementation markers found outside docs/smoke")
PY

echo
echo "=== schema contract documentation markers ==="
grep -q "Candidate Future Table Name" "$DOC"
grep -q "queued_chat_router_shadow_evidence" "$DOC"
grep -q "Candidate Future Columns" "$DOC"
grep -q "EDGE_QUEUED_CHAT_ROUTER_SHADOW_EVIDENCE_ENABLED" "$DOC"
grep -q "separate from" "$DOC"
grep -q "Phase 14I-AL does not create this table" "$DOC"
grep -q "This phase does not patch runtime code or database scripts" "$DOC"
grep -q 'full `payload_json`' "$DOC"
grep -q "raw prompt" "$DOC"
grep -q "raw user message" "$DOC"
grep -q "auth headers" "$DOC"
grep -q "session tokens" "$DOC"
grep -q "shared secrets" "$DOC"
grep -q "model output" "$DOC"
grep -q "No live model endpoints are called by smoke tests" "$DOC"
echo "PASS: required schema contract documentation markers found"

echo
echo "=== candidate allowlist/blocked field sanity ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14i-al-router-shadow-evidence-schema-contract-design.md").read_text()

allowed_required = [
    "created_at",
    "schema_version",
    "redaction_version",
    "route_name",
    "feature_flag_enabled",
    "shadow_decision_executed",
    "confidence_bucket",
    "reason_code",
    "live_model_selection_changed",
    "model_call_allowed",
    "job_enqueue_allowed",
    "browser_exposure_allowed",
    "retention_class",
]

blocked_required = [
    "raw prompt",
    "raw user message",
    "raw context",
    "raw request body",
    "raw queue summary",
    "full job payload",
    "full `payload_json`",
    "cookies",
    "bearer tokens",
    "auth headers",
    "session tokens",
    "shared secrets",
    "model output",
]

for marker in allowed_required:
    if marker not in doc:
        raise SystemExit(f"FAIL: allowed schema field missing from doc: {marker}")

for marker in blocked_required:
    if marker not in doc:
        raise SystemExit(f"FAIL: blocked schema field missing from doc: {marker}")

print("PASS: schema contract allowlist and blocked-field sanity passed")
PY

echo
echo "=== read-only/privacy guard for this smoke script ==="
python3 - <<'PY'
from pathlib import Path

path = Path("ops/smoke/check-phase-14i-al-router-shadow-evidence-schema-contract-design.sh")
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
echo "=== done: Phase 14I-AL router shadow evidence schema contract design smoke complete ==="
