#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o40-b-r4-recover-product-visible-output-worker-support-deploy-no-job-processing.md"
WORKER="ops/workers/ct101_minimal_ollama_worker.py"
CONTRACT_SMOKE="ops/smoke/check-stage-16-fc-o40-b-r3-product-visible-output-worker-contract.py"

test -f "$DOC"
test -f "$WORKER"
test -x "$CONTRACT_SMOKE"

grep -Fq "Stage 16 FC-O40-B-R4 recover product visible output worker support deploy no job processing" "$DOC"
grep -Fq "Base HEAD/origin/main: \`2cd7355\`" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O40_B_APPLY_PRODUCT_VISIBLE_OUTPUT_WORKER_SUPPORT_AND_TESTS_NO_JOB_PROCESSING_NO_PROFILE_POLICY_MUTATION_NO_RESET_FAILED" "$DOC"

grep -Fq "R4 used the already-patched and already-tested repo worker from R3" "$DOC"
grep -Fq "repo_worker_path_fc_o40_b_r4=ops/workers/ct101_minimal_ollama_worker.py" "$DOC"
grep -Fq "old_repo_worker_sha_fc_o40_b_r4=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"
grep -Fq "new_repo_worker_sha_fc_o40_b_r4=302f8c0e6efdc9dfee597373b9fa9fdfc010dc291ef45fc91f1c6ce045d3add4" "$DOC"
grep -Fq "new_deployed_worker_sha_fc_o40_b_r4=302f8c0e6efdc9dfee597373b9fa9fdfc010dc291ef45fc91f1c6ce045d3add4" "$DOC"
grep -Fq "worker_backup_path_fc_o40_b_r4=" "$DOC"
grep -Fq "worker_backup_sha_fc_o40_b_r4=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"

grep -Fq "product_visible_output_v1" "$DOC"
grep -Fq "ProductValidationResult" "$DOC"
grep -Fq "validate_product_visible_output" "$DOC"
grep -Fq "build_product_response_json" "$DOC"
grep -Fq "build_completion_payload" "$DOC"
grep -Fq "REFUSE_PRODUCT_VISIBLE_THINKING" "$DOC"
grep -Fq "REFUSE_PRODUCT_GUARD_JSON" "$DOC"
grep -Fq "Existing exact_marker_only tests still pass." "$DOC"
grep -Fq "CT101 deployed worker import tests also passed." "$DOC"

grep -Fq "active_general_services_after_deploy_fc_o40_b_r4=0" "$DOC"
grep -Fq "active_general_timers_after_deploy_fc_o40_b_r4=0" "$DOC"
grep -Fq "ct101_fc_o40_b_r4_worker_deploy_acceptance_pass=true" "$DOC"
grep -Fq "No failed-unit evidence was cleared." "$DOC"

grep -Fq "job108=queued,0,0" "$DOC"
grep -Fq "job111=queued,0,0" "$DOC"
grep -Fq "Product profiles still retain their previous policy until FC-O41." "$DOC"
grep -Fq "Next recommended stage: FC-O41 product profile policy update only, no job processing." "$DOC"

grep -Fq "product_visible_output_v1" "$WORKER"
grep -Fq "REFUSE_PRODUCT_VISIBLE_THINKING" "$WORKER"
grep -Fq "validate_product_visible_output" "$WORKER"
grep -Fq "build_completion_payload" "$WORKER"
grep -Fq "exact_marker_only" "$WORKER"
grep -Fq "stage-16-e3z-ec-worker-guards" "$WORKER"

python3 -m py_compile "$WORKER"
"$CONTRACT_SMOKE"

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

echo "stage-16-fc-o40-b-r4 product visible output worker support smoke passed"
