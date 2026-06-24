#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$REPO"

PHASE="stage-16-fc-o45-e-r-source-align-companion-auth-no-enqueue-validation"
SRC="edge_controller.py"
DOC="docs/${PHASE}.md"

echo "=== ${PHASE} static smoke ==="

test -s "$SRC"
test -s "$DOC"

grep -q "Source-align Companion Auth No-Enqueue Validation" "$DOC"
grep -q "FC-O45-E-Q" "$DOC"
grep -q "queue_write: false" "$DOC"
grep -q "EDGE_COMPANION_AUTH_VALIDATE_NO_QUEUE_ENABLED" "$DOC"
grep -q "X-APC-Companion-Auth-Validate-Only" "$DOC"

python3 -m py_compile "$SRC"

python3 - <<'PY'
from pathlib import Path
import ast

src = Path("edge_controller.py").read_text(encoding="utf-8")
tree = ast.parse(src)

funcs = {}
routes = []
for node in ast.walk(tree):
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
        body = ast.get_source_segment(src, node) or ""
        funcs[node.name] = body
        decos = [ast.get_source_segment(src, d) or "" for d in node.decorator_list]
        flat = "\n".join(decos)
        if "/api/companion/chat" in flat or "/public/companion/chat" in flat:
            routes.append((node.name, decos, body))

assert "APC_COMPANION_ROUTE_LOCAL_AUTH_FC_O45_E_Q" in src
assert "APC_COMPANION_AUTH_VALIDATE_NO_QUEUE_FC_O45_E_Q" in src
assert "APC_COMPANION_ROUTE_LOCAL_AUTH_FC_O45_E_J" not in src
assert "APC_COMPANION_BEARER_SESSION_AUTH_FC_O45_E_F" not in src

assert "public_companion_chat" in funcs
assert "api_companion_chat" in funcs
assert "_apc_companion_chat_common_fc_o45_e_q" in funcs

public_route = next((r for r in routes if r[0] == "public_companion_chat"), None)
api_route = next((r for r in routes if r[0] == "api_companion_chat"), None)
assert public_route is not None, "missing public wrapper"
assert api_route is not None, "missing api wrapper"

public_decos = "\n".join(public_route[1])
api_decos = "\n".join(api_route[1])
assert "/public/companion/chat" in public_decos
assert "/api/companion/chat" not in public_decos
assert "/api/companion/chat" in api_decos
assert "/public/companion/chat" not in api_decos

assert "require_public_api_key=True" in funcs["public_companion_chat"]
assert "require_public_api_key=False" in funcs["api_companion_chat"]

common = funcs["_apc_companion_chat_common_fc_o45_e_q"]
for required in [
    "if require_public_api_key:",
    "await _require_public_api_key(request)",
    'user_row = _auth_current_user_from_request(request)',
    'request.headers.get("X-APC-Companion-Auth-Validate-Only") == "FC-O45-E-Q"',
    'os.getenv("EDGE_COMPANION_AUTH_VALIDATE_NO_QUEUE_ENABLED"',
    '"queue_write": False',
    '"auth_validated": True',
    '_companion_build_context(user_id)',
    '_public_create_ollama_job(',
]:
    assert required in common, f"missing expected common handler fragment: {required}"

assert common.index('"queue_write": False') < common.index("_companion_build_context(user_id)")
assert common.index("_companion_build_context(user_id)") < common.index("_public_create_ollama_job(")

print("route_no_enqueue_static_checks=PASS")
PY

echo "RESULT=PASS ${PHASE} static smoke"
