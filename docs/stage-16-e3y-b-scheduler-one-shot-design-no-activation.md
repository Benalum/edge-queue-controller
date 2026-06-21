# Stage 16 E3Y-B — Scheduler One-Shot Design, No Activation

## Result

E3Y-B completed the scheduler one-shot design step without activation.

Final marker:

    E3Y_B_SCHEDULER_ONE_SHOT_DESIGN_NO_ACTIVATION_OK

## Repo checkpoint

Before this phase:

    HEAD/origin/main/remote: 86db861
    Previous tag: controller-stage-16-e3y-a-scheduler-integration-readiness-plan-no-activation-2026-06-21
    Working tree: clean

## DB readiness

```text
E3Y_B_DB_READINESS=begin
DB_INTEGRITY=ok
JOBS_TOTAL=30
JOB_RESULTS_TOTAL=11
JOB_29_READINESS id=29 status=failed attempts=1 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3v_option_b_atomic_claim_fresh_model_smoke result_rows=0 updated_at=2026-06-21T19:46:39.173248Z
JOB_30_READINESS id=30 status=failed attempts=1 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3w_timeout_safe_one_job_model_smoke result_rows=0 updated_at=2026-06-21T20:04:30.088429Z
JOB_31_READINESS id=31 status=completed attempts=1 model=qwen2.5:0.5b job_type=stage16_e3x_small_model_timeout_safe_completion_smoke result_rows=1 updated_at=2026-06-21T20:31:54.727776Z
E3Y_B_RUNNING_STAGE16_PROOF_JOB_COUNT=0
E3Y_B_QUEUED_STAGE16_PROOF_JOB_COUNT=0
E3Y_B_DB_READINESS_OK
```

## Repo design inputs

```text
E3Y_B_REPO_DESIGN_INPUTS=begin
--- timeout-safe wrapper markers ---
4:# E3X_E_APPROVAL_COMPAT_SHIM_BEGIN
97:  echo "E3W_TIMEOUT_SAFE_WRAPPER_DRY_RUN_ONLY"
300:    print(f"E3W_RUNTIME_ATOMIC_CLAIM_CHANGES={changes}")
318:grep -F "E3W_RUNTIME_ATOMIC_CLAIM_CHANGES=1" "$RUN_DIR/atomic_claim_result.txt"
523:    print("E3W_RUNTIME_COMPLETION_OK")
542:grep -F "E3W_RUNTIME_COMPLETION_OK" "$RUN_DIR/completion_result.txt"
423:  echo "E3W_RUNTIME_INTERNAL_FAILURE_PATH_OK"
430:  echo "E3W_RUNTIME_INTERNAL_FAILURE_PATH_OK"
538:  echo "E3W_RUNTIME_INTERNAL_FAILURE_PATH_OK"
--- candidate scheduler-related files ---
ops/db/apply-default-off-worker-registry-lane-metadata.sh
ops/db/backup-edge-queue-sqlite.sh
ops/db/default-off-worker-registry-lane-metadata.sql
ops/db/verify-edge-queue-sqlite-backup.sh
ops/model/manual-complete-queued-job-via-pveso-adapter.sh
ops/model/operator-dispatch-one-queued-job-via-pveso.sh
ops/scheduler/__pycache__/stage-16-e3s-scheduler-dry-run-artifact-no-db-writes.cpython-312.pyc
ops/scheduler/stage-16-e3s-scheduler-dry-run-artifact-no-db-writes.py
ops/scheduler/stage-16-e3v-run-one-existing-status-atomic-claim-dispatch.sh
ops/scheduler/stage-16-e3w-timeout-safe-one-job-dispatch.sh
ops/smoke/check-ct101-dormant-laptop-queue-client.sh
ops/smoke/check-ct101-dormant-worker-path-plan.sh
ops/smoke/check-ct101-laptop-queue-one-shot-worker.sh
ops/smoke/check-ct101-laptop-queue-readonly-connectivity.sh
ops/smoke/check-ct101-laptop-queue-synthetic-lifecycle.sh
ops/smoke/check-ct101-real-ollama-laptop-queue-plan.sh
ops/smoke/check-ct101-worker-laptop-queue-integration-plan.sh
ops/smoke/check-ct101-worker-token-prep.sh
ops/smoke/check-frontend-queued-chat-app-flag-detection.sh
ops/smoke/check-frontend-queued-chat-assistant-placeholder-branch.sh
ops/smoke/check-frontend-queued-chat-assistant-placeholder-mock-test.sh
ops/smoke/check-frontend-queued-chat-config-flag.sh
ops/smoke/check-frontend-queued-chat-disabled-send-branch.sh
ops/smoke/check-frontend-queued-chat-disabled-submit-path.sh
ops/smoke/check-frontend-queued-chat-first-wiring-plan.sh
ops/smoke/check-frontend-queued-chat-flag-off-live-submit-preservation.sh
ops/smoke/check-frontend-queued-chat-flag-off-live-submit-regression.sh
ops/smoke/check-frontend-queued-chat-flag-on-submit-orchestration-harness.sh
ops/smoke/check-frontend-queued-chat-flag-on-submit-wiring-plan.sh
ops/smoke/check-frontend-queued-chat-guarded-live-submit-branch-skeleton-mock-test.sh
ops/smoke/check-frontend-queued-chat-guarded-live-submit-branch-skeleton.sh
ops/smoke/check-frontend-queued-chat-guarded-live-submit-gate-mock-test.sh
ops/smoke/check-frontend-queued-chat-guarded-live-submit-gate-rollback.sh
ops/smoke/check-frontend-queued-chat-guarded-live-submit-gate.sh
ops/smoke/check-frontend-queued-chat-guarded-live-submit-readiness-mock-test.sh
ops/smoke/check-frontend-queued-chat-guarded-live-submit-readiness.sh
ops/smoke/check-frontend-queued-chat-guarded-submit-skeleton-mock-test.sh
ops/smoke/check-frontend-queued-chat-guarded-submit-skeleton.sh
ops/smoke/check-frontend-queued-chat-helper-import.sh
ops/smoke/check-frontend-queued-chat-live-submit-prewiring-go-no-go.sh
ops/smoke/check-frontend-queued-chat-live-submit-wiring-dry-run-harness.sh
ops/smoke/check-frontend-queued-chat-live-submit-wiring-implementation-plan.sh
ops/smoke/check-frontend-queued-chat-polling-plan.sh
ops/smoke/check-frontend-queued-chat-send-helper-mock-test.sh
ops/smoke/check-frontend-queued-chat-status-helper.sh
ops/smoke/check-frontend-queued-chat-status-poll-helper-branch.sh
ops/smoke/check-frontend-queued-chat-status-poll-helper-mock-test.sh
ops/smoke/check-frontend-queued-chat-submit-decision-branch.sh
ops/smoke/check-frontend-queued-chat-submit-decision-mock-test.sh
ops/smoke/check-frontend-queued-chat-submit-disabled-rollback.sh
ops/smoke/check-frontend-queued-chat-submit-dry-run-branch.sh
ops/smoke/check-frontend-queued-chat-submit-dry-run-mock-test.sh
ops/smoke/check-frontend-queued-chat-submit-orchestration-branch.sh
ops/smoke/check-frontend-queued-chat-submit-orchestration-mock-test.sh
ops/smoke/check-frontend-queued-chat-submit-orchestration-plan.sh
ops/smoke/check-frontend-queued-chat-submit-payload-builder-branch.sh
ops/smoke/check-frontend-queued-chat-submit-payload-builder-mock-test.sh
ops/smoke/check-frontend-queued-chat-submit-prewiring-readiness-map.sh
ops/smoke/check-frontend-queued-chat-ui-wiring-map.sh
ops/smoke/check-laptop-job-queue-facade-plan.sh
ops/smoke/check-laptop-queue-heartbeat-recovery-plan.sh
ops/smoke/check-laptop-queue-helper.sh
ops/smoke/check-laptop-queue-idempotent-completion.sh
ops/smoke/check-laptop-queue-internal-api.sh
ops/smoke/check-laptop-queue-synthetic-recovery.sh
ops/smoke/check-laptop-queue-token-hardening.sh
ops/smoke/check-laptop-queue-worker-register-heartbeat.sh
ops/smoke/check-opt-in-queued-chat-route-plan.sh
ops/smoke/check-phase-11h-companion-queued-ollama-timeout-inspection.sh
ops/smoke/check-phase-11r-model-lane-routing-contract.sh
ops/smoke/check-phase-11s-live-model-lane-metadata-activation.sh
ops/smoke/check-phase-11t-lane-aware-queue-status-visibility.sh
ops/smoke/check-phase-11u-live-lane-aware-status-activation.sh
ops/smoke/check-phase-11v-lane-aware-worker-claim-source-map.sh
ops/smoke/check-phase-11w-optional-queue-lane-claim-support.sh
ops/smoke/check-phase-11x-live-optional-queue-lane-claim-endpoint-activation.sh
ops/smoke/check-phase-11y-ct101-worker-side-lane-claim-source-map.sh
ops/smoke/check-phase-11z-ct101-worker-repo-versioning-before-dormant-lane-patch.sh
ops/smoke/check-phase-12a-ct101-dormant-worker-queue-lane-patch.sh
ops/smoke/check-phase-12c-ct101-dormant-worker-capacity-metadata.sh
--- service activation guards seen in docs/smokes ---
docs/phase-14j-br-batched-static-contract-inventory-and-first-safe-patch-candidates.md:365:NO scheduler activation
docs/phase-14j-cc-second-static-patch-verification-and-active-source-baseline-update.md:85:NO scheduler activation
docs/phase-14j-bk-runtime-activation-preflight-checklist-and-rollback-verification-plan.md:73:- Do not activate scheduler lane dispatch.
docs/stage-16-e3p-d-r7-completion-recovery-docs-no-rerun.md:100:Do not activate scheduler or persistent workers yet.
docs/stage-16-e3p-e-controlled-dispatch-checkpoint-handoff.md:84:Do not activate scheduler or persistent workers yet.
docs/phase-14j-ca-static-ui-patch-verification-and-milestone-decision.md:85:NO scheduler activation
docs/phase-14j-bx-controller-owned-active-source-ui-map.md:68:NO scheduler activation
docs/phase-14j-bw-active-source-only-ui-route-candidate-batch.md:87:NO scheduler activation
docs/phase-14j-ce-third-static-patch-verification-and-safe-batch-rollup.md:88:NO scheduler activation
docs/phase-14j-bu-smoke-noise-hardening-and-fast-static-baseline.md:132:NO scheduler activation
docs/phase-14j-bu-smoke-noise-hardening-and-fast-static-baseline.md:206:NO scheduler activation
docs/phase-14j-bu-smoke-noise-hardening-and-fast-static-baseline.md:271:NO scheduler activation
docs/phase-14j-bw-controller-owned-static-ui-patch-candidate-index.md:90:NO scheduler activation
docs/stage-16-e3y-a-scheduler-integration-readiness-plan-no-activation.md:1062:ops/smoke/check-phase-14j-safe-static-concise-baseline.sh:11:echo "NO scheduler activation"
docs/stage-16-e3y-a-scheduler-integration-readiness-plan-no-activation.md:1073:ops/smoke/check-phase-14j-br-runtime-parked-surface-static-contracts.sh:11:echo "NO scheduler activation"
docs/stage-16-e3y-a-scheduler-integration-readiness-plan-no-activation.md:1082:ops/smoke/check-phase-14j-safe-static-ultra-concise-v4-baseline.sh:11:echo "NO scheduler activation"
docs/stage-16-e3y-a-scheduler-integration-readiness-plan-no-activation.md:1135:ops/smoke/check-stage-16-e3p-d-r7-completion-recovery-docs-no-rerun.sh:46:must_contain 'Do not activate scheduler or persistent workers yet.'
docs/stage-16-e3y-a-scheduler-integration-readiness-plan-no-activation.md:1209:ops/smoke/check-phase-14j-safe-static-baseline.sh:11:echo "NO scheduler activation"
docs/stage-16-e3y-a-scheduler-integration-readiness-plan-no-activation.md:1251:9. Persistent workers remain disabled until after scheduler one-shot proof.
docs/phase-14j-bs-batched-static-smoke-coverage-and-safe-ui-contract-candidates.md:283:NO scheduler activation
docs/phase-14j-bv-active-static-inventory-hardening-and-concise-baseline.md:265:NO scheduler activation
docs/phase-14j-bv-active-static-inventory-hardening-and-concise-baseline.md:339:NO scheduler activation
docs/phase-14j-ai-default-off-worker-registration-metadata-write-contract.md:86:9. Do not activate scheduler lane dispatch in the same phase as a registration write patch.
ops/smoke/check-phase-14j-safe-static-concise-baseline.sh:11:echo "NO scheduler activation"
ops/smoke/check-phase-14j-br-runtime-parked-surface-static-contracts.sh:11:echo "NO scheduler activation"
ops/smoke/check-phase-14j-safe-static-ultra-concise-v4-baseline.sh:11:echo "NO scheduler activation"
ops/smoke/check-stage-16-e3p-d-r7-completion-recovery-docs-no-rerun.sh:46:must_contain 'Do not activate scheduler or persistent workers yet.'
ops/smoke/check-stage-16-e3y-a-scheduler-integration-readiness-plan-no-activation.sh:40:grep -F "Persistent workers remain disabled" "$DOC"
ops/smoke/check-phase-14j-safe-static-baseline.sh:11:echo "NO scheduler activation"
ops/smoke/check-phase-14j-cc-cb-static-ui-route-patch-post-verify.sh:11:echo "NO scheduler activation"
ops/smoke/check-phase-14j-ca-bz-static-ui-patch-post-verify.sh:11:echo "NO scheduler activation"
ops/smoke/check-phase-14j-safe-static-fast-baseline.sh:11:echo "NO scheduler activation"
ops/smoke/check-phase-14j-safe-static-ultra-concise-v2-baseline.sh:11:echo "NO scheduler activation"
ops/smoke/check-stage-16-e3p-e-controlled-dispatch-checkpoint-handoff.sh:44:must_contain "Do not activate scheduler or persistent workers yet."
ops/smoke/check-phase-14j-ce-cd-static-ui-gateway-patch-post-verify.sh:11:echo "NO scheduler activation"
ops/smoke/check-phase-14j-safe-static-ultra-concise-baseline.sh:11:echo "NO scheduler activation"
ops/smoke/check-phase-14j-safe-static-ultra-concise-v3-baseline.sh:11:echo "NO scheduler activation"
ops/smoke/check-phase-14j-bw-active-source-only-ui-route-inventory.sh:11:echo "NO scheduler activation"
ops/smoke/check-phase-14j-bs-parked-runtime-no-touch-contract.sh:11:echo "NO scheduler activation"
ops/smoke/check-phase-14j-bx-active-source-ui-map-inventory.sh:11:echo "NO scheduler activation"
E3Y_B_WRAPPER_READY_FOR_ONE_SHOT_DELEGATION=true
E3Y_B_SCHEDULER_ACTIVATION_REMAINS_BLOCKED=true
E3Y_B_PERSISTENT_WORKER_ACTIVATION_REMAINS_BLOCKED=true
E3Y_B_REPO_DESIGN_INPUTS_OK
```

## Design goal

Introduce a manually invoked one-shot scheduler path that selects exactly one fresh eligible job and delegates execution to the proven timeout-safe wrapper.

This is not persistent scheduler activation.

This is not persistent worker activation.

## Proven primitive to reuse

The one-shot scheduler must delegate to:

    ops/scheduler/stage-16-e3w-timeout-safe-one-job-dispatch.sh

The wrapper already proves:

1. read-only candidate preflight
2. atomic claim
3. attempts increment only on successful claim
4. bounded model call
5. completion transaction with exactly one job_results row
6. internal failure update if model call fails
7. no job left running after wrapper exit
8. phase-specific approval shim support

## Proposed one-shot scheduler contract

Name:

    ops/scheduler/stage-16-e3y-one-shot-scheduler-dispatch.sh

Modes:

    --dry-run
    --run

Expected environment:

    E3Y_EXPECTED_JOB_ID=<fresh job id>
    E3Y_EXPECTED_MODEL=qwen2.5:0.5b
    E3Y_EXPECTED_JOB_TYPE=stage16_e3y_scheduler_one_shot_small_model_completion_smoke
    E3Y_REQUIRED_APPROVAL=APPROVE_STAGE_16_E3Y_E_RUN_ONE_SHOT_SCHEDULER_SMALL_MODEL_JOB_ONLY
    E3Y_APPROVAL=APPROVE_STAGE_16_E3Y_E_RUN_ONE_SHOT_SCHEDULER_SMALL_MODEL_JOB_ONLY

Dry-run behavior:

1. Verify repo clean.
2. Verify scheduler/persistent worker services are not being activated.
3. Read-only DB preflight.
4. Confirm exactly one eligible fresh job matches the expected id/model/job_type.
5. Confirm no running Stage 16 proof jobs exist.
6. Confirm PVESO model host is ready.
7. Print:

       E3Y_ONE_SHOT_SCHEDULER_DRY_RUN_WOULD_SELECT_JOB

8. Do not claim the job.
9. Do not call the model.
10. Do not mutate DB.

Run behavior:

1. Require exact approval.
2. Re-run all dry-run checks.
3. Delegate to the timeout-safe wrapper with:

       E3W_REQUIRED_APPROVAL=APPROVE_STAGE_16_E3X_E_RUN_ONE_SMALL_MODEL_TIMEOUT_SAFE_JOB_ONLY
       E3W_APPROVAL=APPROVE_STAGE_16_E3X_E_RUN_ONE_SMALL_MODEL_TIMEOUT_SAFE_JOB_ONLY
       E3W_EXPECTED_JOB_ID=$E3Y_EXPECTED_JOB_ID
       E3W_EXPECTED_MODEL=$E3Y_EXPECTED_MODEL
       E3W_EXPECTED_JOB_TYPE=$E3Y_EXPECTED_JOB_TYPE

4. Allow exactly one wrapper invocation.
5. After wrapper exit, read-only postflight must classify:
   - completed_with_one_result, or
   - internal_failure_no_result
6. Refuse if the job remains running.
7. Refuse if more than one job_results row exists for the job.

## Fresh proof sequence

### E3Y-C — insert one fresh scheduler-selected proof job

Requires explicit approval because this writes one DB job.

Approval phrase:

    APPROVE_STAGE_16_E3Y_C_INSERT_ONE_FRESH_SCHEDULER_SELECTED_SMALL_MODEL_JOB_ONLY

Expected job:

    requested_model=qwen2.5:0.5b
    job_type=stage16_e3y_scheduler_one_shot_small_model_completion_smoke
    status=queued
    attempts=0
    result_rows=0

### E3Y-D — implement one-shot scheduler wrapper, no run

Repo code/docs/smoke only.

No DB write. No model call. No scheduler activation.

### E3Y-E — dry-run one-shot scheduler would select fresh job

No DB write. No claim. No model call.

### E3Y-F — approved one-shot scheduler runtime proof

Requires explicit approval.

Allowed exactly:

- one scheduler one-shot invocation
- one timeout-safe wrapper delegation
- one bounded PVESO Ollama model call
- one completion transaction or one internal failure update

Still disallowed:

- persistent scheduler activation
- persistent workers
- service enable/start/restart/reload

## Safety boundary

E3Y-B did not:

- write the DB
- insert a job
- claim a job
- change job status
- increment attempts
- insert job_results
- execute the wrapper
- activate scheduler
- activate persistent workers
- call a model
- pull a model
- start CT101
- kill any process
- mutate services, CTs, VMs, Cloudflare, or private storage

## Hard rules

Do not rerun E3V-Q.

Do not retry job 29.

Do not rerun job 30.

Do not rerun job 31 without a new explicit plan and approval.
