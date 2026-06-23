#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o35-r2-recover-remaining-loader-schema-repair-no-further-mutation.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O35-R2 recover remaining loader schema repair no further mutation" "$DOC"
grep -Fq "FC-O35 failed after it had already written the CT101 profile repair." "$DOC"
grep -Fq "This is a validation-script bug, not a worker-runtime finding." "$DOC"
grep -Fq "read-only CT101 verification" "$DOC"
grep -Fq "read-only CT203 verification" "$DOC"
grep -Fq "It did not perform any further CT101 profile write." "$DOC"

grep -Fq "profile_sha_after_failed_fc_o35_now=bebfb1dcf8fad51681c87fa5b6a8ce5e03df9040cae4f2fa1959a24c88df5740" "$DOC"
grep -Fq "profile_backup_sha_fc_o35_r2=ffcb5278d6a6f470e7f9a1341eaaf2235820880d4677f2c8c4f6bbd3aba95f98" "$DOC"
grep -Fq "worker_sha_now_fc_o35_r2=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"

grep -Fq "worker_required_raw_keys_fc_o35_r2=" "$DOC"
grep -Fq "timeout_seconds" "$DOC"
grep -Fq "exact_marker_supported" "$DOC"
grep -Fq "profile_validation_after_failed_fc_o35_r2_pass=true" "$DOC"
grep -Fq "worker_load_model_profiles_after_failed_fc_o35_r2_pass=true" "$DOC"
grep -Fq "profile_model_name_count_after_failed_fc_o35_r2 gemma4:e4b=1" "$DOC"
grep -Fq "profile_model_name_count_after_failed_fc_o35_r2 gemma3:4b=1" "$DOC"
grep -Fq "profile_model_name_count_after_failed_fc_o35_r2 llama3.2:3b=1" "$DOC"

grep -Fq "OLLAMA_NUM_PARALLEL_fc_o35_r2=2" "$DOC"
grep -Fq "OLLAMA_KEEP_ALIVE_fc_o35_r2=30m" "$DOC"
grep -Fq "active_general_services_fc_o35_r2=0" "$DOC"
grep -Fq "failed_general_units_fc_o35_r2=7" "$DOC"
grep -Fq "FC-O35-R2 did not reset-failed." "$DOC"
grep -Fq "ct101_fc_o35_r2_read_only_acceptance_pass=true" "$DOC"

grep -Fq "quick_check_fc_o35_r2=ok" "$DOC"
grep -Fq "job107_status_fc_o35_r2=queued" "$DOC"
grep -Fq "job107_attempts_fc_o35_r2=0" "$DOC"
grep -Fq "job107_result_rows_fc_o35_r2=0" "$DOC"
grep -Fq "job108_status_fc_o35_r2=queued" "$DOC"
grep -Fq "job111_status_fc_o35_r2=queued" "$DOC"
grep -Fq "jobs107_111_remain_queued_fc_o35_r2=true" "$DOC"
grep -Fq "No runtime occurred during recovery." "$DOC"
grep -Fq "Next recommended stage: rerun job107 only as FC-O36 gemma4 companion_chat one-shot after recovered remaining-loader-schema repair." "$DOC"

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

echo "stage-16-fc-o35-r2 recovery smoke passed"
