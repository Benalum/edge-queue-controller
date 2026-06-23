#!/usr/bin/env python3
import importlib.util
import os
import pathlib
import sys
from types import SimpleNamespace

worker_path = pathlib.Path("ops/workers/ct101_minimal_ollama_worker.py")
spec = importlib.util.spec_from_file_location("ct101_minimal_ollama_worker_fc_o40_b_r3", worker_path)
if spec is None or spec.loader is None:
    raise SystemExit("failed to create import spec")
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod
spec.loader.exec_module(mod)

profile = SimpleNamespace(profile_id="test_product_profile", model_name="test:model", completion_validation_policy="product_visible_output_v1")
exact_profile = SimpleNamespace(profile_id="test_exact_profile", model_name="test:model", completion_validation_policy="exact_marker_only")

def job(job_type: str, prompt: str = ""):
    return {"job_type": job_type, "prompt": prompt}

def assert_pass(job_type: str, output: str, prompt: str = ""):
    result = mod.validate_product_visible_output(profile, job(job_type, prompt), output)
    assert result.passed, (job_type, result)
    assert result.visible_output == output.strip()
    return result

def assert_refuse(code: str, job_type: str, output: str, prompt: str = ""):
    result = mod.validate_product_visible_output(profile, job(job_type, prompt), output)
    assert not result.passed, (code, job_type, result)
    assert result.refusal_code == code, (code, result.refusal_code, result)
    return result

companion = assert_pass(
    "stage16_fc_companion_chat_semantic_probe",
    "You made it through a long day, and it is okay to slow down now and take one small kind step for yourself.",
)
metadata = mod.build_product_response_json(profile, job("stage16_fc_companion_chat_semantic_probe"), companion)
assert metadata["result_contract"] == "product_visible_output_v1"
assert metadata["validation"]["passed"] is True

payload = mod.build_completion_payload(profile, job("stage16_fc_companion_chat_semantic_probe"), companion.visible_output)
assert payload["response_text"] == companion.visible_output
assert payload["response_json"]["result_contract"] == "product_visible_output_v1"

exact_payload = mod.build_completion_payload(exact_profile, job("future_single_model_probe_only"), "OK")
assert exact_payload["response_json"]["stage"] == "stage-16-e3z-ec-worker-guards"
assert exact_payload["response_json"]["exact_match"] is True

assert_refuse("REFUSE_PRODUCT_VISIBLE_THINKING", "stage16_fc_companion_chat_semantic_probe", "Thinking... The user wants comfort. You made it through a hard day.")
assert_refuse("REFUSE_PRODUCT_HIDDEN_THINKING", "stage16_fc_companion_chat_semantic_probe", "<think>plan</think>You made it through a hard day and deserve rest.")
assert_refuse("REFUSE_PRODUCT_GUARD_JSON", "stage16_fc_companion_chat_semantic_probe", '{"exact_match": true, "profile_id": "x", "stage": "stage-16-e3z-ec-worker-guards"}')
assert_refuse("REFUSE_PRODUCT_INTERNAL_TERMS", "stage16_fc_companion_chat_semantic_probe", "You did fine today, but the worker queue system says the instruction should be hidden.")

assert_pass("stage16_fc_flashcards_semantic_probe", '[{"prompt":"What process turns liquid water into vapor?","answer":"Evaporation."}]', "Output exactly this raw JSON array and nothing else.")
assert_refuse("REFUSE_PRODUCT_SHAPE_MISMATCH", "stage16_fc_flashcards_semantic_probe", 'Here are the cards: [{"prompt":"A","answer":"B"}]', "Output exactly this raw JSON array and nothing else.")
assert_pass("stage16_fc_safe_refusal_semantic_probe", "I cannot help with someone else's private credential, but you can use account recovery or rotate the secret.")
assert_refuse("REFUSE_PRODUCT_UNSUPPORTED_JOB_TYPE", "stage16_fc_unknown_semantic_probe", "You made it through a long day and can rest now.")

os.environ["EDGE_WORKER_MODE"] = "exact_marker"
assert mod.validate_completion(exact_profile, {"response_json": {"expected_marker": "OK"}}, "OK") == "OK"
try:
    mod.validate_completion(exact_profile, {"response_json": {"expected_marker": "OK"}}, "WRONG")
except Exception as exc:
    assert "REFUSE_WORKER_EXACT_MARKER_MISMATCH" in str(exc), str(exc)
else:
    raise AssertionError("expected exact marker mismatch refusal")

print("stage-16-fc-o40-b-r3 product visible output worker contract tests passed")
