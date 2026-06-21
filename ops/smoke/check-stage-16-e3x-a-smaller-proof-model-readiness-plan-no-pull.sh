#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3x-a-smaller-proof-model-readiness-plan-no-pull.md"

echo "=== Stage 16 E3X-A smoke: smaller proof model readiness plan no pull ==="

test -s "$DOC"

grep -F "Smaller Proof Model Readiness Plan, No Pull" "$DOC"
grep -F "E3X_A_SMALLER_PROOF_MODEL_READINESS_PLAN_NO_PULL_OK" "$DOC"
grep -F "HEAD/origin/main/remote: e767777" "$DOC"
grep -F "E3W proved the timeout-safe wrapper failure path" "$DOC"
grep -F "E3X_A_CT203_DB_READINESS_OK" "$DOC"
grep -F "E3X_A_RUNNING_E3V_E3W_E3X_JOB_COUNT=0" "$DOC"
grep -F "E3X_A_ELIGIBLE_E3V_E3W_E3X_JOB_COUNT=0" "$DOC"
grep -F "OLLAMA_SERVICE_STATE=active" "$DOC"
grep -F "OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=0" "$DOC"
grep -F "PVESO_ACTIVE_MODEL_CLIENT_COUNT=0" "$DOC"
grep -F "CT101_STATUS=stopped" "$DOC"
grep -F "CT101_ONBOOT=0" "$DOC"
grep -F "E3X_A_LOCAL_MODEL_COUNT=" "$DOC"
grep -F "E3X_A_SMALL_LOCAL_MODEL_PRESENT=" "$DOC"
grep -F "E3X_A_RECOMMENDED_PROOF_MODEL_CANDIDATE=qwen2.5:0.5b" "$DOC"
grep -F "E3X_A_FALLBACK_PROOF_MODEL_CANDIDATE=qwen2.5:1.5b" "$DOC"
grep -F "APPROVE_STAGE_16_E3X_B_PULL_ONE_SMALL_PROOF_MODEL_QWEN25_05B_ONLY" "$DOC"
grep -F "E3X-B may pull one small model only if explicitly approved" "$DOC"
grep -F "E3X-C insert one fresh small-model proof job" "$DOC"
grep -F "E3X-D dry-run timeout-safe wrapper would-claim that fresh job" "$DOC"
grep -F "E3X-E approved runtime proof using the small model" "$DOC"
grep -F "E3X-A did not:" "$DOC"
grep -F "pull a model" "$DOC"
grep -F "call a model" "$DOC"
grep -F "Do not rerun E3V-Q" "$DOC"
grep -F "Do not retry job 29" "$DOC"
grep -F "Do not rerun job 30" "$DOC"
grep -F "Use a fresh job id for any future runtime proof" "$DOC"

echo "E3X_A_SMALLER_PROOF_MODEL_READINESS_PLAN_NO_PULL_SMOKE_OK"
