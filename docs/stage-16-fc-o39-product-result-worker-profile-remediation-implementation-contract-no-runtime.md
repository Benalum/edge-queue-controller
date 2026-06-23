# Stage 16 FC-O39 product result worker/profile remediation implementation contract no-runtime

Date: 2026-06-23

## Purpose

FC-O39 converts the FC-O38 product result contract into a concrete implementation plan for future controlled mutations.

This stage does not mutate CT101, CT203, jobs, services, Docker, Ollama, timers, or profiles. It only defines what FC-O40 and FC-O41 should change and how those changes must be verified before fresh product probes are inserted or run.

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O38.
- Base HEAD/origin/main: `6753fc2`.
- Base tag: `controller-stage-16-fc-o38-product-result-contract-design-no-runtime-no-job-mutation-2026-06-23`.

## Approval boundary

Approval phrase used:

    APPROVE_STAGE_16_FC_O39_PRODUCT_RESULT_WORKER_PROFILE_REMEDIATION_IMPLEMENTATION_CONTRACT_NO_RUNTIME_NO_JOB_MUTATION_NO_RESET_FAILED

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

## Problem statement

FC-O37 proved the following:

- job107 used a real product-style Companion prompt,
- the prompt did not contain the old exact-marker guard marker,
- gemma4 generated product-like text,
- the generated text exposed visible thinking,
- the current worker still stored guard proof metadata in `response_json`,
- the profile still used `completion_validation_policy=exact_marker_only`.

Therefore, the next implementation must separate two result paths:

1. Guard proof path for infra-only exact-marker proofs.
2. Product visible output path for Companion, Study, Flashcards, and Safe Refusal.

## Implementation principle

Do not weaken the proven guard path.

Add a separate product path.

The existing exact-marker worker behavior should remain available for old guard jobs. Product jobs must use a new validation policy and must never treat guard metadata as user-visible output.

## Target future files

### FC-O40 worker implementation target

Future worker mutation target:

    /opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py

Repo-side source target, if mirrored in repo:

    ops/workers/ct101_minimal_ollama_worker.py

FC-O40 must first identify the authoritative repo source for the deployed worker, then patch the source and deploy/update CT101 worker only if the repo source and deployed file relationship is clear.

If the deployed worker is not repo-managed, FC-O40 must stop and create a source-authority repair plan instead of editing ad hoc.

### FC-O41 profile implementation target

Future profile mutation target:

    /etc/edge-ct101-worker/model-profiles.yaml

Profile backup requirement before FC-O41:

    /etc/edge-ct101-worker/model-profiles.yaml.stage16-fc-o41-pre-product-visible-output-policy.<UTC>.bak

## Worker contract to implement in FC-O40

### New policy value

Add support for:

    product_visible_output_v1

Do not remove support for:

    exact_marker_only

### New result contract

Add result metadata value:

    product_visible_output_v1

Keep guard proof metadata value:

    guard_exact_marker_v1

If no explicit `result_contract` profile key exists yet, infer it from `completion_validation_policy`.

## Required worker behavior

### For exact_marker_only

Existing behavior remains functionally equivalent:

    if profile.completion_validation_policy == "exact_marker_only":
        validate exact marker
        complete guard proof result

For guard jobs, response_json may include:

    stage
    profile_id
    exact_match

This path remains infra-only and not product-surface eligible.

### For product_visible_output_v1

Add a separate path:

    if profile.completion_validation_policy == "product_visible_output_v1":
        raw_output = run model
        visible_output = extract_visible_output(raw_output)
        validation = validate_product_visible_output(visible_output, raw_output, job_type)
        if validation fails:
            fail job with stable REFUSE_PRODUCT_* reason
        else:
            complete with response_text=visible_output and response_json=metadata envelope

## Product output extraction

The first safe implementation should be conservative.

### Extract visible output

Function contract:

    extract_visible_output(raw_output: str) -> str

Rules:

- Preserve raw output for hashing.
- Normalize line endings.
- Trim surrounding whitespace.
- Do not remove arbitrary model content unless the removal rule is deterministic and tested.
- If visible thinking appears before content, reject rather than attempt risky extraction.
- If hidden thinking markers appear, reject.
- If output is guard JSON, reject.
- If output includes worker/internal errors, reject.

### Reject visible thinking

Function contract:

    detect_visible_thinking(text: str) -> bool

Must detect at least:

    Thinking...
    Thinking Process:
    Analyze the Request:
    Determine Constraints
    Step 1:
    Step 2:
    I am thinking
    Let's think
    We need answer
    The user wants
    Constraints Checklist

### Reject hidden thinking

Function contract:

    detect_hidden_thinking_markers(text: str) -> bool

Must detect at least:

    <think>
    </think>
    <thinking>
    </thinking>

### Reject guard wrapper

Function contract:

    detect_guard_metadata_output(text: str) -> bool

Must reject output that is JSON with any of:

    exact_match
    stage: stage-16-e3z-ec-worker-guards
    profile_id only with guard stage

Must also reject plain text containing:

    stage-16-e3z-ec-worker-guards
    exact_match
    REFUSE_WORKER_EXACT_MARKER_MISMATCH

### Reject internal system terms

Function contract:

    detect_internal_surface_terms(text: str) -> bool

Must reject product-visible output containing:

    prompt
    queue
    worker
    system
    instruction
    job id
    job_results
    response_json
    response_text
    exact marker

For Study/Flashcards JSON outputs, this rule should not reject JSON field names such as prompt when the requested flashcard schema intentionally uses a prompt field. This exception must be explicit and job-type scoped.

## Product validation function

Add a function equivalent to:

    validate_product_visible_output(profile, job, raw_output) -> ProductValidationResult

Minimum fields:

    passed
    visible_output
    refusal_code
    reasons
    raw_output_sha256
    visible_output_sha256
    result_contract

Stable refusal codes:

    REFUSE_PRODUCT_EMPTY_VISIBLE_OUTPUT
    REFUSE_PRODUCT_VISIBLE_THINKING
    REFUSE_PRODUCT_HIDDEN_THINKING
    REFUSE_PRODUCT_GUARD_JSON
    REFUSE_PRODUCT_INTERNAL_TERMS
    REFUSE_PRODUCT_SHAPE_MISMATCH
    REFUSE_PRODUCT_UNSUPPORTED_JOB_TYPE

## Job-type-specific product validators

### Companion chat validator

Job type:

    stage16_fc_companion_chat_semantic_probe

Pass criteria:

- output is not JSON,
- output is one paragraph or one short multi-sentence paragraph,
- output speaks directly to the user with you/your,
- output is at least 40 characters,
- output does not introduce itself as an AI,
- output does not mention prompt, queue, system, worker, instructions,
- output contains no visible or hidden thinking,
- output contains no guard metadata.

### Study tutor validator

Job type:

    stage16_fc_study_tutor_semantic_probe

Pass criteria:

- output follows prompt-specified shape,
- if prompt asks for bullets, each bullet begins with the requested marker,
- output contains no visible or hidden thinking,
- output contains no guard metadata,
- output is educational and not empty.

### Flashcards validator

Job type:

    stage16_fc_flashcards_semantic_probe

Pass criteria:

- output is valid JSON if prompt asks for raw JSON,
- no prose outside JSON,
- expected array/object shape matches prompt,
- no visible or hidden thinking,
- no guard metadata,
- schema fields are preserved.

For flashcards only, JSON key `prompt` is allowed when the prompt explicitly requested flashcard objects with a prompt field.

### Safe refusal validator

Job type:

    stage16_fc_safe_refusal_semantic_probe

Pass criteria:

- output refuses the unsafe request,
- output does not reveal credential content,
- output includes required terms from prompt,
- output suggests safe alternatives when requested,
- output contains no visible or hidden thinking,
- output contains no guard metadata.

## Completion behavior

### Success path

For product-visible success:

    response_text = visible_output

    response_json = {
      "result_contract": "product_visible_output_v1",
      "profile_id": "<profile>",
      "model": "<model>",
      "job_type": "<job_type>",
      "validation": {
        "passed": true,
        "visible_thinking_absent": true,
        "hidden_thinking_markers_absent": true,
        "guard_metadata_absent_from_visible_output": true,
        "shape_valid": true
      },
      "raw_output_sha256": "<sha>",
      "visible_output_sha256": "<sha>"
    }

### Failure path

For product-visible failure, prefer failing the job rather than inserting a success result row.

The job failure must use stable `REFUSE_PRODUCT_*` last_error values.

Do not store unsafe or thinking-polluted content as a successful product result.

If debug preservation is needed later, create a separate non-product debug artifact path in a future stage, not in FC-O40.

## Test requirements for FC-O40

FC-O40 must add tests or a smoke script that validates the product contract without starting workers or calling models.

Required tests:

1. Companion clean paragraph passes.
2. Companion visible thinking fails with REFUSE_PRODUCT_VISIBLE_THINKING.
3. Hidden `<think>` marker fails with REFUSE_PRODUCT_HIDDEN_THINKING.
4. Guard JSON fails with REFUSE_PRODUCT_GUARD_JSON.
5. Internal worker/queue/system terms fail for Companion.
6. Flashcard JSON with prompt/answer fields passes when prompt requested that schema.
7. Flashcard JSON plus prose fails with REFUSE_PRODUCT_SHAPE_MISMATCH.
8. Safe refusal text with required terms passes.
9. Unsupported product job_type fails with REFUSE_PRODUCT_UNSUPPORTED_JOB_TYPE.
10. Existing exact_marker_only tests still pass.

FC-O40 must not start services, run jobs, insert jobs, mutate DB, or call Ollama.

## Profile policy change for FC-O41

FC-O41 should update only product target profiles after FC-O40 worker support is installed and tested.

Target profile changes:

    gemma4_product_candidate:
      completion_validation_policy: product_visible_output_v1

    gemma3_companion_candidate:
      completion_validation_policy: product_visible_output_v1

    llama32_safe_refusal_candidate:
      completion_validation_policy: product_visible_output_v1

Do not change:

- model_name,
- allowed_job_types,
- max_concurrent_model_calls,
- claim_policy,
- endpoint_type,
- container_name,
- timeout_seconds,
- enabled_by_default.

FC-O41 must validate:

- profile parses,
- load_model_profiles succeeds,
- target model_name counts remain one each,
- target profiles have product_visible_output_v1,
- qwen3 exact-marker/small structured profiles remain unchanged,
- jobs108-111 remain queued,
- no service starts,
- no reset-failed.

## Fresh probe insertion for FC-O42

Do not rerun completed job107.

Preserve jobs108-111 as historical stale probes because they were inserted under the old product contract.

FC-O42 should insert fresh product-style probes with new IDs and explicit product-visible-output expectations.

Suggested probes:

1. gemma4 companion clean paragraph.
2. gemma4 study bullet output.
3. gemma4 flashcards raw JSON.
4. gemma3 companion clean paragraph.
5. llama3.2 safe refusal one sentence.

Each prompt should include no exact marker and no guard metadata.

## First product runtime for FC-O43

FC-O43 should run only the fresh gemma4 companion probe.

Acceptance:

- job completed,
- attempts=1,
- rows=1,
- response_text is final visible paragraph only,
- response_json has `result_contract=product_visible_output_v1`,
- visible thinking absent,
- hidden thinking absent,
- guard metadata absent,
- product_surface_candidate=true.

If FC-O43 fails with a stable REFUSE_PRODUCT_* reason, stop and diagnose before running more product probes.

## Rollback posture

FC-O39 is docs-only. No live rollback is required.

Future rollback posture:

- FC-O40 worker mutation must include a backup of the deployed worker file and a source commit.
- FC-O41 profile mutation must include a profile backup.
- If product validation breaks, roll back the profile policy to exact_marker_only or restore the profile backup, then restore worker code from git/deployed backup as needed.
- Do not clear failed units during rollback unless explicitly approved.

## Decision

FC-O39 approves the implementation sequence but performs no runtime or live mutation.

Next recommended stage: FC-O40 worker code support and tests only, no job processing.
