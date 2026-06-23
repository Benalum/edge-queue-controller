#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fb-r4b-ct101-general-queue-worker-deployment-contract-no-apply.md"
WORKER="ops/workers/ct101_minimal_ollama_worker.py"

test -f "$DOC"
test -f "$WORKER"

python3 -m py_compile "$WORKER"
sha="$(sha256sum "$WORKER" | awk '{print $1}')"
test "$sha" = "25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca"

grep -Fq "Stage 16 FB-R4B CT101 general_queue worker deployment contract no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`f45a80b\`" "$DOC"
grep -Fq "This FB-R4B stage is repo docs/smoke only." "$DOC"
grep -Fq "Old live CT101 worker sha from previous evidence" "$DOC"
grep -Fq "69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f" "$DOC"
grep -Fq "New repo worker sha" "$DOC"
grep -Fq "25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"
grep -Fq "FB-R4C: deploy updated worker file to CT101 only" "$DOC"
grep -Fq "EDGE_WORKER_MODE=general_queue" "$DOC"
grep -Fq "Recommended option: Option A." "$DOC"
grep -Fq "edge-ct101-general-queue-job-worker@.service" "$DOC"
grep -Fq "edge-ct101-general-queue-job-worker@.timer" "$DOC"
grep -Fq "job 58: running, attempts 1, result rows 0" "$DOC"
grep -Fq "jobs 59 through 64: queued, attempts 0, result rows 0" "$DOC"
grep -Fq "edge-ct101-exact-job-worker@58.service" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FB-R4C\`" "$DOC"

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

echo "stage-16-fb-r4b deployment contract smoke passed"
