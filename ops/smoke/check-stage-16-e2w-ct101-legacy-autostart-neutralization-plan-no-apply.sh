#!/usr/bin/env bash
set -euo pipefail
set +H

echo "=== Stage 16-E2W smoke: local-only CT101 neutralization plan assertions ==="
echo "MUTATION_SCOPE=local_repo_read_only_smoke"
echo "NO SSH"
echo "NO live infra mutation"
echo "NO DB write"
echo "NO worker/model/scheduler activation"
echo

cd "$(git rev-parse --show-toplevel)"

doc="docs/stage-16-e2w-ct101-legacy-autostart-neutralization-plan-no-apply.md"
test -f "$doc"

grep -F "CT101 Legacy-Autostart Neutralization Plan" "$doc" >/dev/null
grep -F "Do **not** start CT101 again" "$doc" >/dev/null
grep -F "Docker/containerd active/enabled" "$doc" >/dev/null
grep -F "docker-proxy listening on port 11434" "$doc" >/dev/null
grep -F "/bin/ollama serve" "$doc" >/dev/null
grep -F "python -m app.worker.agent" "$doc" >/dev/null
grep -F "local-queue-controller.sh" "$doc" >/dev/null
grep -F "uvicorn services on ports 8880/8088" "$doc" >/dev/null
grep -F "whisper-asr web service" "$doc" >/dev/null
grep -F "APPROVE_STAGE_16_E2X_CT101_OFFLINE_LEGACY_AUTOSTART_NEUTRALIZATION_NO_CT_START_NO_DB_WRITE_NO_MODEL_CALL" "$doc" >/dev/null
grep -F "CT101 remains stopped" "$doc" >/dev/null
grep -F "no model endpoint call occurred" "$doc" >/dev/null

echo "doc_assertions_ok=true"
echo "PASS_STAGE_16_E2W_LOCAL_ONLY_DOC_SMOKE"
