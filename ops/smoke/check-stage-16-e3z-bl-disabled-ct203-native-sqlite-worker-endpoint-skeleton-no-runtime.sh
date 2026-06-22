#!/usr/bin/env bash
set -euo pipefail

SRC="edge_controller.py"
DOC="docs/stage-16-e3z-bl-disabled-ct203-native-sqlite-worker-endpoint-skeleton-no-runtime.md"

need_src=(
  "E3Z_BL_CT203_SQLITE_WORKER_ENDPOINTS_BEGIN"
  "EDGE_CT203_SQLITE_WORKER_API_ENABLED"
  "@app.get(\"/internal/edge-worker/summary\")"
  "@app.post(\"/internal/edge-worker/workers/register\")"
  "@app.post(\"/internal/edge-worker/workers/heartbeat\")"
  "@app.post(\"/internal/edge-worker/jobs/claim\")"
  "@app.post(\"/internal/edge-worker/jobs/{job_id}/complete\")"
  "@app.post(\"/internal/edge-worker/jobs/{job_id}/fail\")"
  "skeleton-only in stage-16-e3z-bl"
)

need_doc=(
  "Default state is disabled"
  "This stage does not restart CT203"
  "start Docker"
  "call Ollama"
  "mutate jobs"
  "Stage 16 E3Z-BM should perform runtime disabled-route refusal validation"
)

for needle in "${need_src[@]}"; do
  grep -Fq "$needle" "$SRC" || { echo "MISSING_SRC=$needle"; exit 1; }
done

for needle in "${need_doc[@]}"; do
  grep -Fq "$needle" "$DOC" || { echo "MISSING_DOC=$needle"; exit 1; }
done

python3 -m py_compile "$SRC"

echo "E3Z_BL_SMOKE_OK=1"
