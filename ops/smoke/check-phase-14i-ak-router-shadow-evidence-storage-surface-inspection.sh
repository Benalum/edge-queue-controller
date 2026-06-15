#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Phase 14I-AK router shadow evidence storage surface inspection ==="

DOC="docs/phase-14i-ak-router-shadow-evidence-storage-surface-inspection.md"
SMOKE="ops/smoke/check-phase-14i-ak-router-shadow-evidence-storage-surface-inspection.sh"
AI_SMOKE="ops/smoke/check-phase-14i-ai-wire-disabled-router-shadow-helper-into-queued-chat.sh"
AJ_SMOKE="ops/smoke/check-phase-14i-aj-router-shadow-contract-validation-and-evidence-plan.sh"

echo
echo "=== required files ==="
test -f edge_controller.py
test -f "$DOC"
test -f "$SMOKE"
test -f "$AI_SMOKE"
test -f "$AJ_SMOKE"
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
echo "=== queued-chat no-persistence contract ==="
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
    "router_shadow_evidence",
    "shadow_evidence",
    "persist_shadow",
    "insert_router_shadow",
    "record_router_shadow",
    "shadow_payload_json",
    "router_shadow_json",
    "CREATE TABLE",
    "INSERT INTO",
]

for marker in forbidden_route_markers:
    if marker in route:
        raise SystemExit(f"FAIL: queued-chat route contains forbidden evidence persistence marker: {marker}")

print("PASS: queued-chat route still has no router shadow evidence persistence")
PY

echo
echo "=== no new runtime/schema implementation markers ==="
python3 - <<'PY'
from pathlib import Path

source_paths = [Path("edge_controller.py")]
for directory in ["ops/db", "ops/stage"]:
    d = Path(directory)
    if d.exists():
        source_paths.extend(sorted(p for p in d.rglob("*") if p.is_file()))

forbidden_new_markers = [
    "queued_chat_router_shadow_evidence",
    "router_shadow_evidence_table",
    "insert_router_shadow_evidence",
    "record_router_shadow_evidence",
    "persist_router_shadow_evidence",
]

for path in source_paths:
    try:
        text = path.read_text(errors="replace")
    except Exception:
        continue

    for marker in forbidden_new_markers:
        if marker in text:
            raise SystemExit(f"FAIL: runtime/schema evidence marker found in {path}: {marker}")

print("PASS: no runtime/schema router shadow evidence implementation markers found")
PY

echo
echo "=== documentation markers ==="
grep -q "Do not persist queued-chat router shadow evidence yet" "$DOC"
grep -q "This phase does not patch runtime code" "$DOC"
grep -q "dedicated, narrow table or artifact schema" "$DOC"
grep -q "full job payload" "$DOC"
grep -q "full \`payload_json\`" "$DOC"
grep -q "No live model endpoints are called by smoke tests" "$DOC"
echo "PASS: required documentation markers found"

echo
echo "=== read-only/privacy guard for this smoke script ==="
python3 - <<'PY'
from pathlib import Path

path = Path("ops/smoke/check-phase-14i-ak-router-shadow-evidence-storage-surface-inspection.sh")
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
echo "=== done: Phase 14I-AK router shadow evidence storage surface inspection smoke complete ==="
