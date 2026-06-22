#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-cn-worker-claim-and-model-profile-contract-plan-no-apply.md"

needles=(
  "This is a repo-only no-apply stage"
  "jobs 37 through 44 completed attempts=1 result_rows=1"
  "Claim exactly one job at a time"
  "Never assume that max_jobs greater than 1 is honored"
  "model subprocess concurrency is allowed only after model profile gates exist"
  "A model profile must specify"
  "qwen25_router_small"
  "qwen3_router_small"
  "--think=false"
  "--hidethinking"
  "max_concurrent_model_calls: 2"
  "claim_policy: one_at_a_time"
  "gemma4_companion_candidate"
  "enabled_by_default: false"
  "Do not start, unmask, enable, or install any persistent CT101 worker service"
  "CO model profile artifact plan"
  "Do not rerun jobs 37 through 44"
  "Do not call models"
  "Do not activate scheduler or timer"
  "Do not change claim endpoint behavior in this stage"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_CN_SMOKE_OK=1"
