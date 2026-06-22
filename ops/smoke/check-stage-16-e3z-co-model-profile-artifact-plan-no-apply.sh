#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-co-model-profile-artifact-plan-no-apply.md"

needles=(
  "This is a repo-only no-apply stage"
  "ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml"
  "profile_id: qwen25_router_small"
  "profile_id: qwen3_router_small"
  "model_name: qwen2.5:0.5b"
  "model_name: qwen3:0.6b"
  "--think=false"
  "--hidethinking"
  "max_concurrent_model_calls: 2"
  "claim_policy: one_at_a_time"
  "enabled_by_default: false"
  "qwen3_1_7b_candidate"
  "gemma3_study_light_candidate"
  "gemma4_companion_candidate"
  "YAML parses"
  "profile_id values are unique"
  "CP — create model profile artifact repo-only"
  "Do not rerun jobs 37 through 44"
  "Do not call models"
  "Do not create the actual model profile artifact in this plan stage"
  "Do not change claim endpoint behavior in this stage"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_CO_SMOKE_OK=1"
