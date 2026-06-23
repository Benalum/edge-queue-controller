#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-em-r6-bounded-service-path-runtime-proof-job49-env-profile.md"

test -f "$DOC"

grep -Fq "Stage 16 E3Z-EM-R6 bounded service-path runtime proof, job49 env profile path" "$DOC"
grep -Fq "Base HEAD/origin/main: \`fe5b4d6\`" "$DOC"
grep -Fq "APPROVE_STAGE_16_E3Z_EM_BOUNDED_SERVICE_PATH_RUNTIME_PROOF_ONE_FRESH_JOB_ONLY" "$DOC"
grep -Fq "REFUSE_WORKER_DISABLED" "$DOC"
grep -Fq "REFUSE_WORKER_SCHEDULER_ACTIVE" "$DOC"
grep -Fq "REFUSE_PROFILE_FILE_MISSING" "$DOC"
grep -Fq "R6 reused existing job 49. It did not insert a new job." "$DOC"
grep -Fq "EDGE_WORKER_ENABLED=1" "$DOC"
grep -Fq "EDGE_ALLOWED_JOB_IDS=49" "$DOC"
grep -Fq "EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml" "$DOC"
grep -Fq "one CT101 Ollama call using \`qwen2.5:0.5b\`" "$DOC"
grep -Fq "E3Z-EM-R6 passed." "$DOC"
grep -Fq "acceptance_pass=true" "$DOC"
grep -Fq "edge_service_after_active=inactive" "$DOC"
grep -Fq "edge_service_after_enabled=disabled" "$DOC"
grep -Fq "ct101_queue_timer_rows_after=0" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 E3Z-EN\`" "$DOC"

# The doc must not contain raw private or Tailscale IP addresses.
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

echo "stage-16-e3z-em-r6 runtime proof smoke passed"
