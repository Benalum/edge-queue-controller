#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o18-apply-ollama-num-parallel-2-only.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O18 apply Ollama NUM_PARALLEL=2 only" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O18_APPLY_OLLAMA_NUM_PARALLEL_2_ONLY_NO_PROFILE_CHANGE_NO_PERSISTENT_WORKER_NO_BULK_QUEUE_DRAIN" "$DOC"
grep -Fq "Base HEAD/origin/main: \`3baf555\`" "$DOC"

grep -Fq "OLLAMA_NUM_PARALLEL_before_fc_o18=1" "$DOC"
grep -Fq "OLLAMA_NUM_PARALLEL_after_fc_o18=2" "$DOC"
grep -Fq "compose_override_path_fc_o18=" "$DOC"
grep -Fq "compose_override_sha_fc_o18=" "$DOC"
grep -Fq "backup_dir_fc_o18=" "$DOC"

grep -Fq "ollama_container_state_after_fc_o18=running" "$DOC"
grep -Fq "ollama_container_health_after_fc_o18=healthy" "$DOC"

grep -Fq "profile_sha_after_fc_o18=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899" "$DOC"
grep -Fq "worker_sha_after_fc_o18=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"
grep -Fq "active_exact_services_after_fc_o18=0" "$DOC"
grep -Fq "active_general_services_after_fc_o18=0" "$DOC"
grep -Fq "ct101_fc_o18_apply_acceptance_pass=true" "$DOC"

grep -Fq "quick_check_after_fc_o18=ok" "$DOC"
grep -Fq "job105_status_after_fc_o18=running" "$DOC"
grep -Fq "job106_status_after_fc_o18=completed" "$DOC"
grep -Fq "jobs107_111_remain_queued_attempts0_rows0=true" "$DOC"
grep -Fq "job113_status_after_fc_o18=completed" "$DOC"
grep -Fq "ct203_post_fc_o18_no_job_processing_acceptance_pass=true" "$DOC"

grep -Fq "CT203 remains the durable queue and claim authority." "$DOC"
grep -Fq "Do not enable persistent workers or bulk queue draining yet." "$DOC"
grep -Fq "insert one fresh qwen3 proof job after the concurrency change" "$DOC"

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

echo "stage-16-fc-o18 ollama num parallel 2 apply smoke passed"
