#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ct-live-readiness-validator-read-only.md"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "This stage is read-only for live systems and repo-only for documentation/smoke commit"
  "jobs 37 through 44 completed attempts=1 result_rows=1"
  "CT203 DB integrity"
  "jobs_total: 43"
  "job_results_total: 24"
  "jobs_status_running: 0"
  "runtime container set: ollama only"
  "worker service: inactive and masked"
  "Do not rerun jobs 37 through 44"
  "Do not call models"
  "Do not start CT101 persistent worker service"
  "Do not activate scheduler or timer"
  "Do not change CT203 claim endpoint behavior in this stage"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_CT_SMOKE_OK=1"
