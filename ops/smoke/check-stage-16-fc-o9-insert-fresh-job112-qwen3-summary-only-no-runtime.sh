#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o9-insert-fresh-job112-qwen3-summary-only-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O9 insert fresh job112 qwen3 summary only no-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O9_INSERT_FRESH_JOB112_QWEN3_SUMMARY_ONLY_NO_RUNTIME_NO_OLD_JOB_MUTATION" "$DOC"
grep -Fq "Base HEAD/origin/main: \`d3ebdef\`" "$DOC"

grep -Fq "mutated only the CT203 DB by inserting one fresh queued replacement job: job112" "$DOC"
grep -Fq "db_backup_path_fc_o9=" "$DOC"
grep -Fq "db_backup_sha_fc_o9=" "$DOC"

grep -Fq "| 112 | 105 | stage16_fc_summary_semantic_probe | qwen3:1.7b | queued | 0 | 0 |" "$DOC"
grep -Fq "inserted_job_ids_fc_o9=112" "$DOC"
grep -Fq "job112_status_fc_o9=queued" "$DOC"
grep -Fq "job112_attempts_fc_o9=0" "$DOC"
grep -Fq "job112_result_rows_fc_o9=0" "$DOC"
grep -Fq "max_job_id_after_fc_o9=112" "$DOC"
grep -Fq "ct203_fc_o9_insert_acceptance_pass=true" "$DOC"

grep -Fq "job105_status_after_fc_o9=running" "$DOC"
grep -Fq "job105_attempts_after_fc_o9=1" "$DOC"
grep -Fq "job105_result_rows_after_fc_o9=0" "$DOC"
grep -Fq "jobs106_111_remain_queued_attempts0_rows0=true" "$DOC"

grep -Fq "profile_sha_fc_o9=56512391b1df4b444d8f72ff2213ee9faeeb2d2db8a55eb1a642d9d4a1202ebf" "$DOC"
grep -Fq "active_exact_services_fc_o9=0" "$DOC"
grep -Fq "active_general_services_fc_o9=0" "$DOC"
grep -Fq "failed_general_units_fc_o9=6" "$DOC"
grep -Fq "ct101_fc_o9_read_only_acceptance_pass=true" "$DOC"

grep -Fq "Fresh qwen3 summary job112 is queued" "$DOC"
grep -Fq "Do not run jobs106-111 yet." "$DOC"
grep -Fq "The next stage should run job112 only" "$DOC"

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

echo "stage-16-fc-o9 insert fresh job112 smoke passed"
