#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-i-route-local-companion-auth-fix-plan.md"
FAILED_PATCH="docs/failed-patches/fc-o45-e-f-failed-companion-bearer-session-auth.patch"
FAILED_NOTES="docs/failed-patches/fc-o45-e-f-failed-companion-bearer-session-auth-notes.md"

test -s "$DOC"
test -s "$FAILED_PATCH"
test -s "$FAILED_NOTES"

grep -q "Route-local Companion auth fix plan" "$DOC"
grep -q "Do not modify the global public API key guard" "$DOC"
grep -q "/public/companion/chat" "$DOC"
grep -q "/api/companion/chat" "$DOC"
grep -q "No browser public API key injection" "$DOC"
grep -q "No model runtime call" "$DOC"
grep -q "No scheduler/timer activation" "$DOC"

python3 -m py_compile edge_controller.py

if grep -q 'APC_COMPANION_BEARER_SESSION_AUTH_FC_O45_E_F' edge_controller.py; then
  echo "FAIL: failed E-F marker is present in live source"
  exit 1
fi

python3 - <<'PY'
from pathlib import Path
import ast

src = Path("edge_controller.py").read_text(encoding="utf-8")
tree = ast.parse(src)

route_hits = []
for node in ast.walk(tree):
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
        decorators = [ast.get_source_segment(src, d) or "" for d in node.decorator_list]
        if any("/api/companion/chat" in d or "/public/companion/chat" in d for d in decorators):
            route_hits.append((node.name, decorators))

if not route_hits:
    raise SystemExit("FAIL: companion chat route not found")

flat = "\n".join("\n".join(d for d in decs) for _, decs in route_hits)
if "/api/companion/chat" not in flat:
    raise SystemExit("FAIL: /api/companion/chat route not found")
if "/public/companion/chat" not in flat:
    raise SystemExit("FAIL: /public/companion/chat route not found")

print("companion_route_handlers=" + repr(route_hits))
print("static_source_gate=PASS")
PY

echo "RESULT=PASS stage-16-fc-o45-e-i-route-local-companion-auth-fix-plan"
