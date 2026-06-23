#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fb-r4c-deploy-updated-ct101-worker-file-only-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FB-R4C deploy updated CT101 worker file only no-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FB_R4C_DEPLOY_UPDATED_CT101_WORKER_FILE_ONLY_NO_RUNTIME" "$DOC"
grep -Fq "Base HEAD/origin/main: \`2c6e82b\`" "$DOC"
grep -Fq "deployed the updated worker file to CT101 only" "$DOC"
grep -Fq "Old CT101 worker expected sha: \`69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f\`" "$DOC"
grep -Fq "New CT101 worker expected sha: \`25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca\`" "$DOC"
grep -Fq "CT101 worker sha after deploy: \`25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca\`" "$DOC"
grep -Fq "ct101_pre_deploy_default_off_acceptance_pass=true" "$DOC"
grep -Fq "ct101_worker_deploy_acceptance_pass=true" "$DOC"
grep -Fq "ct101_post_deploy_default_off_acceptance_pass=true" "$DOC"
grep -Fq "active_exact_job_services_after_deploy=0" "$DOC"
grep -Fq "active_exact_job_timers_after_deploy=0" "$DOC"
grep -Fq "job58_service_active_after_deploy=failed" "$DOC"
grep -Fq "job58_service_result_after_deploy=exit-code" "$DOC"
grep -Fq "ct203_preservation_after_fb_r4c_deploy_acceptance_pass=true" "$DOC"
grep -Fq "CT101 now has the updated worker source containing \`EDGE_WORKER_MODE=general_queue\`." "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FB-R4D\`" "$DOC"

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

echo "stage-16-fb-r4c deploy worker file only smoke passed"
