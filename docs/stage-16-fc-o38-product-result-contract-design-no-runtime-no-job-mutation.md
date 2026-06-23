# Stage 16 FC-O38 product result contract design no-runtime/no-job-mutation

Date: 2026-06-23

## Purpose

Stage 16 FC-O37 proved that job107 was not blocked by profile loading anymore.

The product-style Companion prompt reached gemma4 and a model response was produced, but the current worker/result contract stored guard proof metadata in `response_json` and left visible thinking in `response_text`.

FC-O38 defines the no-runtime product-result contract needed before running more product probes.

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O37.
- Base HEAD/origin/main: `ed13f13`.
- Base tag: `controller-stage-16-fc-o37-job107-prompt-result-provenance-diagnosis-read-only-2026-06-23`.

## Mutation boundary

This stage is repo documentation and smoke only.

It does not:

- write CT101 profile,
- mutate CT101 worker code,
- write CT203 DB,
- insert jobs,
- mutate jobs,
- reset, retry, delete, or manually complete jobs,
- insert job_results rows,
- run jobs,
- start services,
- enable services or timers,
- start timers,
- write systemd units,
- run daemon-reload,
- reset failed units,
- clear failed-unit evidence,
- mutate Docker,
- mutate Ollama,
- call Ollama generation/model endpoints,
- pull models,
- activate scheduler,
- activate persistent workers,
- drain queue,
- restart CTs or VMs.

## FC-O37 evidence

Job107 evidence:

    job107_prompt_sha_fc_o37=4ae77146c7bd18db6227150ccfcadb2a4504669eb876a56111df2dd24024bafb
    job107_response_json_sha_fc_o37=b306e13d87708c5ccd08e0f8d43da92d402c516cf76085795a3fae25206ebd79
    job107_response_text_sha_fc_o37=5402081494ce7ac5559b84066ad7bb019addc9a9aa127a95e50f1bd06c361180
    job107_prompt_has_guard_marker_fc_o37=false
    job107_prompt_has_companion_terms_fc_o37=true
    job107_result_is_guard_json_fc_o37=true
    job107_prompt_result_mismatch_fc_o37=true
    job107_response_text_contains_thinking_fc_o37=true
    job107_response_text_is_product_like_fc_o37=true

The prompt was product-style:

    Write one friendly paragraph only. The user says: I had a long day and want a quick encouraging check-in. Do not introduce yourself. Do not say you are an AI. Do not mention prompts, queues, systems, workers, or instructions. Do not use quotation marks around the answer.

The stored `response_json` was guard metadata:

    {"exact_match": true, "profile_id": "gemma4_product_candidate", "stage": "stage-16-e3z-ec-worker-guards"}

The stored `response_text` began with visible thinking text.

## Diagnosis

The blocker has moved from profile/runtime wiring to product result handling.

The current behavior is acceptable for old exact-marker guard proofs, but it is not acceptable for Companion, Study, Flashcards, or Safe Refusal product surfaces.

Two issues must be separated:

1. Proof metadata belongs in structured metadata, not as the user-visible product output.
2. Visible thinking must be rejected or stripped before any output can be considered product-safe.

## Contract lanes

### Lane A: guard proof contract

Use this only for infrastructure guard jobs.

    completion_validation_policy=exact_marker_only
    result_contract=guard_exact_marker_v1

Expected behavior:

- `response_text` may hold the exact marker or model raw output used for marker comparison.
- `response_json` may hold guard metadata such as stage, exact_match, and profile_id.
- This lane is not product-surface eligible.
- Any job result under this lane must not be shown directly to users as Companion/Study/Flashcards content.

### Lane B: product visible output contract

Use this for Companion, Study, Flashcards, Safe Refusal, and future user-facing outputs.

    completion_validation_policy=product_visible_output_v1
    result_contract=product_visible_output_v1

Expected behavior:

- `response_text` contains the final user-visible answer only.
- `response_json` contains metadata about validation and extraction, not replacement content.
- Product metadata includes model, profile_id, job_type, result_contract, raw_output_sha, visible_output_sha, validation status, and rejection reasons.
- `response_text` must not contain visible thinking, hidden thinking markers, tracebacks, worker refusal text, internal queue/system text, or guard marker metadata.
- If the output fails product validation, the worker must fail the job or mark it non-product-eligible, rather than storing a successful product result.

## Product validation rules

A product-visible output passes only if all are true:

    non_empty_visible_output=true
    visible_thinking_absent=true
    hidden_thinking_markers_absent=true
    traceback_absent=true
    worker_refusal_absent=true
    guard_metadata_absent_from_visible_output=true
    internal_queue_system_terms_absent=true
    job_type_shape_valid=true

### Visible thinking rejection

Reject or strip any output that starts with, contains, or exposes patterns like:

    Thinking...
    Thinking Process:
    <think>
    </think>
    I am thinking
    Step 1:
    Analyze the Request:
    Determine Constraints:

For first production-safe implementation, prefer reject over strip when the visible thinking is embedded or ambiguous. Stripping can be added later once deterministic extraction is proven.

## Product output shape by job type

Companion chat:

    stage16_fc_companion_chat_semantic_probe

Required shape:

- one natural user-facing paragraph,
- speaks directly to the user,
- no prompt/system/queue/worker language,
- no visible thinking,
- no JSON guard wrapper.

Study tutor:

    stage16_fc_study_tutor_semantic_probe

Required shape:

- follows prompt format exactly,
- no visible thinking,
- no hidden thinking markers,
- educational content only,
- no guard wrapper.

Flashcards:

    stage16_fc_flashcards_semantic_probe

Required shape:

- valid JSON if prompt asks for JSON,
- schema/array shape matches prompt,
- no prose outside JSON,
- no visible thinking,
- no guard wrapper.

Safe refusal:

    stage16_fc_safe_refusal_semantic_probe

Required shape:

- refusal text only,
- includes required safety terms,
- no credential disclosure,
- no visible thinking,
- no guard wrapper.

## Storage contract using current schema

Current `job_results` columns are:

    job_id
    model
    response_text
    response_json
    error
    created_at
    updated_at

Without applying a schema migration, FC-O38 recommends:

### Completed product-visible result

    response_text = final user-visible answer only
    response_json = metadata envelope
    error = NULL

Example metadata envelope:

    {
      "result_contract": "product_visible_output_v1",
      "profile_id": "gemma4_product_candidate",
      "model": "gemma4:e4b",
      "job_type": "stage16_fc_companion_chat_semantic_probe",
      "validation": {
        "passed": true,
        "visible_thinking_absent": true,
        "hidden_thinking_markers_absent": true,
        "guard_metadata_absent_from_visible_output": true
      },
      "raw_output_sha256": "<sha>",
      "visible_output_sha256": "<sha>"
    }

### Failed product validation result

For the first implementation, prefer failing the job rather than inserting a successful result row.

The failure should record a stable machine-readable reason, for example:

    REFUSE_PRODUCT_VISIBLE_THINKING
    REFUSE_PRODUCT_GUARD_JSON
    REFUSE_PRODUCT_EMPTY_VISIBLE_OUTPUT
    REFUSE_PRODUCT_SHAPE_MISMATCH

If the existing fail endpoint requires a last_error only, use that path and do not create a product-visible `job_results` row.

## Profile contract change

Profiles intended for product surfaces must not keep:

    completion_validation_policy=exact_marker_only

Recommended product profiles:

    gemma4_product_candidate:
      completion_validation_policy: product_visible_output_v1
      allowed_job_types:
        - stage16_fc_companion_chat_semantic_probe
        - stage16_fc_study_tutor_semantic_probe
        - stage16_fc_flashcards_semantic_probe

    gemma3_companion_candidate:
      completion_validation_policy: product_visible_output_v1
      allowed_job_types:
        - stage16_fc_companion_chat_semantic_probe

    llama32_safe_refusal_candidate:
      completion_validation_policy: product_visible_output_v1
      allowed_job_types:
        - stage16_fc_safe_refusal_semantic_probe

This is a future mutation and is not performed in FC-O38.

## Worker contract change

The worker needs a product validation path separate from exact-marker validation.

Pseudo-flow:

    if profile.completion_validation_policy == "exact_marker_only":
        validate exact marker
        complete guard result
    elif profile.completion_validation_policy == "product_visible_output_v1":
        raw_output = run model
        visible_output = extract_visible_output(raw_output, profile)
        validate product visible output
        if validation fails:
            fail job with stable REFUSE_PRODUCT_* reason
        else:
            complete job with response_text=visible_output and response_json=metadata_envelope
    else:
        refuse unsupported validation policy

## Rollback posture

Because FC-O38 is no-runtime/no-mutation, rollback is simply:

- do not implement this contract yet, or
- revert this docs commit if needed.

No live infra rollback is required.

## Next recommended stages

1. FC-O39: no-runtime worker/profile remediation implementation contract.
2. FC-O40: apply worker code support for `product_visible_output_v1` and tests only, no job processing.
3. FC-O41: apply product profile policy update only, no job processing.
4. FC-O42: insert fresh product-style probes, preserving jobs108-111 as historical stale probes.
5. FC-O43: run one fresh gemma4 Companion probe only.
