# Stage 16 FC-L model inventory readiness no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-K.
- Base HEAD/origin/main: `e8f57b5`.
- Base tag: `controller-stage-16-fc-k-model-tier-output-control-remediation-plan-no-apply-2026-06-22`.

## Mutation boundary

This stage is no-apply.

It performed:

- FC-K evidence review,
- read-only CT203 baseline verification,
- read-only CT101 default-off verification,
- read-only Ollama model filesystem inventory through the existing `ollama` container,
- repo docs/smoke only.

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
- call Ollama endpoints,
- run Ollama list/version/generate/chat/embed,
- pull or download models,
- restart CTs or VMs.

## CT203 baseline

    fc_k_plan_verified_for_fc_l=true
    quick_check_fc_l=ok
    max_job_id_fc_l=94
    jobs95_104_existing_fc_l=0
    jobs88_94_completed_fc_l=7
    jobs88_94_result_rows_fc_l=7
    jobs81_87_completed_fc_l=7
    jobs81_87_result_rows_fc_l=7
    jobs73_80_completed_fc_l=8
    jobs73_80_result_rows_fc_l=8
    jobs65_72_queued_fc_l=7
    jobs65_72_running_fc_l=1
    jobs65_72_result_rows_fc_l=0
    jobs57_64_existing_fc_l=8
    jobs57_64_completed_fc_l=1
    jobs57_64_running_fc_l=1
    jobs57_64_queued_fc_l=6
    jobs57_64_result_rows_fc_l=1
    ct203_fc_l_read_only_baseline_acceptance_pass=true

## CT101 default-off baseline

    profile_sha_fc_l=432cd0130f61472b94215ffbf279f516bbc64d2d8ea0e8ba161878186816279c
    active_exact_services_fc_l=0
    active_exact_timers_fc_l=0
    active_general_services_fc_l=0
    active_general_timers_fc_l=0
    exact_timer_enabled_fc_l=disabled
    general_timer_enabled_fc_l=disabled
    edge_service_active_fc_l=inactive
    edge_service_enabled_fc_l=disabled
    legacy_main_active_fc_l=inactive
    legacy_main_enabled_fc_l=masked
    ct101_fc_l_read_only_inventory_acceptance_pass=true

## Ollama filesystem inventory

This inventory was collected from the Ollama model filesystem, not from Ollama model endpoints.

Observed counts:

    ollama_manifest_count_fc_l=6
    ollama_blob_count_fc_l=27
    ollama_blob_bytes_fc_l=17246301060

Observed manifest entries, capped at 80:

- `registry.ollama.ai/library/gemma3/4b`
- `registry.ollama.ai/library/gemma4/e4b`
- `registry.ollama.ai/library/llama3.2/3b`
- `registry.ollama.ai/library/qwen2.5/0.5b`
- `registry.ollama.ai/library/qwen3/0.6b`
- `registry.ollama.ai/library/qwen3/1.7b`

## Readiness interpretation

This stage intentionally does not decide production readiness from model names alone.

A model is only a candidate until it has:

- no-pull/no-download inventory proof,
- profile eligibility,
- bounded one-shot runtime proof,
- lane-specific mechanical pass,
- lane-specific semantic pass,
- repeatability pass,
- default-off restoration proof.

## Lane recommendations

### router_label

Current status:

- repeatably passed semantic probes,
- can continue on the smallest available router-capable model.

Recommended next action:

- keep as smoke-only candidate,
- do not activate production route yet,
- include one more router repeatability job in jobs95-104.

### summary

Current status:

- recovered once after prompt tightening,
- repeatability not yet proven.

Recommended next action:

- use jobs96 and 97 for repeatability,
- keep qwen2.5-class model acceptable for smoke,
- require two fresh passes before route wiring.

### json_response

Current status:

- recovered once after stricter prompt,
- should not rely on raw model text alone.

Recommended next action:

- use jobs98 and 99 for backend-shape controls,
- design backend normalization/rejection before product use,
- keep model-only JSON blocked until structured enforcement exists.

### companion_chat

Current status:

- original pass,
- repeatability failure in job93.

Recommended next action:

- use jobs100 and 101 for improved prompt repeatability,
- prefer a stronger companion model candidate if inventory supports it,
- keep public companion route blocked.

### study_tutor

Current status:

- failed original and remediation semantic checks.

Recommended next action:

- use job102 with stronger study prompt/model strategy,
- prefer a study/tutor candidate beyond qwen2.5:0.5b,
- keep study route blocked.

### flashcards

Current status:

- failed original and remediation semantic checks.

Recommended next action:

- use job103 with backend card schema plan,
- model may draft facts but backend should emit final card schema,
- keep flashcards route blocked.

### safe_refusal

Current status:

- failed original and remediation semantic checks.

Recommended next action:

- use job104 with policy-template prompt,
- backend should enforce refusal boundary and safe alternative,
- keep safety-sensitive lane blocked.

## Next stages

### FC-M insert-only jobs95-104

Requires explicit approval.

Purpose:

- backup CT203 DB,
- verify max job id is 94,
- verify jobs95 through 104 absent,
- insert jobs95 through 104 only,
- no runtime,
- preserve all prior evidence.

### FC-N runtime jobs95-104

Requires explicit approval.

Purpose:

- process jobs95 through 104 serially,
- use general_queue only,
- run revised validators,
- preserve all evidence,
- restore default-off after every job and final.

## Productization gate

FC-L does not allow production activation.

No lane may proceed to product route wiring unless it has:

- mechanical pass,
- semantic pass,
- repeatability pass,
- stable validator,
- rollback path,
- explicit no-scheduler/no-persistent-worker route plan,
- separate explicit activation approval.
