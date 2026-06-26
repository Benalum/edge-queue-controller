#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

HELPER="ops/workers/run-deterministic-companion-exact-once.py"
DOC="docs/stage-16-fc-o45-e-cj-s-bounded-deterministic-companion-worker-client-helper.md"

test -f "$HELPER"
test -x "$HELPER"
test -f "$DOC"

grep -Fq "LAPTOP_QUEUE_INTERNAL_TOKEN" "$HELPER"
grep -Fq "X-Laptop-Queue-Token" "$HELPER"
grep -Fq "/internal/edge-worker/jobs/claim" "$HELPER"
grep -Fq "/internal/edge-worker/jobs/{job_id}/complete" "$HELPER"
grep -Fq "claimed" "$HELPER"
grep -Fq "deterministic_exact_answer_short_circuit" "$HELPER"
grep -Fq "backend-deterministic/no-model" "$HELPER"
grep -Fq "model_call_allowed" "$HELPER"
grep -Fq "model_endpoint_called" "$HELPER"
grep -Fq "pveso_called" "$HELPER"

grep -Fq "Bounded Deterministic Companion Worker-Client Helper" "$DOC"
grep -Fq "ops/workers/run-deterministic-companion-exact-once.py" "$DOC"
grep -Fq "claimed" "$DOC"
grep -Fq "backend-deterministic/no-model" "$DOC"
grep -Fq "model_call_allowed=false" "$DOC"
grep -Fq "Does not call PVESO, Ollama, or any model endpoint" "$DOC"
grep -Fq "does not enable persistent workers" "$DOC"

python3 -m py_compile "$HELPER"

python3 - <<'PY'
import importlib.util
from pathlib import Path

helper = Path("ops/workers/run-deterministic-companion-exact-once.py")
spec = importlib.util.spec_from_file_location("cj_s_helper_unit", helper)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

calls = []

def fake_json_post(base_url, path, token, payload, timeout=10):
    calls.append((path, payload))
    assert base_url == "http://offline-unit.invalid"
    assert token == "fake-token-never-printed"

    if path == "/internal/edge-worker/jobs/claim":
        return {
            "ok": True,
            "stage": "stage-16-e3z-bo",
            "claimed": {
                "id": 999,
                "status": "running",
                "attempts": 1,
                "job_type": "companion.chat",
                "requested_model": "qwen2.5:0.5b",
                "companion_execution": {
                    "mode": "deterministic_exact_answer_short_circuit",
                    "complete_without_model": True,
                    "model": "backend-deterministic/no-model",
                    "response_text": "FC-O45-E-CJ-S-HELPER-OK",
                    "response_json": {
                        "ok": True,
                        "marker": "FC-O45-E-CJ-S-HELPER-OK",
                        "model_required": False,
                        "model_call_allowed": False,
                    },
                    "model_required": False,
                    "model_call_allowed": False,
                    "semantic_exact_marker_pass": True,
                    "result_source": "backend_deterministic_exact_answer_short_circuit",
                },
            },
        }

    if path == "/internal/edge-worker/jobs/999/complete":
        assert payload["model"] == "backend-deterministic/no-model"
        assert payload["response_text"] == "FC-O45-E-CJ-S-HELPER-OK"
        assert payload["response_json"]["model_endpoint_called"] is False
        assert payload["response_json"]["pveso_called"] is False
        return {
            "ok": True,
            "stage": "stage-16-e3z-bo",
            "job": {
                "id": 999,
                "status": "completed",
            },
        }

    raise AssertionError(path)

module._json_post = fake_json_post

result = module.run_once(
    base_url="http://offline-unit.invalid",
    token="fake-token-never-printed",
    job_id=999,
    worker_id="unit-worker",
    allowed_model="qwen2.5:0.5b",
    expected_marker="FC-O45-E-CJ-S-HELPER-OK",
)

assert result["ok"] is True, result
assert result["claim_response_key"] == "claimed", result
assert result["complete_without_model"] is True, result
assert result["result_model"] == "backend-deterministic/no-model", result
assert result["response_text"] == "FC-O45-E-CJ-S-HELPER-OK", result
assert result["model_endpoint_called"] is False, result
assert result["pveso_called"] is False, result
assert [c[0] for c in calls] == [
    "/internal/edge-worker/jobs/claim",
    "/internal/edge-worker/jobs/999/complete",
], calls

print("deterministic_companion_worker_client_offline_unit_smoke_ok=yes")
PY

echo "PASS stage-16-fc-o45-e-cj-s-r2 bounded deterministic Companion worker-client helper smoke"
