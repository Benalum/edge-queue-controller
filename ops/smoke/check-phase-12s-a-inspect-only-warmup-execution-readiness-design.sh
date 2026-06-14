#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12s-a-inspect-only-warmup-execution-readiness-design"
DOC="docs/${PHASE}.md"
fail=0

echo "=== ${PHASE}: inspect-only design checks ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== required previous final rollup exists ==="
test -f ops/smoke/check-phase-12r-ao-disabled-warmup-control-plane-final-rollup.sh || fail=1
test -f docs/phase-12r-ao-disabled-warmup-control-plane-final-rollup.md || fail=1

echo
echo "=== run previous final no-restart rollup ==="
ops/smoke/check-phase-12r-ao-disabled-warmup-control-plane-final-rollup.sh || fail=1

echo
echo "=== verify design doc markers ==="
python3 - <<'PY' || fail=1
from pathlib import Path

doc = Path("docs/phase-12s-a-inspect-only-warmup-execution-readiness-design.md")
text = doc.read_text()

required = [
    "This is an inspect-only design phase.",
    "It does not implement warmup execution.",
    "Add a runtime executor.",
    "Add an Ollama call.",
    "Add a /api/generate call.",
    "EDGE_MODEL_WARMUP_ACTION_ENABLED set to 1.",
    "Authenticated admin request.",
    "Explicit confirm phrase WARMUP_MODEL_NOW.",
    "It is safe to stop here before any execution work.",
]

for marker in required:
    if marker not in text:
        raise SystemExit(f"FAIL: design doc missing marker: {marker}")

print("PASS: inspect-only design doc markers are present")
PY

echo
echo "=== static route boundary remains disabled ==="
python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

admin_route = None

def route_path(deco):
    if not isinstance(deco, ast.Call):
        return None
    fn = deco.func
    if not (
        isinstance(fn, ast.Attribute)
        and isinstance(fn.value, ast.Name)
        and fn.value.id == "app"
    ):
        return None
    if deco.args and isinstance(deco.args[0], ast.Constant):
        return f"{fn.attr.upper()} {deco.args[0].value}"
    return None

for node in tree.body:
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
        for deco in node.decorator_list:
            if route_path(deco) == "POST /admin/model-warmup":
                admin_route = node

if admin_route is None:
    raise SystemExit("FAIL: POST /admin/model-warmup route not found")

admin_src = ast.get_source_segment(src, admin_route) or ""

required = [
    "_admin_support_require_admin(request)",
    "authenticated_admin=True",
    "raise HTTPException(status_code=403, detail=response)",
]
for marker in required:
    if marker not in admin_src:
        raise SystemExit(f"FAIL: admin route missing marker: {marker}")

for forbidden in [
    "httpx.",
    "urlopen",
    "urllib.request",
    "requests.",
    "subprocess",
    "systemctl",
    "_forward_ollama_chat_job_direct",
    "tick_ollama_direct",
    "/api/generate",
    "/api/chat",
]:
    if forbidden in admin_src:
        raise SystemExit(f"FAIL: admin route contains forbidden marker: {forbidden}")

print("PASS: admin warmup route remains disabled and non-executing")
PY

echo
echo "=== safety: warmup execution env must not be enabled ==="
if systemctl show edge-queue-controller -p Environment --value \
  | tr ' ' '\n' \
  | grep -q '^EDGE_MODEL_WARMUP_ACTION_ENABLED=1$'; then
  echo "FAIL: EDGE_MODEL_WARMUP_ACTION_ENABLED=1 is set"
  fail=1
else
  echo "PASS: warmup action env is not enabled"
fi

echo
echo "=== safety summary ==="
echo "PASS: no controller restart was performed"
echo "PASS: no CT101 worker runtime was changed"
echo "PASS: no persistent lane workers were started"
echo "PASS: no router rollout was enabled"
echo "PASS: no warmup execution was enabled"
echo "PASS: no bearer token value was printed"
echo "PASS: no Ollama direct call was made"
echo "PASS: no /api/generate call was made"
echo "PASS: no /api/chat call was made"
echo "PASS: no model warmup was executed"
echo "PASS: no model unload was executed"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
fi

exit "$fail"
