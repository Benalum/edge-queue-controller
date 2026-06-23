#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-d-insert-jobs-81-87-only-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-D insert jobs 81-87 only no-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_D_INSERT_JOBS_81_87_ONLY_NO_RUNTIME" "$DOC"
grep -Fq "Base HEAD/origin/main: \`b63f0f5\`" "$DOC"

grep -Fq "profile_fc_all_job_types_present_before_fc_d_insert=true" "$DOC"
grep -Fq "ct101_before_fc_d_insert_acceptance_pass=true" "$DOC"

grep -Fq "backup_path_fc_d=" "$DOC"
grep -Fq "backup_sha256_fc_d=" "$DOC"
grep -Fq "quick_check_before_fc_d_insert=ok" "$DOC"
grep -Fq "max_job_id_before_fc_d_insert=80" "$DOC"
grep -Fq "jobs81_87_existing_before_fc_d_insert=0" "$DOC"
grep -Fq "inserted_jobs_count_fc_d=7" "$DOC"
grep -Fq "max_job_id_after_fc_d_insert=87" "$DOC"
grep -Fq "jobs81_87_existing_after_fc_d_insert=7" "$DOC"
grep -Fq "jobs81_87_queued_after_fc_d_insert=7" "$DOC"
grep -Fq "jobs81_87_attempts_zero_after_fc_d_insert=7" "$DOC"
grep -Fq "jobs81_87_requested_model_count_after_fc_d_insert=7" "$DOC"
grep -Fq "jobs81_87_result_rows_after_fc_d_insert=0" "$DOC"
grep -Fq "jobs81_87_expected_job_types_match_after_fc_d_insert=true" "$DOC"
grep -Fq "ct203_fc_d_insert_acceptance_pass=true" "$DOC"

grep -Fq "stage16_fc_companion_chat_semantic_probe" "$DOC"
grep -Fq "stage16_fc_study_tutor_semantic_probe" "$DOC"
grep -Fq "stage16_fc_flashcards_semantic_probe" "$DOC"
grep -Fq "stage16_fc_summary_semantic_probe" "$DOC"
grep -Fq "stage16_fc_json_semantic_probe" "$DOC"
grep -Fq "stage16_fc_router_label_semantic_probe" "$DOC"
grep -Fq "stage16_fc_safe_refusal_semantic_probe" "$DOC"

grep -Fq "jobs73_80_completed_after_fc_d_insert=8" "$DOC"
grep -Fq "jobs65_72_running_after_fc_d_insert=1" "$DOC"
grep -Fq "ct101_after_fc_d_insert_default_off_acceptance_pass=true" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FC-E\`" "$DOC"

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

echo "stage-16-fc-d insert jobs81-87 only smoke passed"
