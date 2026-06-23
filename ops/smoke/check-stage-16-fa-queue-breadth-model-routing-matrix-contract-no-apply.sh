#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fa-queue-breadth-model-routing-matrix-contract-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FA queue breadth/model-routing matrix contract no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`b0260e6\`" "$DOC"
grep -Fq "This FA stage is repo-only planning." "$DOC"
grep -Fq "job 53: failed evidence, running, attempts 1, result rows 0" "$DOC"
grep -Fq "job 54: failed evidence, running, attempts 1, result rows 0" "$DOC"
grep -Fq "job 55: successful evidence, completed, attempts 1, result rows 1" "$DOC"
grep -Fq "job 56: successful evidence, completed, attempts 1, result rows 1" "$DOC"
grep -Fq "Recommended batch size: 8 jobs." "$DOC"
grep -Fq "| 57 | exact marker sanity | \`qwen2.5:0.5b\` | Return exact marker only | exact match |" "$DOC"
grep -Fq "| 64 | safe refusal boundary | \`qwen2.5:0.5b\` | refuse a disallowed request safely | contains refusal marker |" "$DOC"
grep -Fq "STAGE16-FB-J57-OK" "$DOC"
grep -Fq "preserve jobs 53 through 56" "$DOC"
grep -Fq "process jobs serially" "$DOC"
grep -Fq "never start persistent workers" "$DOC"
grep -Fq "FD must define concurrency limits before any concurrent runtime proof." "$DOC"
grep -Fq "maximum active jobs overall" "$DOC"
grep -Fq "FE should be the first runtime concurrency stage." "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FB\`" "$DOC"

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

echo "stage-16-fa queue breadth matrix contract smoke passed"
