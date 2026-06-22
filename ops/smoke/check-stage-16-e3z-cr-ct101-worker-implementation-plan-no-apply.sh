#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-cr-ct101-worker-implementation-plan-no-apply.md"
PROFILE="ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }
[ -f "$PROFILE" ] || { echo "MISSING_PROFILE=$PROFILE"; exit 1; }

needles=(
  "This is a repository-only no-apply stage"
  "ops/workers/ct101_minimal_ollama_worker.py"
  "load_model_profiles()"
  "EDGE_WORKER_ENABLED=0 by default"
  "EDGE_CLAIM_POLICY=one_at_a_time"
  "EDGE_ALLOW_MODEL_CONCURRENCY=0"
  "POST /internal/edge-worker/jobs/claim"
  "POST /internal/edge-worker/jobs/{job_id}/complete"
  "docker exec ollama ollama run --think=false --hidethinking qwen3:0.6b"
  "docker exec ollama ollama run --think false --hidethinking qwen3:0.6b"
  "exact_marker_only"
  "REFUSE_WORKER_DISABLED"
  "edge-ct101-ollama-worker.service.example"
  "Repo-only smoke should verify"
  "CS — repo-only worker skeleton and smoke"
  "Do not rerun jobs 37 through 44"
  "Do not call models"
  "Do not connect to live CT203 API"
  "Do not connect to live CT101"
  "Do not activate scheduler or timer"
  "Do not change CT203 claim endpoint behavior in this stage"
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

check(data.get("schema_version") == 1, "schema_version")
check(data.get("claim_policy_default") == "one_at_a_time", "claim_policy_default")
check(data.get("enabled_by_default") is False, "artifact_disabled")
check(by_id["qwen3_router_small"].get("cli_flags") == ["--think=false", "--hidethinking"], "qwen3_flags")
check(all(p.get("enabled_by_default") is False for p in profiles), "all_profiles_disabled")
check(all(p.get("claim_policy") == "one_at_a_time" for p in profiles), "all_profiles_one_at_a_time")

if not ok:
    sys.exit(1)

print("E3Z_CR_PROFILE_REFERENCE_VALIDATION_OK=1")
PY

echo "E3Z_CR_SMOKE_OK=1"
