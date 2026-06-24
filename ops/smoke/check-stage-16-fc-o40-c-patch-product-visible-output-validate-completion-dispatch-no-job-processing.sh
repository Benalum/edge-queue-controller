#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o40-c-patch-product-visible-output-validate-completion-dispatch-no-job-processing.md"
WORKER="ops/workers/ct101_minimal_ollama_worker.py"
CONTRACT_SMOKE="ops/smoke/check-stage-16-fc-o40-c-product-visible-output-dispatch.py"

test -f "$DOC"
test -f "$WORKER"
test -x "$CONTRACT_SMOKE"

grep -Fq "Stage 16 FC-O40-C patch product visible output validate_completion dispatch no job processing" "$DOC"
grep -Fq "Base HEAD/origin/main: \`0eb7df5\`" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O40_C_PATCH_PRODUCT_VISIBLE_OUTPUT_VALIDATE_COMPLETION_DISPATCH_NO_PROFILE_POLICY_MUTATION_NO_JOB_PROCESSING_NO_RESET_FAILED" "$DOC"

grep -Fq "validate_completion" "$DOC"
grep -Fq "product_visible_output_v1" "$DOC"
grep -Fq "REFUSE_UNSUPPORTED_COMPLETION_VALIDATION" "$DOC"
grep -Fq "exact_marker_only still refuses wrong marker" "$DOC"
grep -Fq "CT101 deployed worker dispatch tests also passed." "$DOC"
grep -Fq "ct101_fc_o40_c_worker_deploy_acceptance_pass=true" "$DOC"
grep -Fq "No failed-unit evidence was cleared." "$DOC"
grep -Fq "job108=queued,0,0" "$DOC"
grep -Fq "job111=queued,0,0" "$DOC"
grep -Fq "FC-O41 is now unblocked" "$DOC"

grep -Fq 'if profile.completion_validation_policy == "product_visible_output_v1":' "$WORKER"
grep -Fq 'return extract_visible_output(response_text)' "$WORKER"
grep -Fq 'if profile.completion_validation_policy != "exact_marker_only":' "$WORKER"
grep -Fq "REFUSE_UNSUPPORTED_COMPLETION_VALIDATION" "$WORKER"
grep -Fq "REFUSE_WORKER_EXACT_MARKER_MISMATCH" "$WORKER"

python3 -m py_compile "$WORKER"
"$CONTRACT_SMOKE"

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

echo "stage-16-fc-o40-c validate_completion dispatch smoke passed"
