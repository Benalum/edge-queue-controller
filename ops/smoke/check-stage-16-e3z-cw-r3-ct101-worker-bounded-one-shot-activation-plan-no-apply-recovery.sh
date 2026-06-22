#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-cw-r3-ct101-worker-bounded-one-shot-activation-plan-no-apply-recovery.md"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  'This is a repository-only no-apply planning stage'
  'backticked word'
  'Activation must be separate from install'
  'Use qwen2.5:0.5b first'
  'E3Z-WORKER-QWEN25-ONE-SHOT-OK'
  'APPROVE_STAGE_16_E3Z_CX_INSERT_ONE_FRESH_WORKER_ACTIVATION_PROOF_JOB_ONLY'
  'APPROVE_STAGE_16_E3Z_CY_RUN_CT101_WORKER_ONE_SHOT_EXACT_JOB_ONLY'
  'CZ — read-only post-activation guard'
  'systemd-run --wait --collect'
  '--once --job-id'
  'EDGE_WORKER_ENABLED=1'
  'EDGE_WORKER_ENABLED=0'
  'new worker service is inactive and disabled'
  'old worker service is inactive and masked'
  'only the ollama container is running'
  'Scheduler/timer must remain inactive'
  'Do not rerun jobs 37 through 44'
  'Do not insert more than one activation proof job in CX'
  'Do not start a persistent CT101 worker loop'
  'Do not enable the CT101 worker service'
  'Do not activate scheduler or timer'
  'Do not change CT203 claim endpoint behavior'
  'Do not enable model concurrency in the first worker activation'
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_CW_R3_SMOKE_OK=1"
