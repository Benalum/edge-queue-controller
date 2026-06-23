#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-er-guarded-installed-timer-service-path-contract-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 E3Z-ER guarded installed timer/service path contract no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`b2b5e1e\`" "$DOC"
grep -Fq "This E3Z-ER stage is repo-only planning." "$DOC"
grep -Fq "E3Z-EP: job 51 completed through one transient one-tick CT101 timer." "$DOC"
grep -Fq "E3Z-EQ: job 52 completed through repeated transient one-tick CT101 timer." "$DOC"
grep -Fq "EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml" "$DOC"
grep -Fq "Future installed unit design constraints" "$DOC"
grep -Fq "Future install-only stage acceptance criteria" "$DOC"
grep -Fq "Future installed one-tick runtime proof acceptance criteria" "$DOC"
grep -Fq "must not reset jobs, delete rows, apply schema, mutate Docker, restart CTs or VMs, pull models" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 E3Z-ES\`" "$DOC"
grep -Fq "E3Z-ES requires explicit runtime/infrastructure approval" "$DOC"

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

echo "stage-16-e3z-er no-apply installed timer/service contract smoke passed"
