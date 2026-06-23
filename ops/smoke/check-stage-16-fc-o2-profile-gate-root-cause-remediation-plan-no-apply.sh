#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o2-profile-gate-root-cause-remediation-plan-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O2 profile gate root-cause remediation plan no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`675a797\`" "$DOC"
grep -Fq "This stage is repo documentation only." "$DOC"

grep -Fq "REFUSE_JOB_TYPE_NOT_ALLOWED_FOR_PROFILE" "$DOC"
grep -Fq "REFUSE_NO_PROFILE_FOR_MODEL" "$DOC"
grep -Fq "not generation failures" "$DOC"
grep -Fq "profile-gate/productization configuration" "$DOC"

grep -Fq "Add a safe FC-only qwen3:1.7b remediation profile" "$DOC"
grep -Fq "Add a safe FC-only gemma4:e4b remediation profile" "$DOC"
grep -Fq "Add a safe FC-only gemma3:4b remediation profile" "$DOC"
grep -Fq "Add a safe FC-only llama3.2:3b profile" "$DOC"

grep -Fq "mutate only \`/etc/edge-ct101-worker/model-profiles.yaml\`" "$DOC"
grep -Fq "run no jobs" "$DOC"
grep -Fq "call no model endpoints" "$DOC"
grep -Fq "pull no models" "$DOC"
grep -Fq "reset no failed units" "$DOC"

grep -Fq "Preferred recovery path after profile apply" "$DOC"
grep -Fq "create new replacement jobs instead of resetting old stale jobs" "$DOC"
grep -Fq "Stop FC-N runtime remains in force." "$DOC"
grep -Fq "Proceed to an explicitly approved profile-only apply stage when ready." "$DOC"

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
  echo "approval token found in FC-O2 no-apply doc"
  exit 1
fi

echo "stage-16-fc-o2 profile gate root-cause remediation plan smoke passed"
