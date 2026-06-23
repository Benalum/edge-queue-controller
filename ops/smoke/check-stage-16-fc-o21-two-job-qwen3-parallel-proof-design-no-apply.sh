#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o21-two-job-qwen3-parallel-proof-design-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O21 two-job qwen3 parallel proof design no-apply" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O21_TWO_JOB_QWEN3_PARALLEL_PROOF_DESIGN_NO_APPLY" "$DOC"
grep -Fq "Base HEAD/origin/main: \`c1c4ec9\`" "$DOC"
grep -Fq "This stage is repo documentation and smoke only." "$DOC"

grep -Fq "FC-O14: job113 summary hygiene passed" "$DOC"
grep -Fq "FC-O16: job106 JSON strict pass" "$DOC"
grep -Fq "FC-O20: job114 JSON strict pass after OLLAMA_NUM_PARALLEL=2" "$DOC"
grep -Fq "job114_strict_json_pass_fc_o20=true" "$DOC"

grep -Fq "OLLAMA_NUM_PARALLEL=2" "$DOC"
grep -Fq "CT203 remains the durable queue and claim authority." "$DOC"
grep -Fq "Ollama does not own durable job state." "$DOC"
grep -Fq "Persistent workers remain off." "$DOC"
grep -Fq "Bulk queue draining remains prohibited." "$DOC"

grep -Fq "| 115 | 106 or 114 | stage16_fc_json_semantic_probe | qwen3:1.7b | first parallel JSON proof |" "$DOC"
grep -Fq "| 116 | 106 or 114 | stage16_fc_json_semantic_probe | qwen3:1.7b | second parallel JSON proof |" "$DOC"
grep -Fq "FC-O22 insert fresh jobs115-116 qwen3 JSON parallel proof only no-runtime" "$DOC"

grep -Fq "edge-ct101-general-queue-job-worker@115.service" "$DOC"
grep -Fq "edge-ct101-general-queue-job-worker@116.service" "$DOC"
grep -Fq "start both service instances back-to-back" "$DOC"

grep -Fq "Both jobs complete with attempts=1." "$DOC"
grep -Fq "Both result payloads parse as JSON." "$DOC"
grep -Fq "Job105 remains running/stale and untouched." "$DOC"
grep -Fq "Failed unit evidence count is unchanged." "$DOC"

grep -Fq "Do not run parallel jobs in this design stage." "$DOC"
grep -Fq "Next recommended step is FC-O22: insert exactly two fresh qwen3 JSON proof jobs" "$DOC"

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

echo "stage-16-fc-o21 two-job qwen3 parallel proof design smoke passed"
