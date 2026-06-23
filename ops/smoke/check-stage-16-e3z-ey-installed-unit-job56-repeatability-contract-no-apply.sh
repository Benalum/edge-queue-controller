#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ey-installed-unit-job56-repeatability-contract-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 E3Z-EY installed-unit job56 repeatability contract no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`23ff889\`" "$DOC"
grep -Fq "This E3Z-EY stage is repo-only planning." "$DOC"
grep -Fq "job 53: running, attempts 1, result rows 0" "$DOC"
grep -Fq "job 54: running, attempts 1, result rows 0" "$DOC"
grep -Fq "job 55: completed, attempts 1, result rows 1" "$DOC"
grep -Fq "response text: \`E3Z-EW-OK\`" "$DOC"
grep -Fq "Future workers must be constrained to a fresh job id only." "$DOC"
grep -Fq "Recommended future marker:" "$DOC"
grep -Fq "E3Z-EY-OK" "$DOC"
grep -Fq "Return exactly this text and nothing else: E3Z-EY-OK" "$DOC"
grep -Fq "Expected next fresh job id: \`56\`." "$DOC"
grep -Fq "EDGE_ALLOWED_JOB_IDS=56" "$DOC"
grep -Fq "edge-ct101-exact-job-worker@56.timer" "$DOC"
grep -Fq "edge-ct101-exact-job-worker@56.service" "$DOC"
grep -Fq "It must not include job 53, job 54, or job 55 in the allowed job ids." "$DOC"
grep -Fq "Stage 16 FA: queue breadth and model-routing matrix contract, no-apply" "$DOC"
grep -Fq "Stage 16 FB: queue breadth single-thread runtime proof" "$DOC"
grep -Fq "Stage 16 FC: queue breadth multi-model serial proof" "$DOC"
grep -Fq "Stage 16 FD: concurrency preflight no-apply" "$DOC"
grep -Fq "Stage 16 FE: limited concurrency runtime proof" "$DOC"
grep -Fq "Stage 16 FF: broader concurrency/load proof" "$DOC"
grep -Fq "Concurrency testing must not start persistent workers or scheduler dispatch until those limits are documented and explicitly approved." "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 E3Z-EZ\`" "$DOC"

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

echo "stage-16-e3z-ey installed-unit repeatability contract smoke passed"
