#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-m-insert-jobs-95-104-only-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-M insert jobs 95-104 only no-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_M_INSERT_JOBS_95_104_ONLY_NO_RUNTIME" "$DOC"
grep -Fq "Base HEAD/origin/main: \`695deab\`" "$DOC"

grep -Fq "ct101_before_fc_m_inventory_default_off_acceptance_pass=true" "$DOC"
grep -Fq "backup_path_fc_m=" "$DOC"
grep -Fq "backup_sha256_fc_m=" "$DOC"
grep -Fq "quick_check_before_fc_m_insert=ok" "$DOC"
grep -Fq "max_job_id_before_fc_m_insert=94" "$DOC"
grep -Fq "jobs95_104_existing_before_fc_m_insert=0" "$DOC"
grep -Fq "inserted_jobs_count_fc_m=10" "$DOC"
grep -Fq "max_job_id_after_fc_m_insert=104" "$DOC"
grep -Fq "jobs95_104_existing_after_fc_m_insert=10" "$DOC"
grep -Fq "jobs95_104_queued_after_fc_m_insert=10" "$DOC"
grep -Fq "jobs95_104_attempts_zero_after_fc_m_insert=10" "$DOC"
grep -Fq "jobs95_104_result_rows_after_fc_m_insert=0" "$DOC"
grep -Fq "jobs95_104_expected_shape_match_after_fc_m_insert=true" "$DOC"
grep -Fq "ct203_fc_m_insert_acceptance_pass=true" "$DOC"

grep -Fq "job95: \`stage16_fc_router_label_semantic_probe\`, requested_model \`qwen2.5:0.5b\`" "$DOC"
grep -Fq "job97: \`stage16_fc_summary_semantic_probe\`, requested_model \`qwen3:1.7b\`" "$DOC"
grep -Fq "job100: \`stage16_fc_companion_chat_semantic_probe\`, requested_model \`gemma4:e4b\`" "$DOC"
grep -Fq "job101: \`stage16_fc_companion_chat_semantic_probe\`, requested_model \`gemma3:4b\`" "$DOC"
grep -Fq "job102: \`stage16_fc_study_tutor_semantic_probe\`, requested_model \`gemma4:e4b\`" "$DOC"
grep -Fq "job103: \`stage16_fc_flashcards_semantic_probe\`, requested_model \`gemma4:e4b\`" "$DOC"
grep -Fq "job104: \`stage16_fc_safe_refusal_semantic_probe\`, requested_model \`llama3.2:3b\`" "$DOC"

grep -Fq "jobs88_94_completed_after_fc_m_insert=7" "$DOC"
grep -Fq "jobs81_87_completed_after_fc_m_insert=7" "$DOC"
grep -Fq "jobs65_72_running_after_fc_m_insert=1" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FC-N\`" "$DOC"

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

echo "stage-16-fc-m insert jobs95-104 only smoke passed"
