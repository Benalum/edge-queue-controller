#!/usr/bin/env python3
import importlib.util
import pathlib
import sys
from types import SimpleNamespace

worker_path = pathlib.Path("ops/workers/ct101_minimal_ollama_worker.py")
spec = importlib.util.spec_from_file_location("ct101_minimal_ollama_worker_fc_o43_a_r3", worker_path)
if spec is None or spec.loader is None:
    raise SystemExit("failed import spec")
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod
spec.loader.exec_module(mod)

captured = {}

def fake_post_json(config, token, path, payload):
    captured["config"] = config
    captured["token"] = token
    captured["path"] = path
    captured["payload"] = payload
    return 200, {"ok": True}

mod._post_json = fake_post_json

product_config = SimpleNamespace(worker_id="fc-o43-a-r3-product-test-worker", allowed_job_ids=(117,))
exact_config = SimpleNamespace(worker_id="fc-o43-a-r3-exact-test-worker", allowed_job_ids=(114,))

product_profile = SimpleNamespace(
    profile_id="gemma4_product_candidate",
    model_name="gemma4:e4b",
    completion_validation_policy="product_visible_output_v1",
)
exact_profile = SimpleNamespace(
    profile_id="qwen3_1_7b_candidate",
    model_name="qwen3:1.7b",
    completion_validation_policy="exact_marker_only",
)

job = {
    "id": 117,
    "job_type": "stage16_fc_companion_chat_semantic_probe",
    "requested_model": "gemma4:e4b",
    "prompt": "Write one friendly paragraph only. The user says: I had a long day and want a quick encouraging check-in.",
}
clean = "You made it through a long day, and it is okay to rest now while giving yourself credit for showing up."

mod.complete_job(product_config, "token", 117, product_profile, job, clean)
payload = captured["payload"]
assert captured["path"].endswith("/internal/edge-worker/jobs/117/complete"), captured["path"]
assert payload["worker_id"] == "fc-o43-a-r3-product-test-worker"
assert payload["model"] == "gemma4:e4b"
assert payload["response_text"] == clean
assert payload["response_json"]["result_contract"] == "product_visible_output_v1"
assert payload["response_json"]["job_type"] == "stage16_fc_companion_chat_semantic_probe"

try:
    mod.complete_job(product_config, "token", 117, product_profile, job, "Thinking... The user wants comfort.")
except Exception as exc:
    assert "REFUSE_PRODUCT_VISIBLE_THINKING" in str(exc), str(exc)
else:
    raise AssertionError("expected visible-thinking refusal")

captured.clear()
mod.complete_job(exact_config, "token", 114, exact_profile, {"id": 114, "job_type": "stage16_fc_json_semantic_probe"}, "OK")
payload = captured["payload"]
assert payload["worker_id"] == "fc-o43-a-r3-exact-test-worker"
assert payload["response_json"]["stage"] == "stage-16-e3z-ec-worker-guards"
assert payload["response_json"]["exact_match"] is True

try:
    mod.complete_job(product_config, "token", 999, product_profile, job, clean)
except Exception as exc:
    assert "REFUSE_WORKER_CLAIMED_JOB_ID_NOT_ALLOWED" in str(exc), str(exc)
else:
    raise AssertionError("expected allowed-job-id refusal")

print("stage-16-fc-o43-a-r3 complete_job job context tests passed")
