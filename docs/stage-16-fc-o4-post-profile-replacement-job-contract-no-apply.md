# Stage 16 FC-O4 post-profile replacement job contract no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O3-R4.
- Base HEAD/origin/main: `c3a6c08`.
- Base tag: `controller-stage-16-fc-o3-r4-ct101-profile-apply-verified-no-further-mutation-2026-06-22`.

## Mutation boundary

This stage is no-apply.

It did not:

- write CT203 DB,
- insert jobs,
- reset jobs,
- delete jobs,
- retry jobs,
- manually complete jobs,
- mutate CT101 profile,
- process jobs,
- start or stop services/timers,
- reset failed units,
- clear evidence,
- call Ollama endpoints,
- pull models,
- activate scheduler,
- enable persistent workers.

## Verified baseline

    fc_o3_r4_doc_verified_for_o4=true
    quick_check_fc_o4=ok
    max_job_id_fc_o4=104
    ct203_fc_o4_read_only_acceptance_pass=true
    profile_sha_fc_o4=005bb2990ee2244591777c37ff164b26bdab8cd3c9adc7685f78e4c8f624e5ec
    ct101_fc_o4_read_only_acceptance_pass=true

## Preserved old evidence

Do not reuse these stale/evidence jobs:

| Old job | Model | Lane | Current state |
|---|---|---|---|
| 97 | qwen3:1.7b | summary | running/stale, failed CT101 unit |
| 99 | qwen3:1.7b | json_response | running/stale, failed CT101 unit |
| 100 | gemma4:e4b | companion_chat | running/stale, failed CT101 unit |
| 101 | gemma3:4b | companion_chat | running/stale, failed CT101 unit |
| 104 | llama3.2:3b | safe_refusal | running/stale, failed CT101 unit |

Do not run old queued jobs102 or 103.

They belong to the pre-profile-remediation FC-N batch and should remain untouched for audit clarity.

## Replacement job contract

The next DB-apply stage should insert exactly seven fresh post-profile replacement jobs.

Assuming no intervening job inserts, proposed IDs are `105` through `111`.

| Proposed job | Replaces | Job type | Model | Purpose |
|---:|---:|---|---|---|
| 105 | 97 | stage16_fc_summary_semantic_probe | qwen3:1.7b | prove qwen3 summary after profile gate fix |
| 106 | 99 | stage16_fc_json_semantic_probe | qwen3:1.7b | prove qwen3 JSON after profile gate fix |
| 107 | 100 | stage16_fc_companion_chat_semantic_probe | gemma4:e4b | prove gemma4 companion after profile gate fix |
| 108 | 101 | stage16_fc_companion_chat_semantic_probe | gemma3:4b | prove gemma3 companion after profile gate fix |
| 109 | 102 | stage16_fc_study_tutor_semantic_probe | gemma4:e4b | prove gemma4 study after profile gate fix |
| 110 | 103 | stage16_fc_flashcards_semantic_probe | gemma4:e4b | prove gemma4 flashcards after profile gate fix |
| 111 | 104 | stage16_fc_safe_refusal_semantic_probe | llama3.2:3b | prove llama3.2 safe refusal after profile gate fix |

## DB insert guardrails for the next apply stage

The next apply stage must:

- require explicit approval,
- backup CT203 DB before insert,
- insert only the seven replacement jobs above,
- not reset or mutate old jobs97, 99, 100, 101, 102, 103, or 104,
- not create job_results rows,
- not run jobs,
- not start timers/services,
- not call models,
- not clear CT101 failed units,
- verify inserted job IDs, job types, requested models, status queued, attempts 0, result rows 0,
- commit/tag/push the insert checkpoint.

## Runtime guardrails after insertion

Post-insert runtime must be separate from DB insertion.

Recommended runtime order:

1. qwen3 summary only.
2. qwen3 JSON only.
3. llama3.2 safe refusal only.
4. gemma3 companion only.
5. gemma4 companion only.
6. gemma4 study only.
7. gemma4 flashcards only.

Rationale:

- prove qwen3 profile-gate remediation before larger gemma jobs,
- isolate llama3.2 safe-refusal,
- keep gemma4 last because it has the highest expected cost/risk,
- preserve default-off posture between each one-shot.

## Decision

Proceed next to a separately approved DB insert stage for replacement jobs only.
