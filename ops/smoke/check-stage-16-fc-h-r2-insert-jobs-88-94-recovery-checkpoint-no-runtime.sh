#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-h-r2-insert-jobs-88-94-recovery-checkpoint-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-H-R2 insert jobs 88-94 recovery checkpoint no-runtime" "$DOC"
grep -Fq "does not rerun the insert" "$DOC"
grep -Fq "Base HEAD/origin/main before FC-H-R2 documentation: \`5b295c5\`" "$DOC"

grep -Fq "backup_path_fc_h=/var/lib/edge-queue-controller/stage16-fc-backups/edge_queue.sqlite3.stage16-fc-h-pre-jobs88-94-insert.20260623T032634Z.bak" "$DOC"
grep -Fq "backup_sha256_fc_h=7aa60bc3df02a2cfd79972ed61cd5f087ea3409b7467acdc08da4a619a8bf732" "$DOC"

grep -Fq "quick_check_fc_h_r2=ok" "$DOC"
grep -Fq "max_job_id_fc_h_r2=94" "$DOC"
grep -Fq "jobs88_94_existing_fc_h_r2=7" "$DOC"
grep -Fq "jobs88_94_queued_fc_h_r2=7" "$DOC"
grep -Fq "jobs88_94_attempts_zero_fc_h_r2=7" "$DOC"
grep -Fq "jobs88_94_requested_model_count_fc_h_r2=7" "$DOC"
grep -Fq "jobs88_94_result_rows_fc_h_r2=0" "$DOC"
grep -Fq "jobs88_94_expected_job_types_match_fc_h_r2=true" "$DOC"
grep -Fq "ct203_fc_h_r2_read_only_acceptance_pass=true" "$DOC"

grep -Fq "job88: \`stage16_fc_study_tutor_semantic_probe\`" "$DOC"
grep -Fq "job89: \`stage16_fc_flashcards_semantic_probe\`" "$DOC"
grep -Fq "job90: \`stage16_fc_summary_semantic_probe\`" "$DOC"
grep -Fq "job91: \`stage16_fc_json_semantic_probe\`" "$DOC"
grep -Fq "job92: \`stage16_fc_safe_refusal_semantic_probe\`" "$DOC"
grep -Fq "job93: \`stage16_fc_companion_chat_semantic_probe\`" "$DOC"
grep -Fq "job94: \`stage16_fc_router_label_semantic_probe\`" "$DOC"

grep -Fq "jobs81_87_completed_fc_h_r2=7" "$DOC"
grep -Fq "jobs73_80_completed_fc_h_r2=8" "$DOC"
grep -Fq "jobs65_72_running_fc_h_r2=1" "$DOC"
grep -Fq "ct101_fc_h_r2_default_off_acceptance_pass=true" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FC-I\`" "$DOC"

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

echo "stage-16-fc-h-r2 recovery checkpoint smoke passed"
