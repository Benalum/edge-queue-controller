#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o36-r3-recover-job107-completed-after-timeout-read-only.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O36-R3 recover job107 completed after timeout read-only" "$DOC"
grep -Fq "FC-O36 timed out at the PPB layer" "$DOC"
grep -Fq "FC-O36-R2 used an incorrect no-runtime assumption" "$DOC"
grep -Fq "read-only CT203 verification and result classification" "$DOC"
grep -Fq "read-only CT101 verification" "$DOC"
grep -Fq "It did not:" "$DOC"
grep -Fq "run jobs again" "$DOC"
grep -Fq "start services" "$DOC"

grep -Fq "quick_check_fc_o36_r3=ok" "$DOC"
grep -Fq "job107_job_type_fc_o36_r3=stage16_fc_companion_chat_semantic_probe" "$DOC"
grep -Fq "job107_requested_model_fc_o36_r3=gemma4:e4b" "$DOC"
grep -Fq "job107_status_fc_o36_r3=completed" "$DOC"
grep -Fq "job107_attempts_fc_o36_r3=1" "$DOC"
grep -Fq "job107_result_rows_fc_o36_r3=1" "$DOC"
grep -Fq "job107_mechanical_pass_fc_o36_r3=true" "$DOC"
grep -Fq "job107_output_hygiene_pass_fc_o36_r3=" "$DOC"
grep -Fq "job107_semantic_pass_fc_o36_r3=" "$DOC"
grep -Fq "job107_product_surface_candidate_fc_o36_r3=" "$DOC"
grep -Fq "job107_completed_after_timeout_fc_o36_r3=true" "$DOC"
grep -Fq "preserved_unrelated_jobs_fc_o36_r3=true" "$DOC"
grep -Fq "ct203_fc_o36_r3_read_only_acceptance_pass=true" "$DOC"

grep -Fq "Jobs108-111 remained queued attempts=0 rows=0." "$DOC"
grep -Fq "profile_sha_fc_o36_r3=bebfb1dcf8fad51681c87fa5b6a8ce5e03df9040cae4f2fa1959a24c88df5740" "$DOC"
grep -Fq "worker_sha_fc_o36_r3=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"
grep -Fq "OLLAMA_NUM_PARALLEL_fc_o36_r3=2" "$DOC"
grep -Fq "active_general_services_fc_o36_r3=0" "$DOC"
grep -Fq "unit107_latest_result_fc_o36_r3=" "$DOC"
grep -Fq "ct101_fc_o36_r3_read_only_acceptance_pass=true" "$DOC"
grep -Fq "FC-O36-R3 did not reset-failed." "$DOC"

grep -Fq "Job107 did complete after the FC-O36 PPB timeout." "$DOC"
grep -Fq "Next recommended stage depends on classification:" "$DOC"

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

echo "stage-16-fc-o36-r3 completed-after-timeout recovery smoke passed"
