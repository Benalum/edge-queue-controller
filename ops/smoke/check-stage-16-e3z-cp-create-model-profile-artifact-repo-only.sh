#!/usr/bin/env bash
set -euo pipefail

PROFILE="ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml"
DOC="docs/stage-16-e3z-cp-create-model-profile-artifact-repo-only.md"

[ -f "$PROFILE" ] || { echo "MISSING_PROFILE=$PROFILE"; exit 1; }
[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

python3 - <<'PY'
from pathlib import Path
import sys

try:
    import yaml
except Exception as e:
    print("MISSING_PYYAML_OR_YAML_IMPORT_FAILED="+repr(e))
    sys.exit(2)

p = Path("ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml")
data = yaml.safe_load(p.read_text(encoding="utf-8"))

ok = True

def check(cond, msg):
    global ok
    if not cond:
        print("CHECK_FAILED="+msg)
        ok = False

check(data.get("schema_version") == 1, "schema_version")
check(data.get("artifact_id") == "ct101_ollama_model_profiles_stage16_e3z", "artifact_id")
check(data.get("runtime_owner") == "ct101", "runtime_owner")
check(data.get("model_runtime") == "ollama_docker_container", "model_runtime")
check(data.get("container_name") == "ollama", "container_name")
check(data.get("claim_policy_default") == "one_at_a_time", "claim_policy_default")
check(data.get("enabled_by_default") is False, "artifact_enabled_by_default_false")

profiles = data.get("profiles")
check(isinstance(profiles, list) and len(profiles) == 5, "profiles_len_5")

by_id = {p.get("profile_id"): p for p in profiles}
check(len(by_id) == len(profiles), "unique_profile_id")

required_ids = {
    "qwen25_router_small",
    "qwen3_router_small",
    "qwen3_1_7b_candidate",
    "gemma3_study_light_candidate",
    "gemma4_companion_candidate",
}
check(set(by_id) == required_ids, "required_profile_ids")

for pid, profile in by_id.items():
    check(profile.get("enabled_by_default") is False, f"{pid}_enabled_by_default_false")
    check(profile.get("claim_policy") == "one_at_a_time", f"{pid}_claim_policy")
    check(profile.get("endpoint_type") == "ollama_cli_in_container", f"{pid}_endpoint_type")
    check(profile.get("container_name") == "ollama", f"{pid}_container_name")
    check(isinstance(profile.get("allowed_job_types"), list) and profile.get("allowed_job_types"), f"{pid}_allowed_job_types")
    check(isinstance(profile.get("timeout_seconds"), int) and profile.get("timeout_seconds") > 0, f"{pid}_timeout_seconds")
    check(isinstance(profile.get("max_concurrent_model_calls"), int) and profile.get("max_concurrent_model_calls") >= 1, f"{pid}_max_concurrent_model_calls")

q25 = by_id["qwen25_router_small"]
check(q25.get("model_name") == "qwen2.5:0.5b", "q25_model")
check(q25.get("role") == "router_small", "q25_role")
check(q25.get("cli_flags") == [], "q25_cli_flags")
check(q25.get("max_concurrent_model_calls") == 2, "q25_max_concurrent")
check(q25.get("exact_marker_supported") is True, "q25_exact")
check(q25.get("thinking_mode") == "none", "q25_thinking")
check(q25.get("hidethinking_required") is False, "q25_hidethinking")
check(q25.get("completion_validation_policy") == "exact_marker_only", "q25_validation")

q3 = by_id["qwen3_router_small"]
check(q3.get("model_name") == "qwen3:0.6b", "q3_model")
check(q3.get("role") == "router_small", "q3_role")
check(q3.get("cli_flags") == ["--think=false", "--hidethinking"], "q3_cli_flags")
check(q3.get("max_concurrent_model_calls") == 2, "q3_max_concurrent")
check(q3.get("exact_marker_supported") is True, "q3_exact")
check(q3.get("thinking_mode") == "disabled", "q3_thinking")
check(q3.get("hidethinking_required") is True, "q3_hidethinking")
check(q3.get("completion_validation_policy") == "exact_marker_only", "q3_validation")

for pid in ("qwen3_1_7b_candidate", "gemma3_study_light_candidate", "gemma4_companion_candidate"):
    profile = by_id[pid]
    check(profile.get("max_concurrent_model_calls") == 1, f"{pid}_single_call")
    check(profile.get("exact_marker_supported") is False, f"{pid}_not_exact_supported")
    check(profile.get("completion_validation_policy") == "no_default_until_proven", f"{pid}_validation")
    check(profile.get("allowed_job_types") == ["future_single_model_probe_only"], f"{pid}_allowed_future_single_probe_only")

if not ok:
    sys.exit(1)

print("E3Z_CP_PROFILE_YAML_VALIDATION_OK=1")
PY

needles=(
  "This stage is repository-only"
  "ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml"
  "qwen25_router_small"
  "qwen3_router_small"
  "--think=false"
  "--hidethinking"
  "Do not rerun jobs 37 through 44"
  "Do not call models"
  "Do not start CT101 persistent worker service"
  "Do not activate scheduler or timer"
  "Do not change claim endpoint behavior in this stage"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_DOC_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_CP_SMOKE_OK=1"
