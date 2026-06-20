#!/usr/bin/env bash
set -euo pipefail
set +H

CONTRACT="edge_model_worker_contract.py"
DOC="docs/stage-16-c-default-off-model-worker-contract.md"

echo "=== Stage 16-C smoke ==="

test -f "$CONTRACT"
test -f "$DOC"

require_text() {
  file="$1"
  needle="$2"
  if grep -F -- "$needle" "$file" >/dev/null 2>&1; then
    echo "PASS: found text in $file: $needle"
  else
    echo "FAIL: missing text in $file: $needle"
    exit 1
  fi
}

require_text "$CONTRACT" "STAGE16_ENABLE_ENV"
require_text "$CONTRACT" "EDGE_STAGE16_MODEL_WORKER_ENABLED"
require_text "$CONTRACT" "EDGE_STAGE16_MODEL_WORKER_CONFIRM"
require_text "$CONTRACT" "APPROVE_STAGE_16_D_ONE_CONTROLLED_QUEUE_MODEL_TEST"
require_text "$CONTRACT" "STAGE16_DEFAULT_JOB_TYPE = \"companion.chat\""
require_text "$CONTRACT" "STAGE16_DEFAULT_MODEL = \"qwen2.5:0.5b\""
require_text "$CONTRACT" "direct_ollama_blocked=True"
require_text "$CONTRACT" "scheduler_broad_activation_allowed=False"
require_text "$CONTRACT" "worker_persistent_enable_allowed=False"
require_text "$CONTRACT" "It performs no network activity."

require_text "$DOC" "Default-Off Model Worker Contract"
require_text "$DOC" "It does not deploy this helper to CT203."
require_text "$DOC" "It does not wire this helper into the live controller."
require_text "$DOC" "Users must never talk directly to models."
require_text "$DOC" "Direct /tick/ollama-direct remains blocked for this rollout path."
require_text "$DOC" "No DB write."
require_text "$DOC" "No worker activation."
require_text "$DOC" "No scheduler activation."
require_text "$DOC" "No Ollama endpoint calls."

python3 -m py_compile "$CONTRACT"
echo "PASS: python compile"

python3 - <<'PY'
import ast
from pathlib import Path

path = Path("edge_model_worker_contract.py")
tree = ast.parse(path.read_text(encoding="utf-8"))

blocked_import_roots = {"requests", "httpx", "urllib", "subprocess", "socket", "sqlite3"}
blocked_calls = {"open", "exec", "eval", "__import__"}

for node in ast.walk(tree):
    if isinstance(node, ast.Import):
        for alias in node.names:
            root = alias.name.split(".", 1)[0]
            if root in blocked_import_roots:
                raise SystemExit(f"FAIL: blocked import {alias.name}")
    if isinstance(node, ast.ImportFrom):
        root = (node.module or "").split(".", 1)[0]
        if root in blocked_import_roots:
            raise SystemExit(f"FAIL: blocked import-from {node.module}")
    if isinstance(node, ast.Call):
        func = node.func
        name = ""
        if isinstance(func, ast.Name):
            name = func.id
        elif isinstance(func, ast.Attribute):
            name = func.attr
        if name in blocked_calls:
            raise SystemExit(f"FAIL: blocked call {name}")

print("PASS: AST no runtime/IO imports or calls")
PY

python3 - <<'PY'
import edge_model_worker_contract as c

assert c.stage16_model_worker_enabled({}) is False
assert c.stage16_disabled_reason({}) == "enable_flag_not_set"

env_enable_only = {c.STAGE16_ENABLE_ENV: "true"}
assert c.stage16_model_worker_enabled(env_enable_only) is False
assert c.stage16_disabled_reason(env_enable_only) == "confirmation_phrase_missing_or_mismatched"

env_confirmed = {
    c.STAGE16_ENABLE_ENV: "true",
    c.STAGE16_CONFIRM_ENV: c.STAGE16_REQUIRED_CONFIRMATION,
}
assert c.stage16_model_worker_enabled(env_confirmed) is True

contract = c.stage16_contract({})
assert contract["enabled"] is False
assert contract["job_type"] == "companion.chat"
assert contract["model_name"] == "qwen2.5:0.5b"
assert contract["queue_owned_only"] is True
assert contract["direct_ollama_blocked"] is True
assert contract["scheduler_broad_activation_allowed"] is False
assert contract["worker_persistent_enable_allowed"] is False
assert contract["private_storage_required"] is False
assert contract["ct204_required"] is False

good_job = {"job_id": 25, "job_type": "companion.chat", "requested_model": "qwen2.5:0.5b"}
bad_job = {"job_id": 24, "job_type": "companion.chat", "requested_model": "mock/no-model"}

assert c.stage16_validate_candidate_job(good_job)["ok"] is True
bad = c.stage16_validate_candidate_job(bad_job)
assert bad["ok"] is False
assert "mock_model_not_real_model_test" in bad["errors"]

delta = c.stage16_expected_activation_delta()
assert delta == {
    "jobs": 1,
    "job_results": 1,
    "router_logs": 0,
    "router_resolution_steps": 0,
    "router_feedback": 0,
}

print("PASS: contract behavior")
PY

echo "PASS_STAGE_16_C_SMOKE"
