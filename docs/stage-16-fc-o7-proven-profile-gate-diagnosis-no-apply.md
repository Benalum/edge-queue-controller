# Stage 16 FC-O7 proven-profile gate diagnosis no-apply

Date: 2026-06-23

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O6.
- Base HEAD/origin/main: `5e50ca2`.
- Base tag: `controller-stage-16-fc-o6-run-only-job105-qwen3-summary-one-shot-2026-06-23`.

## Mutation boundary

This stage is read-only against CT203 and CT101.

It did not:

- write CT203 DB,
- insert, reset, delete, retry, or manually complete jobs,
- mutate CT101 profile,
- process jobs,
- start, stop, restart, reload, enable, disable, or reset-failed services,
- clear failed unit evidence,
- write systemd units,
- run daemon-reload,
- activate scheduler,
- enable persistent workers,
- mutate Docker,
- call Ollama endpoints,
- pull models,
- restart CTs or VMs.

## FC-O6 finding

Job105 was started once and failed before model generation.

The CT101 unit journal contained:

    REFUSE_PROFILE_NOT_PROVEN

CT203 state after FC-O6:

    job105_status=running
    job105_attempts=1
    job105_result_rows=0

Jobs106-111 remain queued with attempts=0 and result_rows=0.

## Proven-profile gate diagnosis

The qwen3:1.7b profile now has the required FC summary allowlist entry, but it is still not marked proven.

    profile_sha_fc_o7=005bb2990ee2244591777c37ff164b26bdab8cd3c9adc7685f78e4c8f624e5ec
    worker_sha_fc_o7=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    qwen3_1_7b_profile_id_fc_o7=qwen3_1_7b_candidate
    qwen3_1_7b_proven_fc_o7=None
    qwen3_1_7b_allowed_types_fc_o7=future_single_model_probe_only,stage16_fc_summary_semantic_probe,stage16_fc_json_semantic_probe
    qwen3_1_7b_has_allowed_but_not_proven_fc_o7=true

Interpretation:

- FC-O3 fixed the job-type allowlist gate.
- FC-O6 hit the next guard: the selected qwen3:1.7b profile is still a candidate/unproven profile.
- Therefore qwen3:1.7b still has not reached model generation through CT203 queue.
- This is still a profile policy gate, not an Ollama/model generation failure.

## Runtime posture

    active_exact_services_fc_o7=0
    active_general_services_fc_o7=0
    active_exact_timers_fc_o7=0
    active_general_timers_fc_o7=0
    failed_general_units_fc_o7=6

## Recommended next stage

Do not run job106 or any later replacement job yet.

The next apply stage should be profile-only and should address only qwen3:1.7b proven-profile gating for the job105 retry path.

Recommended conservative approach:

1. Back up CT101 profile.
2. Mutate only the qwen3:1.7b profile's proven/approval field needed to pass the worker's proven-profile guard.
3. Do not change gemma4, gemma3, or llama3.2 proven state yet.
4. Do not reset job105 in the same step.
5. Do not clear failed unit evidence.
6. Do not start any runtime.
7. Verify profile sha and worker loader.
8. Commit/tag/push the profile-only checkpoint.

After that, use a separate approval to create or run a fresh qwen3:1.7b summary replacement job rather than blindly retrying job105.
