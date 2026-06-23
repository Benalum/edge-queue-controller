#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o7-proven-profile-gate-diagnosis-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O7 proven-profile gate diagnosis no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`5e50ca2\`" "$DOC"
grep -Fq "This stage is read-only against CT203 and CT101." "$DOC"

grep -Fq "REFUSE_PROFILE_NOT_PROVEN" "$DOC"
grep -Fq "job105_status=running" "$DOC"
grep -Fq "job105_attempts=1" "$DOC"
grep -Fq "job105_result_rows=0" "$DOC"

grep -Fq "qwen3_1_7b_has_allowed_but_not_proven_fc_o7=true" "$DOC"
grep -Fq "FC-O3 fixed the job-type allowlist gate." "$DOC"
grep -Fq "FC-O6 hit the next guard" "$DOC"
grep -Fq "This is still a profile policy gate, not an Ollama/model generation failure." "$DOC"

grep -Fq "active_exact_services_fc_o7=0" "$DOC"
grep -Fq "active_general_services_fc_o7=0" "$DOC"
grep -Fq "failed_general_units_fc_o7=6" "$DOC"

grep -Fq "Do not run job106 or any later replacement job yet." "$DOC"
grep -Fq "profile-only" "$DOC"
grep -Fq "Do not change gemma4, gemma3, or llama3.2 proven state yet." "$DOC"
grep -Fq "Do not reset job105 in the same step." "$DOC"
grep -Fq "use a separate approval" "$DOC"

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
  echo "approval token found in no-apply FC-O7 doc"
  exit 1
fi

echo "stage-16-fc-o7 proven-profile gate diagnosis smoke passed"
