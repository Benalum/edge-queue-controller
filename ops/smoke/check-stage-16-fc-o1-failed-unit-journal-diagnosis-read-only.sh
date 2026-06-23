#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o1-failed-unit-journal-diagnosis-read-only.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O1 failed-unit journal diagnosis read-only" "$DOC"
grep -Fq "Base HEAD/origin/main: \`4daa3bc\`" "$DOC"
grep -Fq "This stage is read-only." "$DOC"

grep -Fq "fc_n_final_matrix_verified_for_o1=true" "$DOC"
grep -Fq "quick_check_fc_o1=ok" "$DOC"
grep -Fq "ct203_fc_o1_read_only_acceptance_pass=true" "$DOC"
grep -Fq "ct101_fc_o1_read_only_acceptance_pass=true" "$DOC"

grep -Fq "profile_sha_fc_o1=432cd0130f61472b94215ffbf279f516bbc64d2d8ea0e8ba161878186816279c" "$DOC"
grep -Fq "worker_sha_fc_o1=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"

grep -Fq "failed_general_units_fc_o1=5" "$DOC"
grep -Fq "| 97 | qwen3:1.7b | summary |" "$DOC"
grep -Fq "| 104 | llama3.2:3b | safe_refusal |" "$DOC"

grep -Fq "Do not reset failed units." "$DOC"
grep -Fq "Do not retry stale jobs." "$DOC"
grep -Fq "Do not run new probes." "$DOC"
grep -Fq "Proceed to FC-O2" "$DOC"

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
  echo "approval token found in read-only FC-O1 doc"
  exit 1
fi

echo "stage-16-fc-o1 failed-unit journal diagnosis smoke passed"
