#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o19-insert-fresh-job114-qwen3-json-post-concurrency-proof-only-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O19 insert fresh job114 qwen3 JSON post-concurrency proof only no-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O19_INSERT_FRESH_JOB114_QWEN3_JSON_POST_CONCURRENCY_PROOF_ONLY_NO_RUNTIME_NO_OLD_JOB_MUTATION" "$DOC"
grep -Fq "Base HEAD/origin/main: \`285c8ae\`" "$DOC"

grep -Fq "mutated only the CT203 DB by inserting one fresh queued qwen3 JSON post-concurrency proof job: job114" "$DOC"
grep -Fq "db_backup_path_fc_o19=" "$DOC"
grep -Fq "db_backup_sha_fc_o19=" "$DOC"

grep -Fq "| 114 | 106 | stage16_fc_json_semantic_probe | qwen3:1.7b | queued | 0 | 0 |" "$DOC"
grep -Fq "inserted_job_ids_fc_o19=114" "$DOC"
grep -Fq "job114_status_fc_o19=queued" "$DOC"
grep -Fq "job114_attempts_fc_o19=0" "$DOC"
grep -Fq "job114_result_rows_fc_o19=0" "$DOC"
grep -Fq "max_job_id_after_fc_o19=114" "$DOC"
grep -Fq "ct203_fc_o19_insert_acceptance_pass=true" "$DOC"

grep -Fq "job105_status_after_fc_o19=running" "$DOC"
grep -Fq "job106_status_after_fc_o19=completed" "$DOC"
grep -Fq "jobs107_111_remain_queued_attempts0_rows0=true" "$DOC"
grep -Fq "job113_status_after_fc_o19=completed" "$DOC"

grep -Fq "profile_sha_fc_o19=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899" "$DOC"
grep -Fq "worker_sha_fc_o19=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"
grep -Fq "ollama_container_health_fc_o19=healthy" "$DOC"
grep -Fq "OLLAMA_NUM_PARALLEL_fc_o19=2" "$DOC"
grep -Fq "active_exact_services_fc_o19=0" "$DOC"
grep -Fq "active_general_services_fc_o19=0" "$DOC"
grep -Fq "failed_general_units_fc_o19=6" "$DOC"
grep -Fq "ct101_fc_o19_read_only_acceptance_pass=true" "$DOC"

grep -Fq "Fresh qwen3 JSON post-concurrency proof job114 is queued." "$DOC"
grep -Fq "Do not run bulk jobs." "$DOC"
grep -Fq "Do not enable persistent workers." "$DOC"
grep -Fq "The next stage should run job114 only" "$DOC"

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

echo "stage-16-fc-o19 insert fresh job114 smoke passed"
