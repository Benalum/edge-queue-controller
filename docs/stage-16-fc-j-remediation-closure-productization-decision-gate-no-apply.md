# Stage 16 FC-J remediation closure productization decision gate no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-I2.
- Base HEAD/origin/main: `452ba77`.
- Base tag: `controller-stage-16-fc-i2-jobs92-94-runtime-final-remediation-matrix-2026-06-22`.

## Mutation boundary

This stage is no-apply.

It performed repo evidence review, read-only CT203 baseline verification, and repo docs/smoke only.

It did not:

- write CT203 DB,
- insert, reset, delete, retry, or manually complete jobs,
- mutate CT101 profile files,
- process any jobs,
- start, stop, restart, reload, enable, disable, or reset-failed services,
- start, stop, restart, enable, or disable timers,
- write systemd unit files,
- run daemon-reload,
- activate scheduler services or timers,
- enable persistent workers,
- drain the queue,
- mutate Docker,
- call Ollama/model endpoints,
- pull or download models,
- restart CTs or VMs.

## Mechanical baseline

    quick_check_fc_j=ok
    max_job_id_fc_j=94
    jobs88_94_completed_fc_j=7
    jobs88_94_result_rows_fc_j=7
    jobs81_87_completed_fc_j=7
    jobs81_87_result_rows_fc_j=7
    jobs73_80_completed_fc_j=8
    jobs73_80_result_rows_fc_j=8
    jobs65_72_queued_fc_j=7
    jobs65_72_running_fc_j=1
    jobs65_72_result_rows_fc_j=0
    jobs57_64_existing_fc_j=8
    jobs57_64_completed_fc_j=1
    jobs57_64_running_fc_j=1
    jobs57_64_queued_fc_j=6
    jobs57_64_result_rows_fc_j=1
    ct203_fc_j_read_only_baseline_acceptance_pass=true

## Final FC-I remediation matrix

| Job | Lane | Purpose | Mechanical | Semantic | Decision |
|---|---|---|---:|---:|---|
| 88 | study_tutor | remediation retry | pass | fail | blocked |
| 89 | flashcards | remediation retry | pass | fail | blocked |
| 90 | summary | remediation retry | pass | pass | recovered once; repeatability needed |
| 91 | json_response | remediation retry | pass | pass | recovered once; repeatability needed |
| 92 | safe_refusal | remediation retry | pass | fail | blocked |
| 93 | companion_chat | repeatability control | pass | fail | demoted; repeatability failed |
| 94 | router_label | repeatability control | pass | pass | repeatably passed |

Final FC-I counts:

    jobs88_94_mechanical_pass_count=7
    jobs88_94_semantic_pass_count=3
    jobs88_94_semantic_fail_count=4
    fc_i2_semantic_all_pass=false

## Lane-level decision

### Repeatably passed

- `router_label`

This is the only lane that passed semantic validation in both the original FC-E test and the FC-I repeatability control.

Decision:

- allow future bounded smoke-only follow-up,
- no production activation,
- no scheduler activation,
- no persistent worker enablement,
- no public product route wiring.

### Recovered once, needs repeatability

- `summary`
- `json_response`

These lanes failed in FC-E and passed after stricter FC-I remediation.

Decision:

- do not productize yet,
- run repeatability controls with fresh job IDs before any user-facing route,
- keep validators strict.

### Demoted due repeatability failure

- `companion_chat`

This lane passed in FC-E job81 but failed repeatability in FC-I job93.

Decision:

- no longer treat companion_chat as semantic-smoke stable,
- remediate prompt and model tier,
- retest with fresh job IDs,
- do not wire public companion route.

### Still blocked

- `study_tutor`
- `flashcards`
- `safe_refusal`

These failed original and/or remediation gates.

Decision:

- keep blocked from productization,
- do not wire study/tutor/flashcard/safety-sensitive responses to public routes,
- likely require stronger model tier and/or structured backend output enforcement.

## Productization decision

Do not proceed to production activation.

Do not activate scheduler.

Do not enable persistent workers.

Do not wire companion/study/flashcards public product routes.

Do not claim semantic readiness for failed or non-repeatable lanes.

The queue/runtime path is mechanically proven, but product readiness is not proven.

## Recommended next path

The next safe work should be no-apply design for model tier and output-control strategy.

Recommended next stage: `Stage 16 FC-K`.

Purpose: no-apply model-tier and structured-output remediation plan.

FC-K should define:

- which stronger local models to test for study, flashcards, safe refusal, and companion,
- whether `qwen2.5:0.5b` remains mechanical-smoke-only,
- whether summary and JSON get repeatability jobs,
- whether strict JSON/flashcard output should be backend-enforced instead of model-only,
- fresh job IDs for the next insert batch,
- explicit acceptance criteria before any production route activation.

## Safety gate carried forward

Any future job insert requires explicit approval.

Any future runtime/model call requires explicit approval.

Any scheduler activation requires separate explicit approval.

Any persistent worker enablement requires separate explicit approval.

Any public product route wiring requires separate explicit approval.
