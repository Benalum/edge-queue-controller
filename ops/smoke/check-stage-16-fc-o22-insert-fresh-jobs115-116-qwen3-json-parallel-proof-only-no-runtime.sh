#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o22-insert-fresh-jobs115-116-qwen3-json-parallel-proof-only-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O22 insert fresh jobs115-116 qwen3 JSON parallel proof only no-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O22_INSERT_FRESH_JOBS115_116_QWEN3_JSON_PARALLEL_PROOF_ONLY_NO_RUNTIME_NO_OLD_JOB_MUTATION" "$DOC"
grep -Fq "Base HEAD/origin/main: \`4e56bd8\`" "$DOC"

grep -Fq "mutated only the CT203 DB by inserting two fresh queued qwen3 JSON parallel proof jobs: jobs115 and 116" "$DOC"
grep -Fq "db_backup_path_fc_o22=" "$DOC"
grep -Fq "db_backup_sha_fc_o22=" "$DOC"

grep -Fq "| 115 | 114 | stage16_fc_json_semantic_probe | qwen3:1.7b | queued | 0 | 0 |" "$DOC"
grep -Fq "| 116 | 114 | stage16_fc_json_semantic_probe | qwen3:1.7b | queued | 0 | 0 |" "$DOC"
grep -Fq "inserted_job_ids_fc_o22=115,116" "$DOC"
grep -Fq "job115_status_fc_o22=queued" "$DOC"
grep -Fq "job116_status_fc_o22=queued" "$DOC"
grep -Fq "job115_attempts_fc_o22=0" "$DOC"
grep -Fq "job116_attempts_fc_o22=0" "$DOC"
grep -Fq "job115_result_rows_fc_o22=0" "$DOC"
grep -Fq "job116_result_rows_fc_o22=0" "$DOC"
grep -Fq "max_job_id_after_fc_o22=116" "$DOC"
grep -Fq "ct203_fc_o22_insert_acceptance_pass=true" "$DOC"

grep -Fq "job105_status_after_fc_o22=running" "$DOC"
grep -Fq "job106_status_after_fc_o22=completed" "$DOC"
grep -Fq "jobs107_111_remain_queued_attempts0_rows0=true" "$DOC"
grep -Fq "job114_status_after_fc_o22=completed" "$DOC"

grep -Fq "profile_sha_fc_o22=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899" "$DOC"
grep -Fq "worker_sha_fc_o22=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"
grep -Fq "ollama_container_health_fc_o22=healthy" "$DOC"
grep -Fq "OLLAMA_NUM_PARALLEL_fc_o22=2" "$DOC"
grep -Fq "active_exact_services_fc_o22=0" "$DOC"
grep -Fq "active_general_services_fc_o22=0" "$DOC"
grep -Fq "failed_general_units_fc_o22=6" "$DOC"
grep -Fq "ct101_fc_o22_read_only_acceptance_pass=true" "$DOC"

grep -Fq "Fresh qwen3 JSON parallel proof jobs115 and 116 are queued." "$DOC"
grep -Fq "Do not run bulk jobs." "$DOC"
grep -Fq "Do not enable persistent workers." "$DOC"
grep -Fq "edge-ct101-general-queue-job-worker@115.service" "$DOC"
grep -Fq "edge-ct101-general-queue-job-worker@116.service" "$DOC"
grep -Fq "That runtime proof must use separate explicit approval." "$DOC"

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

echo "stage-16-fc-o22 insert fresh jobs115-116 smoke passed"
