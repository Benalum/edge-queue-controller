#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fb-r3-corrected-queue-breadth-worker-strategy-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FB-R3 corrected queue breadth worker strategy no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`6023189\`" "$DOC"
grep -Fq "This FB-R3 stage is repo-only planning." "$DOC"
grep -Fq "The installed worker is still an exact-marker proof worker." "$DOC"
grep -Fq "general queue worker mode" "$DOC"
grep -Fq "EDGE_WORKER_MODE=exact_marker" "$DOC"
grep -Fq "EDGE_WORKER_MODE=general_queue" "$DOC"
grep -Fq "exact-marker mode still refuses missing marker" "$DOC"
grep -Fq "general_queue mode does not require marker extraction" "$DOC"
grep -Fq "Recommended path: Option A." "$DOC"
grep -Fq "Use fresh jobs 65 through 72" "$DOC"
grep -Fq "Job58 service currently remains failed as preserved evidence." "$DOC"
grep -Fq "No concurrency testing should begin" "$DOC"
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
if grep -Eq 'systemctl[[:space:]]+(start|restart|reload|enable|disable|daemon-reload)' "$DOC"; then
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

echo "stage-16-fb-r3 corrected queue breadth strategy smoke passed"
