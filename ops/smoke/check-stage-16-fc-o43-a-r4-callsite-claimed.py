#!/usr/bin/env python3
import ast
from pathlib import Path

path = Path("ops/workers/ct101_minimal_ollama_worker.py")
source = path.read_text()
tree = ast.parse(source)

run_func = None
for node in tree.body:
    if isinstance(node, ast.FunctionDef) and node.name == "run_one_claim_complete":
        run_func = node
        break

assert run_func is not None, "run_one_claim_complete missing"

calls = []
for node in ast.walk(run_func):
    if isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and node.func.id == "complete_job":
        calls.append(node)

assert len(calls) == 1, f"expected one complete_job call in run_one_claim_complete, got {len(calls)}"
call = calls[0]
args = []
for arg in call.args:
    if isinstance(arg, ast.Name):
        args.append(arg.id)
    else:
        args.append(ast.unparse(arg))

assert args == ["config", "token", "job_id", "profile", "claimed", "response"], args
assert "complete_job(config, token, job_id, profile, job, response)" not in source
assert "complete_job(config, token, job_id, profile, claimed, response)" in source
assert "build_completion_payload(profile, job, response_text)" in source

print("stage-16-fc-o43-a-r4 callsite claimed smoke passed")
