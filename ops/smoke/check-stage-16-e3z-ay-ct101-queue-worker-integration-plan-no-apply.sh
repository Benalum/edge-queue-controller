#!/usr/bin/env bash
set -euo pipefail
DOC="docs/stage-16-e3z-ay-ct101-queue-worker-integration-plan-no-apply.md"
for needle in \
  'CT203 remains the controller, queue, scheduler, and database authority' \
  'CT101 is the intended model-worker container' \
  'Do not build a parallel queue system' \
  'Do not call `/api/generate`' \
  'Do not reuse job 34'
do
  grep -Fq "$needle" "$DOC" || { echo "missing_required_text=$needle"; exit 2; }
done
echo 'E3Z_AY_SMOKE_OK=1'
