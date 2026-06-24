#!/usr/bin/env python3
import ast
import importlib.util
from pathlib import Path
import sys
from types import SimpleNamespace

path = Path("ops/workers/ct101_minimal_ollama_worker.py")
source = path.read_text()
tree = ast.parse(source)

assert "def fail_job(" in source
assert "except WorkerRefusal as exc:" in source
assert "fail_job(config, token, job_id, str(exc))" in source
assert "complete_job(config, token, job_id, profile, claimed, response)" in source
assert "complete_job(config, token, job_id, profile, job, response)" not in source

run_func = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == "run_one_claim_complete")
try_nodes = [n for n in ast.walk(run_func) if isinstance(n, ast.Try)]
assert try_nodes, "expected try/except around validate_completion"

matching = []
for node in try_nodes:
    validate_calls = [
        n for n in ast.walk(ast.Module(body=node.body, type_ignores=[]))
        if isinstance(n, ast.Call) and isinstance(n.func, ast.Name) and n.func.id == "validate_completion"
    ]
    if not validate_calls:
        continue
    for h in node.handlers:
        htype = ast.unparse(h.type) if h.type is not None else ""
        if htype != "WorkerRefusal":
            continue
        fail_calls = [
            n for n in ast.walk(ast.Module(body=h.body, type_ignores=[]))
            if isinstance(n, ast.Call) and isinstance(n.func, ast.Name) and n.func.id == "fail_job"
        ]
        returns = [
            n for n in ast.walk(ast.Module(body=h.body, type_ignores=[]))
            if isinstance(n, ast.Return)
        ]
        if fail_calls and any(isinstance(r.value, ast.Constant) and r.value.value == 1 for r in returns):
            args = [ast.unparse(a) for a in fail_calls[0].args]
            assert args == ["config", "token", "job_id", "str(exc)"], args
            matching.append(node)

assert len(matching) == 1, f"expected one validation refusal fail path, got {len(matching)}"

spec = importlib.util.spec_from_file_location("ct101_minimal_ollama_worker_fc_o43_d_r2", path)
if spec is None or spec.loader is None:
    raise SystemExit("failed import spec")
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod
spec.loader.exec_module(mod)

captured = {}
def fake_post_json(config, token, endpoint, payload):
    captured["config"] = config
    captured["token"] = token
    captured["endpoint"] = endpoint
    captured["payload"] = payload
    return 200, {"ok": True}

mod._post_json = fake_post_json

config = SimpleNamespace(worker_id="fc-o43-d-r2-test-worker", allowed_job_ids=(117,))
mod.fail_job(config, "token", 117, "REFUSE_PRODUCT_VISIBLE_THINKING")

assert captured["endpoint"].endswith("/internal/edge-worker/jobs/117/fail"), captured["endpoint"]
assert captured["payload"]["worker_id"] == "fc-o43-d-r2-test-worker"
assert captured["payload"]["error"] == "REFUSE_PRODUCT_VISIBLE_THINKING"

try:
    mod.fail_job(config, "token", 999, "REFUSE_PRODUCT_VISIBLE_THINKING")
except Exception as exc:
    assert "REFUSE_WORKER_CLAIMED_JOB_ID_NOT_ALLOWED" in str(exc), str(exc)
else:
    raise AssertionError("expected allowed-job-id refusal")

print("stage-16-fc-o43-d-r2 validation refusal fail-path smoke passed")
