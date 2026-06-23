#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fb-r4f-install-general-queue-systemd-templates-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FB-R4F install general_queue systemd templates no-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FB_R4F_INSTALL_GENERAL_QUEUE_SYSTEMD_TEMPLATES_NO_RUNTIME" "$DOC"
grep -Fq "Base HEAD/origin/main: \`75e84e3\`" "$DOC"
grep -Fq "installed separate CT101 general_queue systemd templates and ran daemon-reload" "$DOC"
grep -Fq "/etc/systemd/system/edge-ct101-general-queue-job-worker@.service" "$DOC"
grep -Fq "/etc/systemd/system/edge-ct101-general-queue-job-worker@.timer" "$DOC"
grep -Fq "systemctl daemon-reload" "$DOC"
grep -Fq "exact_service_sha_after_general_units_install=16f76e1414def112bbd73f8f1edd0fda23d8a9d796124c44bb982301e9deac8e" "$DOC"
grep -Fq "exact_timer_sha_after_general_units_install=7bf2492ad123b2eb4950f80ec7b0bc412728f05099d18f362f446e4d2e235390" "$DOC"
grep -Fq "EDGE_WORKER_MODE=general_queue" "$DOC"
grep -Fq "EDGE_ALLOWED_JOB_IDS=\"\$JOB_ID\"" "$DOC"
grep -Fq "Unit=edge-ct101-general-queue-job-worker@%i.service" "$DOC"
grep -Fq "general_service_enabled_after_install=static" "$DOC"
grep -Fq "general_timer_enabled_after_install=disabled" "$DOC"
grep -Fq "active_general_services_after_general_units_install=0" "$DOC"
grep -Fq "active_general_timers_after_general_units_install=0" "$DOC"
grep -Fq "ct101_general_queue_units_install_acceptance_pass=true" "$DOC"
grep -Fq "ct203_preservation_after_fb_r4f_general_units_install_acceptance_pass=true" "$DOC"
grep -Fq "job 58 remains running, attempts 1, result rows 0" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FB-R5A\`" "$DOC"

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

echo "stage-16-fb-r4f general_queue systemd templates install smoke passed"
