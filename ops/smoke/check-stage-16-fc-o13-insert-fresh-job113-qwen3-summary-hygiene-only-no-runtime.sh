#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o13-insert-fresh-job113-qwen3-summary-hygiene-only-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O13 insert fresh job113 qwen3 summary hygiene only no-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O13_INSERT_FRESH_JOB113_QWEN3_SUMMARY_HYGIENE_ONLY_NO_RUNTIME_NO_OLD_JOB_MUTATION" "$DOC"
grep -Fq "Base HEAD/origin/main: \`626463a\`" "$DOC"

grep -Fq "mutated only the CT203 DB by inserting one fresh queued qwen3 summary hygiene proof job: job113" "$DOC"
grep -Fq "db_backup_path_fc_o13=" "$DOC"
grep -Fq "db_backup_sha_fc_o13=" "$DOC"

grep -Fq "| 113 | 112 | stage16_fc_summary_semantic_probe | qwen3:1.7b | queued | 0 | 0 |" "$DOC"
grep -Fq "inserted_job_ids_fc_o13=113" "$DOC"
grep -Fq "job113_status_fc_o13=queued" "$DOC"
grep -Fq "job113_attempts_fc_o13=0" "$DOC"
grep -Fq "job113_result_rows_fc_o13=0" "$DOC"
grep -Fq "max_job_id_after_fc_o13=113" "$DOC"
grep -Fq "ct203_fc_o13_insert_acceptance_pass=true" "$DOC"

grep -Fq "job105_status_after_fc_o13=running" "$DOC"
grep -Fq "job105_attempts_after_fc_o13=1" "$DOC"
grep -Fq "job105_result_rows_after_fc_o13=0" "$DOC"
grep -Fq "jobs106_111_remain_queued_attempts0_rows0=true" "$DOC"
grep -Fq "job112_status_after_fc_o13=completed" "$DOC"
grep -Fq "job112_result_rows_after_fc_o13=1" "$DOC"

grep -Fq "profile_sha_fc_o13=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899" "$DOC"
grep -Fq "active_exact_services_fc_o13=0" "$DOC"
grep -Fq "active_general_services_fc_o13=0" "$DOC"
grep -Fq "failed_general_units_fc_o13=6" "$DOC"
grep -Fq "ct101_fc_o13_read_only_acceptance_pass=true" "$DOC"

grep -Fq "Fresh qwen3 summary hygiene proof job113 is queued" "$DOC"
grep -Fq "Do not run job106 yet." "$DOC"
grep -Fq "The next stage should run job113 only" "$DOC"

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

echo "stage-16-fc-o13 insert fresh job113 smoke passed"
