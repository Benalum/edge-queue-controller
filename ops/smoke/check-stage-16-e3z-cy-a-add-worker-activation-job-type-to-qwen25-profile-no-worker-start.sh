#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-cy-a-add-worker-activation-job-type-to-qwen25-profile-no-worker-start.md"
PROFILE="ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml"
JOB_TYPE="stage16_e3z_worker_one_shot_activation_proof"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }
[ -f "$PROFILE" ] || { echo "MISSING_PROFILE=$PROFILE"; exit 1; }

needles=(
  "APPROVE_STAGE_16_E3Z_CY_A_ADD_WORKER_ACTIVATION_JOB_TYPE_TO_QWEN25_PROFILE_NO_WORKER_START"
  "job_id: 45"
  "stage16_e3z_worker_one_shot_activation_proof"
  "E3Z-WORKER-QWEN25-ONE-SHOT-OK"
  "Running the worker without this repair could have claimed job 45"
  "qwen3_router_small was not changed"
  "job 45 remains queued attempts=0 result_rows=0"
  "new edge-ct101-ollama-worker.service remains inactive and disabled"
  "EDGE_WORKER_ENABLED=0 remains installed"
  "APPROVE_STAGE_16_E3Z_CY_RUN_CT101_WORKER_ONE_SHOT_EXACT_JOB_45_ONLY"
  "Do not call models in CY-A"
  "Do not claim job 45 in CY-A"
  "Do not start CT101 worker service in CY-A"
  "Do not activate scheduler or timer"
  "Do not enable model concurrency in the first worker activation"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_DOC_NEEDLE=$needle"; exit 1; }
done

python3 - "$PROFILE" "$JOB_TYPE" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
job_type = sys.argv[2]
text = path.read_text(encoding="utf-8")

def block(profile_id):
    marker = f"  - profile_id: {profile_id}\n"
    start = text.find(marker)
    if start < 0:
        raise SystemExit(f"MISSING_PROFILE_BLOCK={profile_id}")
    nxt = text.find("\n  - profile_id:", start + len(marker))
    end = len(text) if nxt < 0 else nxt + 1
    return text[start:end]

q25 = block("qwen25_router_small")
q3 = block("qwen3_router_small")
checks = {
    "qwen25_job_type_present": job_type in q25,
    "qwen3_job_type_absent": job_type not in q3,
    "qwen25_model_ok": "model_name: qwen2.5:0.5b" in q25,
    "qwen25_claim_one": "claim_policy: one_at_a_time" in q25,
}
for key, val in checks.items():
    print(f"{key}={1 if val else 0}")
if not all(checks.values()):
    raise SystemExit("PROFILE_VALIDATION_FAILED")
print("E3Z_CY_A_PROFILE_SMOKE_OK=1")
PY

echo "E3Z_CY_A_SMOKE_OK=1"
