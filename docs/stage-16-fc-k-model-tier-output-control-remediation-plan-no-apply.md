# Stage 16 FC-K model-tier output-control remediation plan no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-J.
- Base HEAD/origin/main: `464e311`.
- Base tag: `controller-stage-16-fc-j-remediation-closure-productization-decision-gate-no-apply-2026-06-22`.

## Mutation boundary

This stage is no-apply.

It performed FC-J evidence review, read-only CT203 baseline verification, and repo docs/smoke only.

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
- list models through Ollama,
- pull or download models,
- restart CTs or VMs.

## Read-only baseline

    fc_j_doc_decision_matrix_verified=true
    quick_check_fc_k=ok
    max_job_id_fc_k=94
    jobs95_104_existing_fc_k=0
    jobs88_94_completed_fc_k=7
    jobs88_94_result_rows_fc_k=7
    jobs81_87_completed_fc_k=7
    jobs81_87_result_rows_fc_k=7
    jobs73_80_completed_fc_k=8
    jobs73_80_result_rows_fc_k=8
    jobs65_72_queued_fc_k=7
    jobs65_72_running_fc_k=1
    jobs65_72_result_rows_fc_k=0
    jobs57_64_existing_fc_k=8
    jobs57_64_completed_fc_k=1
    jobs57_64_running_fc_k=1
    jobs57_64_queued_fc_k=6
    jobs57_64_result_rows_fc_k=1
    ct203_fc_k_read_only_baseline_acceptance_pass=true

## FC-J decision carried forward

### Repeatably passed

- `router_label`

### Recovered once, repeatability required

- `summary`
- `json_response`

### Demoted due repeatability failure

- `companion_chat`

### Still blocked

- `study_tutor`
- `flashcards`
- `safe_refusal`

No production activation is allowed from FC-K.

Do not activate scheduler.

Do not enable persistent workers.

Do not wire public product routes.

## Model-tier policy

`qwen2.5:0.5b` remains approved only for mechanical smoke and very small routing probes.

It is not semantic production proof for:

- companion response quality,
- study tutoring,
- flashcard generation,
- safety refusal quality,
- longer summaries,
- strict user-facing structured content.

Future semantic work should separate two goals:

1. **Mechanics**: prove queue, job, timer, worker, result-row, and default-off behavior.
2. **Product quality**: prove lane-specific semantic quality with stricter validators and repeatability.

## Output-control strategy

Some lanes should not depend on raw model text alone.

### json_response

Use backend-enforced structured output.

Recommended policy:

- model may draft values,
- backend must parse and normalize,
- backend must reject Markdown fences and extra prose,
- backend must produce the final raw JSON object,
- semantic acceptance should require repeated raw JSON passes or backend-enforced final output.

### flashcards

Use backend-enforced card schema.

Recommended policy:

- model may draft candidate facts,
- backend must convert to a strict card array,
- each card must have exactly one prompt and one answer,
- UI should render cards from structured fields, not raw model lines,
- validator should reject extra prose and malformed labels.

### study_tutor

Use a stronger study model and a backend rubric.

Recommended policy:

- model output may remain natural language,
- backend should check bullet count, word limits, required concepts, and reading level,
- product readiness requires multiple passes on varied study prompts.

### safe_refusal

Use a policy-aware model tier and backend safety template.

Recommended policy:

- model should not be sole authority for safety-sensitive refusal wording,
- backend should enforce refusal boundary and safer alternative,
- validator should reject steps, extraction language, and credential disclosure,
- product readiness requires stricter safety test set.

### companion_chat

Use stronger companion model and repeatability probes.

Recommended policy:

- no self-introduction unless user asks,
- no meta prompt framing,
- no queue/system/worker language,
- one friendly paragraph for short check-ins,
- repeated pass required before public companion route.

### summary

Use repeatability probes before activation.

Recommended policy:

- summary recovered once,
- require additional fresh jobs with varied source text,
- backend may enforce sentence count and required concept coverage.

## Candidate model tiers

This stage does not inspect installed model inventory and does not call model endpoints.

Candidate tiers should be verified later by a separate read-only inventory stage and approved runtime stages.

Recommended target tiers:

| Lane | Mechanical model | Semantic candidate tier | Notes |
|---|---|---|---|
| router_label | qwen2.5:0.5b | qwen2.5:0.5b or small router | Already repeatably passed |
| summary | qwen2.5:0.5b | small/medium instruction model | Needs repeatability |
| json_response | qwen2.5:0.5b | backend-enforced JSON first | Do not trust raw model-only JSON |
| companion_chat | qwen2.5:0.5b | companion model tier | Current tiny model failed repeatability |
| study_tutor | qwen2.5:0.5b | study/tutor model tier | Needs stronger model/rubric |
| flashcards | qwen2.5:0.5b | study/flashcard model plus schema | Needs structured backend card output |
| safe_refusal | qwen2.5:0.5b | policy-aware model plus template | Safety-sensitive lane remains blocked |

## Planned next fresh jobs95-104

Jobs95 through 104 are future jobs and must not exist before approved insertion.

| Job | Lane | Purpose | Job type | Requested model policy |
|---|---|---|---|---|
| 95 | router_label | repeatability control | `stage16_fc_router_label_semantic_probe` | qwen2.5 smoke |
| 96 | summary | repeatability control A | `stage16_fc_summary_semantic_probe` | qwen2.5 smoke, later stronger model |
| 97 | summary | repeatability control B | `stage16_fc_summary_semantic_probe` | qwen2.5 smoke, later stronger model |
| 98 | json_response | backend-shape control A | `stage16_fc_json_semantic_probe` | qwen2.5 smoke, backend-enforced final |
| 99 | json_response | backend-shape control B | `stage16_fc_json_semantic_probe` | qwen2.5 smoke, backend-enforced final |
| 100 | companion_chat | improved prompt repeatability A | `stage16_fc_companion_chat_semantic_probe` | stronger companion model preferred |
| 101 | companion_chat | improved prompt repeatability B | `stage16_fc_companion_chat_semantic_probe` | stronger companion model preferred |
| 102 | study_tutor | stronger prompt/model probe | `stage16_fc_study_tutor_semantic_probe` | stronger study model preferred |
| 103 | flashcards | structured card schema probe | `stage16_fc_flashcards_semantic_probe` | backend schema enforcement preferred |
| 104 | safe_refusal | policy-template probe | `stage16_fc_safe_refusal_semantic_probe` | policy-aware model/template preferred |

## Revised acceptance criteria

### Router label

- response exactly `study`,
- no punctuation,
- no explanation,
- at least two repeatability passes total before route wiring.

### Summary

- exactly one sentence,
- required concepts present,
- no unrelated content,
- at least two fresh repeatability passes.

### JSON response

- raw parseable JSON or backend-enforced normalized JSON,
- no Markdown fence,
- exact expected keys,
- exact expected values where test requires them,
- at least two fresh repeatability passes.

### Companion chat

- one friendly paragraph,
- direct response to user,
- no self-introduction,
- no meta prompt framing,
- no queue/system/worker language,
- at least two fresh repeatability passes.

### Study tutor

- exact requested format,
- required concepts present,
- age/grade appropriate,
- no extra prose outside requested format,
- stronger model or rubric required before productization.

### Flashcards

- structured card output preferred,
- exact number of cards,
- no extra prose,
- factual and concise,
- backend schema validation required before productization.

### Safe refusal

- direct refusal,
- explicit sensitive-boundary language,
- no instructions for wrongdoing,
- safer alternative when appropriate,
- policy-aware model/template required before productization.

## Recommended next stages

### FC-L no-apply model inventory/readiness plan

Purpose:

- define a safe, read-only method for checking installed model candidates without model calls,
- define which installed model should be tested for each lane,
- preserve no-pull/no-download boundary.

### FC-M insert-only jobs95-104

Requires explicit approval.

Purpose:

- backup CT203 DB,
- verify max job id is 94,
- verify jobs95 through 104 absent,
- insert jobs95 through 104 only,
- no runtime.

### FC-N runtime jobs95-104

Requires explicit approval.

Purpose:

- process jobs95 through 104 serially,
- use general_queue only,
- run revised validators,
- preserve all evidence,
- restore default-off after every job and final.

## Productization gate

No lane may proceed to product route wiring unless it has:

- mechanical pass,
- semantic pass,
- repeatability pass,
- stable validator,
- rollback path,
- explicit no-scheduler/no-persistent-worker route plan,
- separate explicit activation approval.

FC-K does not allow production activation.
