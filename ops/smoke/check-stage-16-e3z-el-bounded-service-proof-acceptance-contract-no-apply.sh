#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-el-bounded-service-proof-acceptance-contract-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 E3Z-EL bounded service proof acceptance contract no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`ec8eab8\`" "$DOC"
grep -Fq "Stage 16 E3Z-EK" "$DOC"
grep -Fq "This E3Z-EL stage is repo-only planning." "$DOC"
grep -Fq "The worker service path must be invoked in a bounded one-shot mode." "$DOC"
grep -Fq "one approved job only" "$DOC"
grep -Fq "no general queue drain" "$DOC"
grep -Fq "No queue-processing timer is enabled." "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 E3Z-EM\`" "$DOC"
grep -Fq "E3Z-EM must not enable persistent workers or scheduler/timer dispatch." "$DOC"

# Required known-good baseline facts from E3Z-EK/EJ-C.
grep -Fq "Job 48 response sha256 was \`a567b6299a152552cee2aae209616c8d708bd47cd1aa02b8bd93194503818382\`" "$DOC"
grep -Fq "CT101 worker script sha256 was \`69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f\`" "$DOC"
grep -Fq "CT101 model profile sha256 was \`329118c8916917e538200ee5c0e6d2b4c2a214adf00cf075b810ee23d0baed1d\`" "$DOC"

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

echo "stage-16-e3z-el no-apply smoke passed"
