# Stage 16 FC-O37 job107 prompt/result provenance diagnosis read-only

Date: 2026-06-23

## Purpose

FC-O36-R3 proved job107 completed mechanically through the repaired gemma4 profile path, but the result stored in `response_json` was guard/exact-marker JSON rather than a usable Companion response.

The first FC-O37 attempt gathered the correct evidence, then failed during the smoke/doc phase. FC-O37-R2 preserves that evidence in a corrected checkpoint.

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O36-R3.
- Base HEAD/origin/main: `789567c`.
- Base tag: `controller-stage-16-fc-o36-r3-recover-job107-completed-after-timeout-read-only-2026-06-23`.

## Mutation boundary

This stage performed only:

- read-only CT203 job/result provenance inspection,
- read-only CT101 profile/worker inspection,
- repo docs/smoke/commit/tag/push.

It did not write CT101 profile, mutate CT101 worker code, write CT203 DB, insert or mutate jobs, reset/retry/delete/manually complete jobs, insert job_results rows, run jobs, start services, enable services or timers, start timers, write systemd units, run daemon-reload, reset failed units, clear failed-unit evidence, mutate Docker/Ollama, call Ollama generation/model endpoints, pull models, activate scheduler or persistent workers, drain queue, or restart CTs/VMs.

## Job107 provenance

    job107_prompt_sha_fc_o37=4ae77146c7bd18db6227150ccfcadb2a4504669eb876a56111df2dd24024bafb
    job107_prompt_preview_fc_o37=Write one friendly paragraph only. The user says: I had a long day and want a quick encouraging check-in. Do not introduce yourself. Do not say you are an AI. Do not mention prompts, queues, systems, workers, or instructions. Do not use quotation marks around the answer.
    job107_response_json_sha_fc_o37=b306e13d87708c5ccd08e0f8d43da92d402c516cf76085795a3fae25206ebd79
    job107_response_json_preview_fc_o37={"exact_match": true, "profile_id": "gemma4_product_candidate", "stage": "stage-16-e3z-ec-worker-guards"}
    job107_response_text_sha_fc_o37=5402081494ce7ac5559b84066ad7bb019addc9a9aa127a95e50f1bd06c361180
    job107_response_text_preview_fc_o37=Thinking... Thinking Process: 1.  **Analyze the Request:** The user wants a friendly, encouraging check-i check-in because they had a long day. 2.  **Determine Constraints (CRITICAL):** *   One paragraph only. *   Friendly tone. *   Do not introduce self. *   Do not say "I am an AI." *   Do not mention: prompts, queues, systems, workers, or instructions. instructions. *   Do not use quotation marks around the answer. 3.  **Drafting Focus (Encouragement + Empathy):** The message must validate validate their effort and encourage rest/self-care without breaking any rul rules. 4.  **Review against Constraints Checklist:** *   One paragraph? Yes. *   Friendly? Yes. *   No self-introduction? Yes. 

## Findings

    job107_prompt_has_guard_marker_fc_o37=false
    job107_prompt_has_companion_terms_fc_o37=true
    job107_result_is_guard_json_fc_o37=true
    job107_prompt_result_mismatch_fc_o37=true
    job107_response_text_contains_thinking_fc_o37=true
    job107_response_text_is_product_like_fc_o37=true

The prompt was a real product-style companion prompt. It did not contain the old guard marker.

The stored `response_json` is the older exact-marker/guard wrapper:

    {"exact_match": true, "profile_id": "gemma4_product_candidate", "stage": "stage-16-e3z-ec-worker-guards"}

The stored `response_text` contains a visible thinking trace before the model's actual draft. This means gemma4 did generate content, but the current worker/result contract stored a guard-style success JSON and did not yield a clean product surface response.

## Profile context

    profile_sha_fc_o37=bebfb1dcf8fad51681c87fa5b6a8ce5e03df9040cae4f2fa1959a24c88df5740
    worker_sha_fc_o37=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    profile_gemma4_product_candidate_completion_validation_policy_fc_o37=exact_marker_only
    profile_gemma4_product_candidate_exact_marker_supported_fc_o37=False
    profile_gemma4_product_candidate_allowed_job_types_fc_o37=stage16_fc_companion_chat_semantic_probe,stage16_fc_study_tutor_semantic_probe,stage16_fc_flashcards_semantic_probe

The gemma4 target profile allows companion/study/flashcard job types, but its completion validation policy is still exact-marker-oriented.

## Preserved queue state

    preserved_job_states_fc_o37=true
    job108_status_fc_o37=queued
    job109_status_fc_o37=queued
    job110_status_fc_o37=queued
    job111_status_fc_o37=queued

## CT101/Ollama state

    OLLAMA_NUM_PARALLEL_fc_o37=2
    OLLAMA_KEEP_ALIVE_fc_o37=30m
    active_exact_services_fc_o37=0
    active_general_services_fc_o37=0
    active_exact_timers_fc_o37=0
    active_general_timers_fc_o37=0
    failed_general_units_fc_o37=6
    ct101_fc_o37_read_only_acceptance_pass=true
    ct203_fc_o37_read_only_acceptance_pass=true

No failed-unit evidence was cleared.

## Decision

Do not rerun job107. It already completed.

The blocker is no longer profile loading. The blocker is result contract/product extraction:

1. The product-style prompt reached gemma4.
2. Gemma4 produced a visible thinking trace in `response_text`.
3. The worker stored guard/exact-marker metadata in `response_json`.
4. The output is therefore not a clean Companion product surface candidate.

Next recommended stage: design a no-runtime remediation contract for product-style model jobs that separates guard proof metadata from user-visible model output and adds visible-thinking rejection/stripping rules before any further product probes.
