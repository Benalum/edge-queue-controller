#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ep-one-tick-timer-runtime-proof-one-fresh-job.md"

test -f "$DOC"

grep -Fq "Stage 16 E3Z-EP one-tick timer runtime proof, one fresh job" "$DOC"
grep -Fq "Base HEAD/origin/main: \`f5a6592\`" "$DOC"
grep -Fq "APPROVE_STAGE_16_E3Z_EP_ONE_TICK_TIMER_RUNTIME_PROOF_ONE_FRESH_JOB_ONLY" "$DOC"
grep -Fq "one transient one-tick CT101 systemd timer" "$DOC"
grep -Fq "one timer-triggered worker invocation" "$DOC"
grep -Fq "EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml" "$DOC"
grep -Fq "one CT101 Ollama call using \`qwen2.5:0.5b\`" "$DOC"
grep -Fq "E3Z-EP passed." "$DOC"
grep -Fq "acceptance_pass=true" "$DOC"
grep -Fq "edge_service_after_active=inactive" "$DOC"
grep -Fq "edge_service_after_enabled=disabled" "$DOC"
grep -Fq "ct101_queue_timer_rows_after=0" "$DOC"
grep -Fq "first one-tick timer-triggered CT101 worker completion" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 E3Z-EQ\`" "$DOC"

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

echo "stage-16-e3z-ep one-tick timer proof smoke passed"
