#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o42-r2-insert-fresh-product-visible-output-probes-schema-adaptive-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O42-R2 insert fresh product-visible-output probes no runtime" "$DOC"
grep -Fq "Base HEAD/origin/main: \`6297bae\`" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O42_INSERT_FRESH_PRODUCT_VISIBLE_OUTPUT_PROBES_NO_RUNTIME_NO_RESET_FAILED" "$DOC"

grep -Fq "first FC-O42 attempt failed safely" "$DOC"
grep -Fq "worker_sha_fc_o42_r2=1809af3a97e5b357d47b4ce3728ca4e5e8f6692de89e920b881f7b3b58b820d3" "$DOC"
grep -Fq "profile_sha_fc_o42_r2=2605835c8efe00de65123486d5432f900dd6449f3a720da1befb76e8b93eac5b" "$DOC"
grep -Fq "profile_readiness_fc_o42_r2=true" "$DOC"
grep -Fq "ct101_readiness_fc_o42_r2=true" "$DOC"

grep -Fq "gemma4_product_candidate=product_visible_output_v1" "$DOC"
grep -Fq "gemma3_companion_candidate=product_visible_output_v1" "$DOC"
grep -Fq "llama32_safe_refusal_candidate=product_visible_output_v1" "$DOC"

grep -Fq "R2 avoided optional-column assumptions" "$DOC"
grep -Fq "inserted_fc_o42_r2_job_ids=" "$DOC"
grep -Fq "gemma4_companion_product_visible" "$DOC"
grep -Fq "gemma3_companion_product_visible" "$DOC"
grep -Fq "gemma4_study_tutor_product_visible" "$DOC"
grep -Fq "gemma4_flashcards_product_visible" "$DOC"
grep -Fq "llama32_safe_refusal_product_visible" "$DOC"

grep -Fq "Jobs108-111 were intentionally preserved" "$DOC"
grep -Fq "old_job108_state_after_fc_o42_r2=queued,0,0" "$DOC"
grep -Fq "old_job111_state_after_fc_o42_r2=queued,0,0" "$DOC"

grep -Fq "active_general_services_fc_o42_r2=0" "$DOC"
grep -Fq "active_general_timers_fc_o42_r2=0" "$DOC"
grep -Fq "No failed-unit evidence was cleared." "$DOC"
grep -Fq "quick_check_after_insert_fc_o42_r2=ok" "$DOC"
grep -Fq "ct203_fc_o42_r2_insert_acceptance_pass=true" "$DOC"
grep -Fq "Next recommended stage: FC-O43 run one fresh gemma4 Companion probe only" "$DOC"

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

echo "stage-16-fc-o42-r2 fresh product-visible-output probe insert smoke passed"
