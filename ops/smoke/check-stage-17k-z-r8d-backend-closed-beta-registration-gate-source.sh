#!/usr/bin/env bash
set -euo pipefail

SRC="edge_controller.py"
DOC="docs/stage-17k-z-r8d-backend-closed-beta-registration-gate-source.md"
CONTRACT="docs/generated/stage-17k-z-r8d-backend-closed-beta-registration-gate-source.json"

echo "=== Stage 17K-Z-R8D backend closed beta registration gate source smoke ==="

test -f "$SRC"
test -f "$DOC"
test -f "$CONTRACT"

grep -Fq "APC_CLOSED_BETA_SIGNUP_DISABLED_STAGE_17K_Z_R8D" "$SRC"
grep -Fq "APC_CLOSED_BETA_SIGNUP_MESSAGE_STAGE_17K_Z_R8D" "$SRC"
grep -Fq "closed_beta_signup_disabled" "$SRC"
grep -Fq "Buddies Who Study" "$SRC"
grep -Fq "buddieswhostudy.com" "$SRC"
grep -Fq '@app.post("/public/auth/register")' "$SRC"
grep -Fq 'async def public_auth_register' "$SRC"
grep -Fq '@app.post("/system/session/register")' "$SRC"
grep -Fq 'async def system_session_register' "$SRC"
grep -Fq '@app.post("/public/auth/login")' "$SRC"

python3 -m py_compile "$SRC"

python3 - <<'PYSMOKE'
import ast
import json
from pathlib import Path

src = Path("edge_controller.py").read_text(encoding="utf-8")
tree = ast.parse(src)

functions = {node.name: node for node in tree.body if isinstance(node, ast.FunctionDef) or isinstance(node, ast.AsyncFunctionDef)}

assert "_closed_beta_signup_disabled_response" in functions
assert "public_auth_register" in functions
assert "system_session_register" in functions
assert "public_auth_login" in functions

def contains_call(fn_name, call_name):
    fn = functions[fn_name]
    for node in ast.walk(fn):
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and node.func.id == call_name:
            return True
    return False

assert contains_call("public_auth_register", "_closed_beta_signup_disabled_response")
assert contains_call("system_session_register", "_closed_beta_signup_disabled_response")
assert not contains_call("public_auth_login", "_closed_beta_signup_disabled_response")

contract = json.loads(Path("docs/generated/stage-17k-z-r8d-backend-closed-beta-registration-gate-source.json").read_text())
assert contract["stage"] == "17K-Z-R8D"
assert contract["product_domain"] == "buddieswhostudy.com"
assert contract["public_signup_enabled"] is False
assert contract["existing_user_signin_enabled"] is True
assert "/public/auth/register" in contract["gated_routes"]
assert "/system/session/register" in contract["gated_routes"]
assert "/public/auth/login" in contract["preserved_routes"]
assert contract["refusal"]["status_code"] == 403
assert contract["refusal"]["code"] == "closed_beta_signup_disabled"
assert contract["not_performed"]["deploy"] is True

print("ast_and_contract_ok")
PYSMOKE

echo "PASS Stage 17K-Z-R8D backend closed beta registration gate source smoke"
