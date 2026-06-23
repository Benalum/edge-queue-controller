#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o40-a-worker-source-authority-implementation-preflight-read-only.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O40-A worker source authority implementation preflight read-only" "$DOC"
grep -Fq "Base HEAD/origin/main: \`5a2f728\`" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O40_A_WORKER_SOURCE_AUTHORITY_IMPLEMENTATION_PREFLIGHT_READ_ONLY_NO_RUNTIME_NO_JOB_MUTATION_NO_RESET_FAILED" "$DOC"

grep -Fq "read-only repo source inspection" "$DOC"
grep -Fq "read-only CT203 queue-state inspection" "$DOC"
grep -Fq "read-only CT101 deployed-worker/profile/systemd inspection" "$DOC"

grep -Fq "deployed_worker_path_fc_o40_a=/opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py" "$DOC"
grep -Fq "deployed_worker_sha_fc_o40_a=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"
grep -Fq "profile_sha_fc_o40_a=bebfb1dcf8fad51681c87fa5b6a8ce5e03df9040cae4f2fa1959a24c88df5740" "$DOC"

grep -Fq "ct203_queue_state_preserved_fc_o40_a=true" "$DOC"
grep -Fq "ct203_fc_o40_a_read_only_acceptance_pass=true" "$DOC"
grep -Fq "ct101_fc_o40_a_read_only_acceptance_pass=true" "$DOC"

grep -Fq "source_authority_classification_fc_o40_a=" "$DOC"
grep -Fq "fc_o40_b_worker_patch_allowed_fc_o40_a=" "$DOC"
grep -Fq "Decision rules:" "$DOC"
grep -Fq "repo_exact_sha_match" "$DOC"
grep -Fq "deployed_worker_not_matched_in_repo" "$DOC"
grep -Fq "multiple_repo_candidates_match_deployed_sha" "$DOC"

grep -Fq "Required FC-O40-B boundary if allowed" "$DOC"
grep -Fq "Still forbidden in FC-O40-B:" "$DOC"
grep -Fq "job processing" "$DOC"
grep -Fq "service start" "$DOC"
grep -Fq "Future FC-O40-B must include a worker file backup" "$DOC"

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

echo "stage-16-fc-o40-a worker source authority preflight smoke passed"
