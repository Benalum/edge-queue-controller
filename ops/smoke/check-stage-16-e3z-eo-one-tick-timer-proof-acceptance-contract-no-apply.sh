#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-eo-one-tick-timer-proof-acceptance-contract-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 E3Z-EO one-tick timer proof acceptance contract no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`8c2e135\`" "$DOC"
grep -Fq "This E3Z-EO stage is repo-only planning." "$DOC"
grep -Fq "two consecutive bounded CT101 transient service-path completions" "$DOC"
grep -Fq "EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml" "$DOC"
grep -Fq "Future one-tick timer proof target" "$DOC"
grep -Fq "A future timer proof must not enable a persistent timer." "$DOC"
grep -Fq "one-shot timer mechanism" "$DOC"
grep -Fq "Acceptance criteria for a future timer proof" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 E3Z-EP\`" "$DOC"
grep -Fq "E3Z-EP must not enable persistent workers or scheduler/timer dispatch." "$DOC"

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

# Guard against accidentally turning this contract into an executable apply document.
if grep -Fq "APPROVE_" "$DOC"; then
  echo "approval token found in no-apply doc"
  exit 1
fi
if grep -Eq '^```bash' "$DOC"; then
  echo "bash executable block found in no-apply doc"
  exit 1
fi
if grep -Eq 'systemctl[[:space:]]+(start|restart|reload|enable|disable)' "$DOC"; then
  echo "systemctl mutation command found"
  exit 1
fi
if grep -Eq 'docker[[:space:]]+(run|restart|stop|rm|pull)' "$DOC"; then
  echo "docker mutation command found"
  exit 1
fi
if grep -Eq 'ollama[[:space:]]+(run|pull|create|cp|rm|serve)' "$DOC"; then
  echo "ollama mutation command found"
  exit 1
fi
if grep -Eq 'sqlite3[[:space:]]+/var/lib/edge-queue-controller/edge_queue\.sqlite3' "$DOC"; then
  echo "direct writable sqlite command found"
  exit 1
fi

echo "stage-16-e3z-eo no-apply timer contract smoke passed"
