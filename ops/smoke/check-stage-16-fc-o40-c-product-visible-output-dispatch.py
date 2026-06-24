#!/usr/bin/env python3
import importlib.util
import os
import pathlib
import sys
from types import SimpleNamespace

worker_path = pathlib.Path("ops/workers/ct101_minimal_ollama_worker.py")
spec = importlib.util.spec_from_file_location("ct101_minimal_ollama_worker_fc_o40_c", worker_path)
if spec is None or spec.loader is None:
    raise SystemExit("failed import spec")
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod
spec.loader.exec_module(mod)

product_profile = SimpleNamespace(
    profile_id="test_product_profile",
    model_name="test:model",
    completion_validation_policy="product_visible_output_v1",
)
exact_profile = SimpleNamespace(
    profile_id="test_exact_profile",
    model_name="test:model",
    completion_validation_policy="exact_marker_only",
)
unsupported_profile = SimpleNamespace(
    profile_id="test_bad_profile",
    model_name="test:model",
    completion_validation_policy="no_default_until_proven",
)

def job(job_type: str, prompt: str = ""):
    return {"job_type": job_type, "prompt": prompt, "response_json": {"expected_marker": "OK"}}

clean = "  You made it through a long day, and it is okay to rest now while giving yourself credit for showing up.  "

# Product policy now passes through validate_completion instead of refusing as unsupported.
validated = mod.validate_completion(product_profile, job("stage16_fc_companion_chat_semantic_probe"), clean)
assert validated == clean.strip(), validated

# Product visible-output validator and completion payload still enforce product rules.
payload = mod.build_completion_payload(product_profile, job("stage16_fc_companion_chat_semantic_probe"), clean)
assert payload["response_text"] == clean.strip()
assert payload["response_json"]["result_contract"] == "product_visible_output_v1"

try:
    mod.build_completion_payload(product_profile, job("stage16_fc_companion_chat_semantic_probe"), "Thinking... The user wants comfort.")
except Exception as exc:
    assert "REFUSE_PRODUCT_VISIBLE_THINKING" in str(exc), str(exc)
else:
    raise AssertionError("expected visible-thinking refusal")

# Exact marker behavior is unchanged.
os.environ["EDGE_WORKER_MODE"] = "exact_marker"
assert mod.validate_completion(exact_profile, job("future_single_model_probe_only"), "OK") == "OK"
try:
    mod.validate_completion(exact_profile, job("future_single_model_probe_only"), "WRONG")
except Exception as exc:
    assert "REFUSE_WORKER_EXACT_MARKER_MISMATCH" in str(exc), str(exc)
else:
    raise AssertionError("expected exact marker mismatch refusal")

# Unsupported policy still refuses.
try:
    mod.validate_completion(unsupported_profile, job("stage16_fc_companion_chat_semantic_probe"), "OK")
except Exception as exc:
    assert "REFUSE_UNSUPPORTED_COMPLETION_VALIDATION" in str(exc), str(exc)
else:
    raise AssertionError("expected unsupported policy refusal")

print("stage-16-fc-o40-c validate_completion dispatch tests passed")
