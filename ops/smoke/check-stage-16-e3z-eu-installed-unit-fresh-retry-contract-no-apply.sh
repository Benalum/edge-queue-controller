#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-eu-installed-unit-fresh-retry-contract-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 E3Z-EU installed-unit fresh retry contract no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`e2719b2\`" "$DOC"
grep -Fq "This E3Z-EU stage is repo-only planning." "$DOC"
grep -Fq "REFUSE_WORKER_EXACT_MARKER_MISMATCH" "$DOC"
grep -Fq "Job 53 must remain preserved as failure evidence." "$DOC"
grep -Fq "job id: \`53\`" "$DOC"
grep -Fq "status: \`running\`" "$DOC"
grep -Fq "attempts: \`1\`" "$DOC"
grep -Fq "result rows: \`0\`" "$DOC"
grep -Fq "Job 53 must not be:" "$DOC"
grep -Fq "Expected next fresh job id: \`54\`." "$DOC"
grep -Fq "EDGE_ALLOWED_JOB_IDS=54" "$DOC"
grep -Fq "It must not include job 53 in the allowed job ids." "$DOC"
grep -Fq "Recommended marker:" "$DOC"
grep -Fq "E3Z-EV-OK" "$DOC"
grep -Fq "Return exactly E3Z-EV-OK" "$DOC"
grep -Fq "Job 53 remains unchanged after the retry." "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 E3Z-EV\`" "$DOC"

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

# Guard this no-apply contract from becoming an apply block.
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
if grep -Eq 'sqlite3[[:space:]]+/var/lib/edge-queue-controller/edge_queue\.sqlite3' "$DOC"; then
  echo "direct writable sqlite command found"
  exit 1
fi

echo "stage-16-e3z-eu installed-unit fresh retry contract smoke passed"
