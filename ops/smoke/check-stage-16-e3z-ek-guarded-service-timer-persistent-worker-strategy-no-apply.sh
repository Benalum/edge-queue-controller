#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ek-guarded-service-timer-persistent-worker-strategy-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 E3Z-EK guarded service/timer/persistent-worker strategy no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`5c89dbb\`" "$DOC"
grep -Fq "repo-only planning" "$DOC"
grep -Fq "The working operator route is OpenSSH to root at the PVESO Tailscale IP" "$DOC"
grep -Fq "edge-ct101-ollama-worker.service" "$DOC"
grep -Fq "The Ollama Docker container is running and healthy" "$DOC"
grep -Fq "Persistent workers remain default-off" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 E3Z-EL\`" "$DOC"

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

# Guard against accidentally turning this into an apply document.
if grep -Fq "APPROVE_" "$DOC"; then
  echo "approval token found in no-apply doc"
  exit 1
fi
if grep -Eq 'systemctl[[:space:]]+(start|restart|reload|enable|disable)[[:space:]]+edge-ct101-ollama-worker' "$DOC"; then
  echo "worker service mutation command found"
  exit 1
fi
if grep -Eq 'systemctl[[:space:]]+(start|restart|reload|enable|disable)[[:space:]]+edge-.*scheduler' "$DOC"; then
  echo "scheduler mutation command found"
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

echo "stage-16-e3z-ek no-apply smoke passed"
