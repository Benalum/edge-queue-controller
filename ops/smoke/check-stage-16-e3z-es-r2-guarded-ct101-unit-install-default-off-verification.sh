#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-es-r2-guarded-ct101-unit-install-default-off-verification.md"

test -f "$DOC"

grep -Fq "Stage 16 E3Z-ES-R2 guarded CT101 unit install default-off verification" "$DOC"
grep -Fq "Base HEAD/origin/main: \`de99901\`" "$DOC"
grep -Fq "APPROVE_STAGE_16_E3Z_ES_INSTALL_GUARDED_CT101_TIMER_SERVICE_UNITS_DEFAULT_OFF_NO_START_NO_ENABLE" "$DOC"
grep -Fq "R1 failed after installation, but failed safely" "$DOC"
grep -Fq "R2 performed post-install verification through inactive instance names and did not write the unit files again." "$DOC"
grep -Fq "Service template: \`edge-ct101-exact-job-worker@.service\`" "$DOC"
grep -Fq "Timer template: \`edge-ct101-exact-job-worker@.timer\`" "$DOC"
grep -Fq "EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml" "$DOC"
grep -Fq 'EDGE_ALLOWED_JOB_IDS="$JOB_ID"' "$DOC"
grep -Fq 'Unit=edge-ct101-exact-job-worker@%i.service' "$DOC"
grep -Fq "systemd_analyze_verify_rc=0" "$DOC"
grep -Fq "r2_acceptance_pass=true" "$DOC"
grep -Fq "active_exact_job_units_after=0" "$DOC"
grep -Fq "ct101_queue_timer_rows_after=0" "$DOC"
grep -Fq "edge_service_after_active=inactive" "$DOC"
grep -Fq "edge_service_after_enabled=disabled" "$DOC"
grep -Fq "jobs_37_52_completed_with_one_result_after_es_r1=16" "$DOC"
grep -Fq "E3Z-ES-R2 passed." "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 E3Z-ET\`" "$DOC"

# The doc must not contain raw private or Tailscale IP addresses.
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

echo "stage-16-e3z-es-r2 guarded unit install verification smoke passed"
