#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o43-b-reset-requeue-only-job117-no-runtime-no-reset-failed.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O43-B reset/requeue only job117 no runtime no reset-failed" "$DOC"
grep -Fq "Base HEAD/origin/main: \`69113f8\`" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O43_B_RESET_REQUEUE_ONLY_JOB117_NO_RUNTIME_NO_RESET_FAILED" "$DOC"

grep -Fq "worker_sha_fc_o43_b=884e0fcbbd7d31df5cd6027b1d4e5294c61ac2ae497e52d6d560ee5d3bf30ca8" "$DOC"
grep -Fq "profile_sha_fc_o43_b=2605835c8efe00de65123486d5432f900dd6449f3a720da1befb76e8b93eac5b" "$DOC"

grep -Fq "job117_state_before_fc_o43_b=running,1,0" "$DOC"
grep -Fq "job117_post_update_fc_o43_b=queued,1,0" "$DOC"
grep -Fq "job117_rows_updated_fc_o43_b=1" "$DOC"

grep -Fq "job108_state_post_update_fc_o43_b=queued,0,0" "$DOC"
grep -Fq "job118_state_post_update_fc_o43_b=queued,0,0" "$DOC"
grep -Fq "job121_state_post_update_fc_o43_b=queued,0,0" "$DOC"

grep -Fq "No failed-unit evidence was cleared." "$DOC"
grep -Fq "quick_check_after_update_fc_o43_b=ok" "$DOC"
grep -Fq "ct203_fc_o43_b_requeue_acceptance_pass=true" "$DOC"
grep -Fq "Next recommended stage: FC-O43-C run only job117 again with the fixed worker." "$DOC"

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

echo "stage-16-fc-o43-b job117 requeue smoke passed"
