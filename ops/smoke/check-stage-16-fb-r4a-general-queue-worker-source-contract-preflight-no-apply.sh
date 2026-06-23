#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fb-r4a-general-queue-worker-source-contract-preflight-no-apply.md"
WORKER="ops/workers/ct101_minimal_ollama_worker.py"

test -f "$DOC"
test -f "$WORKER"

python3 -m py_compile "$WORKER"

grep -Fq "Stage 16 FB-R4A general_queue worker source contract preflight no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`d02eac3\`" "$DOC"
grep -Fq "This FB-R4A stage is repo docs/smoke only." "$DOC"
grep -Fq "Worker path: \`ops/workers/ct101_minimal_ollama_worker.py\`" "$DOC"
grep -Fq "has_EDGE_ALLOWED_JOB_IDS=true" "$DOC"
grep -Fq "has_EDGE_WORKER_MODE=false" "$DOC"
grep -Fq "has_general_queue_reference=false" "$DOC"
grep -Fq "has_REFUSE_EXPECTED_MARKER_NOT_FOUND=true" "$DOC"
grep -Fq "EDGE_WORKER_MODE=exact_marker" "$DOC"
grep -Fq "EDGE_WORKER_MODE=general_queue" "$DOC"
grep -Fq "default mode remains exact-marker compatible" "$DOC"
grep -Fq "general_queue mode must not require marker extraction" "$DOC"
grep -Fq "general_queue mode must still require exactly one allowed job id" "$DOC"
grep -Fq "job 57: completed exact marker evidence" "$DOC"
grep -Fq "job 58: running failed evidence" "$DOC"
grep -Fq "jobs 59 through 64: queued evidence" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FB-R4\`" "$DOC"

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "raw Tailscale IPv4 leaked into doc"
  exit 1
fi
if grep -Eq '10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "raw private IPv4 leaked into doc"
  exit 1
fi
if grep -Eq '192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "raw private IPv4 leaked into doc"
  exit 1
fi
if grep -Eq 'fd7a:[0-9a-f:]+' "$DOC"; then
  echo "raw Tailscale IPv6 leaked into doc"
  exit 1
fi

if grep -Fq "APPROVE_" "$DOC"; then
  echo "approval token found in no-apply doc"
  exit 1
fi
if grep -Eq '^```bash' "$DOC"; then
  echo "bash executable block found in no-apply doc"
  exit 1
fi

echo "stage-16-fb-r4a source contract preflight smoke passed"
