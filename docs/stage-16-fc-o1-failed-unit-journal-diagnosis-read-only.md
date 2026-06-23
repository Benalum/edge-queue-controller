# Stage 16 FC-O1 failed-unit journal diagnosis read-only

Date: 2026-06-22

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-N2D1-R3.
- Base HEAD/origin/main: `4daa3bc`.
- Base tag: `controller-stage-16-fc-n2d1-r3-final-fc-n-matrix-stop-runtime-no-apply-2026-06-22`.

## Mutation boundary

This stage is read-only.

It did not:

- write CT203 DB,
- insert, reset, delete, retry, or manually complete jobs,
- process any jobs,
- start, stop, restart, reload, enable, disable, or reset-failed services,
- clear failed unit evidence,
- write systemd unit files,
- run daemon-reload,
- activate scheduler services or timers,
- enable persistent workers,
- drain the queue,
- mutate Docker,
- call Ollama endpoints,
- pull or download models,
- restart CTs or VMs.

## Baseline verification

    fc_n_final_matrix_verified_for_o1=true
    quick_check_fc_o1=ok
    ct203_fc_o1_read_only_acceptance_pass=true
    ct101_fc_o1_read_only_acceptance_pass=true

## Worker/profile integrity

    profile_sha_fc_o1=432cd0130f61472b94215ffbf279f516bbc64d2d8ea0e8ba161878186816279c
    worker_sha_fc_o1=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca

## CT203 final FC-N state retained

    jobs95_99_completed_fc_o1=3
    jobs95_99_running_fc_o1=2
    jobs95_99_result_rows_fc_o1=3
    jobs100_104_queued_fc_o1=2
    jobs100_104_running_fc_o1=3
    jobs100_104_completed_fc_o1=0
    jobs100_104_failed_fc_o1=0
    jobs100_104_result_rows_fc_o1=0

## CT101 default-off state retained

    active_exact_services_fc_o1=0
    active_exact_timers_fc_o1=0
    active_general_services_fc_o1=0
    active_general_timers_fc_o1=0
    failed_general_units_fc_o1=5
    exact_timer_enabled_fc_o1=disabled
    general_timer_enabled_fc_o1=disabled
    edge_service_active_fc_o1=inactive
    edge_service_enabled_fc_o1=disabled
    legacy_main_active_fc_o1=inactive
    legacy_main_enabled_fc_o1=masked

## Failed-unit classification

| Job | Model | Lane | Timeout evidence | Traceback evidence | Model-not-found evidence | Connection evidence |
|---|---|---|---|---|---|---|
| 97 | qwen3:1.7b | summary | false | false | false | false |
| 99 | qwen3:1.7b | json_response | false | false | false | false |
| 100 | gemma4:e4b | companion_chat | false | false | false | false |
| 101 | gemma3:4b | companion_chat | false | false | false | false |
| 104 | llama3.2:3b | safe_refusal | false | false | false | false |

## Initial diagnosis

FC-O1 confirms the failed unit evidence is preserved and no active runtime remains.

Interpretation should be conservative:

- If timeout evidence is true across failed units, suspect model generation duration/worker timeout budget.
- If model-not-found evidence is true, suspect model naming/profile mismatch despite filesystem manifests.
- If connection evidence is true, suspect Ollama container/network path.
- If traceback evidence is true, inspect the exact exception in the journal before retrying anything.
- If all classifier fields are false, the next read-only step should capture fuller sanitized journal context and worker execution arguments.

## Decision

Do not reset failed units.

Do not retry stale jobs.

Do not run new probes.

Do not run jobs102 or 103.

Proceed to FC-O2 with a narrower read-only root-cause document based on the FC-O1 journal classification.
