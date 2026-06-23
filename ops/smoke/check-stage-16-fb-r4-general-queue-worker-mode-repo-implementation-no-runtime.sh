#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fb-r4-general-queue-worker-mode-repo-implementation-no-runtime.md"
WORKER="ops/workers/ct101_minimal_ollama_worker.py"

test -f "$DOC"
test -f "$WORKER"

python3 -m py_compile "$WORKER"

grep -Fq "EDGE_WORKER_MODE" "$WORKER"
grep -Fq "general_queue" "$WORKER"
grep -Fq "exact_marker" "$WORKER"
grep -Fq "REFUSE_UNKNOWN_WORKER_MODE" "$WORKER"
grep -Fq "REFUSE_GENERAL_QUEUE_EMPTY_RESPONSE" "$WORKER"
grep -Fq "REFUSE_GENERAL_QUEUE_RESPONSE_TOO_LARGE" "$WORKER"
grep -Fq "REFUSE_EXPECTED_MARKER_NOT_FOUND" "$WORKER"
grep -Fq "REFUSE_WORKER_EXACT_MARKER_MISMATCH" "$WORKER"

grep -Fq "Stage 16 FB-R4 general_queue worker mode repo implementation no-runtime" "$DOC"
grep -Fq "Base HEAD/origin/main: \`86c8590\`" "$DOC"
grep -Fq "This FB-R4 stage changed repo source and tests only." "$DOC"
grep -Fq "EDGE_WORKER_MODE=exact_marker" "$DOC"
grep -Fq "EDGE_WORKER_MODE=general_queue" "$DOC"
grep -Fq "Default behavior remains exact-marker compatible." "$DOC"
grep -Fq "general_queue_missing_marker_allowed=true" "$DOC"
grep -Fq "This preserves the proof-worker behavior used by jobs 55, 56, and 57." "$DOC"
grep -Fq "does not prove live CT101 runtime behavior" "$DOC"
grep -Fq "job 57: completed exact marker evidence" "$DOC"
grep -Fq "job 58: running failed evidence" "$DOC"
grep -Fq "jobs 59 through 64: queued evidence" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FB-R4B\`" "$DOC"

python3 - <<'PY_SMOKE'
import importlib.util
import inspect
import os
import sys
from pathlib import Path
from types import SimpleNamespace

path = Path("ops/workers/ct101_minimal_ollama_worker.py")
spec = importlib.util.spec_from_file_location("ct101_minimal_ollama_worker_fb_r4_smoke", path)
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod
spec.loader.exec_module(mod)
sig = inspect.signature(mod.validate_completion)

profile = SimpleNamespace(
    name="stage16-test-profile",
    model="qwen2.5:0.5b",
    completion_validation_policy="exact_marker_only",
)

def call_validate(prompt, completion):
    args = []
    kwargs = {}
    for name, param in sig.parameters.items():
        lname = name.lower()
        if "profile" in lname:
            value = profile
        elif "job" in lname:
            value = {"id": 999, "prompt": prompt, "requested_model": "qwen2.5:0.5b"}
        elif "prompt" in lname or "input" in lname or "request" in lname:
            value = prompt
        elif "completion" in lname or "response" in lname or "output" in lname or "text" in lname:
            value = completion
        elif param.default is not inspect._empty:
            continue
        else:
            value = completion
        if param.kind in (inspect.Parameter.POSITIONAL_ONLY, inspect.Parameter.POSITIONAL_OR_KEYWORD):
            args.append(value)
        elif param.kind == inspect.Parameter.KEYWORD_ONLY:
            kwargs[name] = value
    return mod.validate_completion(*args, **kwargs)

os.environ.pop("EDGE_WORKER_MODE", None)
try:
    call_validate("No marker here.", "hello")
except Exception as exc:
    assert "REFUSE_EXPECTED_MARKER_NOT_FOUND" in str(exc)
else:
    raise SystemExit("default mode did not refuse missing marker")

os.environ["EDGE_WORKER_MODE"] = "general_queue"
call_validate("No marker here.", "hello companion")

try:
    call_validate("No marker here.", "")
except Exception as exc:
    assert "REFUSE_GENERAL_QUEUE_EMPTY_RESPONSE" in str(exc)
else:
    raise SystemExit("general_queue did not refuse empty response")

print("stage-16-fb-r4 dynamic smoke passed")
PY_SMOKE

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "raw Tailscale IPv4 leaked into doc"
  exit 1
fi
if grep -Eq '10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "raw private IPv4 leaked into doc"
  exit 1
fi
if grep -Eq '192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "raw private IPv4 leaked into doc"
  exit 1
fi
if grep -Eq 'fd7a:[0-9a-f:]+' "$DOC"; then
  echo "raw Tailscale IPv6 leaked into doc"
  exit 1
fi

echo "stage-16-fb-r4 general_queue worker implementation smoke passed"
