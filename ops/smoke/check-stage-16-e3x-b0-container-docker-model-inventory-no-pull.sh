#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3x-b0-container-docker-model-inventory-no-pull.md"

echo "=== Stage 16 E3X-B0 smoke: container/Docker model inventory no pull ==="

test -s "$DOC"

grep -F "Container/Docker Model Inventory, No Pull" "$DOC"
grep -F "E3X_B0_CONTAINER_DOCKER_MODEL_INVENTORY_NO_PULL_OK" "$DOC"
grep -F "APPROVAL_HELD_NOT_CONSUMED=APPROVE_STAGE_16_E3X_B_PULL_ONE_SMALL_PROOF_MODEL_QWEN25_05B_ONLY" "$DOC"
grep -F "HEAD/origin/main/remote: 537aa37" "$DOC"
grep -F "E3X_B0_CT203_READINESS_OK" "$DOC"
grep -F "E3X_B0_RUNNING_E3V_E3W_E3X_JOB_COUNT=0" "$DOC"
grep -F "E3X_B0_ELIGIBLE_E3V_E3W_E3X_JOB_COUNT=0" "$DOC"
grep -F "LOCAL_DOCKER_INVENTORY_OK" "$DOC"
grep -F "PVESO_DOCKER_MODEL_INVENTORY=begin" "$DOC"
grep -F "OLLAMA_SERVICE_STATE=active" "$DOC"
grep -F "OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=0" "$DOC"
grep -F "PVESO_ACTIVE_MODEL_CLIENT_COUNT=0" "$DOC"
grep -F "CT101_STATUS=stopped" "$DOC"
grep -F "CT101_ONBOOT=0" "$DOC"
grep -F "E3X_B0_PVESO_HOST_OLLAMA_MODEL_COUNT=" "$DOC"
grep -F "E3X_B0_SMALL_MODEL_PRESENT_ON_HOST_OLLAMA=" "$DOC"
grep -F "E3X_B0_PVESO_CONTAINER_DOCKER_MODEL_INVENTORY_OK" "$DOC"
grep -F "qwen2.5:0.5b" "$DOC"
grep -F "E3X-B0 did not:" "$DOC"
grep -F "pull a model" "$DOC"
grep -F "docker pull" "$DOC"
grep -F "start a Docker container" "$DOC"
grep -F "call a model" "$DOC"
grep -F "APPROVE_STAGE_16_E3X_B_PULL_ONE_SMALL_PROOF_MODEL_QWEN25_05B_ONLY" "$DOC"
grep -F "Do not rerun E3V-Q" "$DOC"
grep -F "Do not retry job 29" "$DOC"
grep -F "Do not rerun job 30" "$DOC"
grep -F "Use a fresh job id for any future runtime proof" "$DOC"

echo "E3X_B0_CONTAINER_DOCKER_MODEL_INVENTORY_NO_PULL_SMOKE_OK"
