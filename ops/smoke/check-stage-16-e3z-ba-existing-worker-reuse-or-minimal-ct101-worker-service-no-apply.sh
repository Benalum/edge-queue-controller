#!/usr/bin/env bash
set -euo pipefail
DOC="docs/stage-16-e3z-ba-existing-worker-reuse-or-minimal-ct101-worker-service-no-apply.md"
for needle in \
  'The preferred design is existing-worker reuse first' \
  'CT101 should run a small worker process that talks to CT203 using existing queue-worker contracts' \
  '_s5e4_queue_client' \
  's5e4_laptop_queue_claim_job' \
  '_phase14j_filter_workers_for_lane' \
  'Ten existing Docker containers have restart policy `unless-stopped`' \
  'Do not call `/api/generate`' \
  'Do not reuse job 34'
do
  grep -Fq "$needle" "$DOC" || { echo "missing_required_text=$needle"; exit 2; }
done
echo 'E3Z_BA_SMOKE_OK=1'
