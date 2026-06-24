#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$REPO"

PHASE="stage-16-fc-o45-e-p-companion-auth-no-enqueue-validation-plan"
DOC="docs/${PHASE}.md"
SRC="edge_controller.py"

echo "=== ${PHASE} static smoke ==="

test -s "$DOC"
test -s "$SRC"

grep -q "Companion Auth No-Enqueue Validation Plan" "$DOC"
grep -q "/api/companion/chat" "$DOC"
grep -q "/public/companion/chat" "$DOC"
grep -q "public API key guarded" "$DOC"
grep -q "no-enqueue validation mode" "$DOC"
grep -q "queue_write=false" "$DOC"
grep -q "EDGE_COMPANION_AUTH_VALIDATE_NO_QUEUE_ENABLED=1" "$DOC"
grep -q "X-APC-Companion-Auth-Validate-Only" "$DOC"
grep -q "jobs count unchanged" "$DOC"

python3 - <<'PY'
from pathlib import Path
import ast

src = Path("edge_controller.py").read_text(encoding="utf-8")
tree = ast.parse(src)

routes = []
funcs = {}
for node in ast.walk(tree):
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
        funcs[node.name] = ast.get_source_segment(src, node) or ""
        decorators = [ast.get_source_segment(src, d) or "" for d in node.decorator_list]
        flat = "\n".join(decorators)
        if "/api/companion/chat" in flat or "/public/companion/chat" in flat:
            routes.append((node.name, decorators))

assert any("/api/companion/chat" in "\n".join(decos) for _, decos in routes), "missing /api/companion/chat route"
assert any("/public/companion/chat" in "\n".join(decos) for _, decos in routes), "missing /public/companion/chat route"
assert "public_companion_chat" in funcs, "missing current companion handler"

body = funcs["public_companion_chat"]
assert "_require_public_api_key" in body, "current combined handler should still be public API key guarded before implementation"
assert "_auth_current_user_from_request" in body, "current handler should still authenticate bearer session"
assert "Companion response queued" in body, "current behavior still queues; plan must not pretend source is patched"
assert "APC_COMPANION_ROUTE_LOCAL_AUTH_FC_O45_E_J" not in src, "route-split marker should not be in repo source during no-apply plan"

print("route_static_checks=PASS")
PY

echo "RESULT=PASS ${PHASE} static smoke"
