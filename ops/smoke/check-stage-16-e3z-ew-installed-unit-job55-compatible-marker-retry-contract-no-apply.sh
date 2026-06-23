#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ew-installed-unit-job55-compatible-marker-retry-contract-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 E3Z-EW installed-unit job55 compatible-marker retry contract no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`dc4899a\`" "$DOC"
grep -Fq "This E3Z-EW stage is repo-only planning." "$DOC"
grep -Fq "REFUSE_WORKER_EXACT_MARKER_MISMATCH" "$DOC"
grep -Fq "REFUSE_EXPECTED_MARKER_NOT_FOUND" "$DOC"
grep -Fq "job 53: running, attempts 1, result rows 0" "$DOC"
grep -Fq "job 54: running, attempts 1, result rows 0" "$DOC"
grep -Fq "Future workers must be constrained to a fresh job id only." "$DOC"
grep -Fq "Return exactly E3Z-EV-OK" "$DOC"
grep -Fq "Return exactly this text and nothing else: E3Z-EW-OK" "$DOC"
grep -Fq "Expected next fresh job id: \`55\`." "$DOC"
grep -Fq "EDGE_ALLOWED_JOB_IDS=55" "$DOC"
grep -Fq "edge-ct101-exact-job-worker@55.timer" "$DOC"
grep -Fq "edge-ct101-exact-job-worker@55.service" "$DOC"
grep -Fq "It must not include job 53 or job 54 in the allowed job ids." "$DOC"
grep -Fq "Job 53 remains unchanged." "$DOC"
grep -Fq "Job 54 remains unchanged." "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 E3Z-EX\`" "$DOC"

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

echo "stage-16-e3z-ew compatible-marker retry contract smoke passed"
