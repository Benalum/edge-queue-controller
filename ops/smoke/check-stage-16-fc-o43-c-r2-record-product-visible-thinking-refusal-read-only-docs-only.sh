#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o43-c-r2-record-product-visible-thinking-refusal-read-only-docs-only.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O43-C-R2 record product visible thinking refusal read-only docs only" "$DOC"
grep -Fq "Base HEAD/origin/main: \`5418317\`" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O43_C_R2_RECORD_PRODUCT_VISIBLE_THINKING_REFUSAL_READ_ONLY_DOCS_ONLY_NO_RESET_FAILED" "$DOC"

grep -Fq "REFUSE_PRODUCT_VISIBLE_THINKING" "$DOC"
grep -Fq "This means the product gate is working" "$DOC"
grep -Fq "job117_state_fc_o43_c_r2=running,2,0" "$DOC"
grep -Fq "job117_result_rows_fc_o43_c_r2=0" "$DOC"
grep -Fq "worker_sha_fc_o43_c_r2=884e0fcbbd7d31df5cd6027b1d4e5294c61ac2ae497e52d6d560ee5d3bf30ca8" "$DOC"
grep -Fq "profile_sha_fc_o43_c_r2=2605835c8efe00de65123486d5432f900dd6449f3a720da1befb76e8b93eac5b" "$DOC"
grep -Fq "No reset-failed command was run." "$DOC"
grep -Fq "Next recommended stage: FC-O43-D worker failure-path remediation contract" "$DOC"

grep -Fq "job108_state_fc_o43_c_r2=queued,0,0" "$DOC"
grep -Fq "job118_state_fc_o43_c_r2=queued,0,0" "$DOC"
grep -Fq "job121_state_fc_o43_c_r2=queued,0,0" "$DOC"

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

echo "stage-16-fc-o43-c-r2 product visible thinking refusal record smoke passed"
