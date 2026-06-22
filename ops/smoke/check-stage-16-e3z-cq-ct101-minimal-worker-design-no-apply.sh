#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-cq-ct101-minimal-worker-design-no-apply.md"
PROFILE="ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }
[ -f "$PROFILE" ] || { echo "MISSING_PROFILE=$PROFILE"; exit 1; }

needles=(
  "This is a repository-only no-apply stage"
  "ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml"
  "CT101 worker service remains inactive and masked"
  "claim one job at a time"
  "EDGE_WORKER_ENABLED=0"
  "EDGE_CLAIM_POLICY=one_at_a_time"
  "docker exec ollama ollama run --think=false --hidethinking qwen3:0.6b"
  "--think false"
  "claim one job at a time"
  "no persistent model-call concurrency yet"
  "exact_marker_only"
  "edge-ct101-ollama-worker.service"
  "disabled"
  "inactive"
  "Do not rerun jobs 37 through 44"
  "Do not call models"
  "Do not start CT101 persistent worker service"
  "Do not activate scheduler or timer"
  "Do not change CT203 claim endpoint behavior in this stage"
  "Do not create live systemd units in this stage"
  "Do not create runtime files under"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

python3 - <<'PY'
from pathlib import Path
import sys

try:
    import yaml
except Exception as e:
    print("MISSING_PYYAML_OR_YAML_IMPORT_FAILED="+repr(e))
    sys.exit(2)

data = yaml.safe_load(Path("ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml").read_text(encoding="utf-8"))
profiles = data.get("profiles", [])
by_id = {p.get("profile_id"): p for p in profiles}
ok = True

def check(cond, msg):
    global ok
    if not cond:
        print("CHECK_FAILED="+msg)
        ok = False

check(data.get("claim_policy_default") == "one_at_a_time", "claim_policy_default")
check(data.get("enabled_by_default") is False, "artifact_disabled")
check("qwen25_router_small" in by_id, "qwen25_profile")
check("qwen3_router_small" in by_id, "qwen3_profile")
check(by_id["qwen25_router_small"].get("max_concurrent_model_calls") == 2, "qwen25_max_concurrent")
check(by_id["qwen3_router_small"].get("cli_flags") == ["--think=false", "--hidethinking"], "qwen3_flags")
check(all(p.get("enabled_by_default") is False for p in profiles), "all_profiles_disabled")
check(all(p.get("claim_policy") == "one_at_a_time" for p in profiles), "all_profiles_one_at_a_time")

if not ok:
    sys.exit(1)

print("E3Z_CQ_PROFILE_REFERENCE_VALIDATION_OK=1")
PY

echo "E3Z_CQ_SMOKE_OK=1"
