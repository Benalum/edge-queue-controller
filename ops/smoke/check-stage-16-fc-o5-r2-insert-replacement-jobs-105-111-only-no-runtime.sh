#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o5-r2-insert-replacement-jobs-105-111-only-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O5-R2 insert replacement jobs 105-111 only no-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O5_INSERT_REPLACEMENT_JOBS_105_111_ONLY_NO_RUNTIME_NO_OLD_JOB_MUTATION" "$DOC"
grep -Fq "previous pasted block was an old FC-D block" "$DOC"
grep -Fq "Base HEAD/origin/main: \`610bc71\`" "$DOC"

grep -Fq "This stage mutated only the CT203 DB by inserting seven fresh queued replacement jobs." "$DOC"
grep -Fq "db_backup_path_fc_o5_r2=" "$DOC"
grep -Fq "db_backup_sha_fc_o5_r2=" "$DOC"

grep -Fq "| 105 | 97 | stage16_fc_summary_semantic_probe | qwen3:1.7b | queued | 0 | 0 |" "$DOC"
grep -Fq "| 106 | 99 | stage16_fc_json_semantic_probe | qwen3:1.7b | queued | 0 | 0 |" "$DOC"
grep -Fq "| 107 | 100 | stage16_fc_companion_chat_semantic_probe | gemma4:e4b | queued | 0 | 0 |" "$DOC"
grep -Fq "| 108 | 101 | stage16_fc_companion_chat_semantic_probe | gemma3:4b | queued | 0 | 0 |" "$DOC"
grep -Fq "| 109 | 102 | stage16_fc_study_tutor_semantic_probe | gemma4:e4b | queued | 0 | 0 |" "$DOC"
grep -Fq "| 110 | 103 | stage16_fc_flashcards_semantic_probe | gemma4:e4b | queued | 0 | 0 |" "$DOC"
grep -Fq "| 111 | 104 | stage16_fc_safe_refusal_semantic_probe | llama3.2:3b | queued | 0 | 0 |" "$DOC"

grep -Fq "inserted_job_ids_fc_o5_r2=105,106,107,108,109,110,111" "$DOC"
grep -Fq "jobs105_111_queued_fc_o5_r2=7" "$DOC"
grep -Fq "jobs105_111_result_rows_fc_o5_r2=0" "$DOC"
grep -Fq "ct203_fc_o5_r2_insert_acceptance_pass=true" "$DOC"
grep -Fq "ct101_fc_o5_r2_read_only_acceptance_pass=true" "$DOC"
grep -Fq "No old job was reset or mutated." "$DOC"
grep -Fq "Do not run them in bulk." "$DOC"
grep -Fq "The next stage should run job105 only" "$DOC"

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

echo "stage-16-fc-o5-r2 insert replacement jobs smoke passed"
