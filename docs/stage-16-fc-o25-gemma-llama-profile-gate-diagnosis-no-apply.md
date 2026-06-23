# Stage 16 FC-O25 gemma/llama profile gate diagnosis no-apply

Date: 2026-06-23

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O25_GEMMA_LLAMA_PROFILE_GATE_DIAGNOSIS_NO_APPLY

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O24-R2.
- Base HEAD/origin/main: `e0dcd0b`.
- Base tag: `controller-stage-16-fc-o24-r2-qwen3-small-structured-tier-and-gemma-llama-remediation-decision-no-apply-2026-06-23`.

## Mutation boundary

This stage was read-only CT203/CT101 diagnosis plus repo documentation and smoke.

It did not:

- write CT203 DB,
- insert jobs,
- mutate jobs,
- run jobs,
- start services,
- enable services or timers,
- reset failed unit evidence,
- mutate CT101 profile,
- mutate CT101 worker code,
- mutate Docker,
- mutate Ollama,
- call Ollama generation/model endpoints,
- activate scheduler or persistent workers,
- drain the queue,
- restart CTs or VMs.

## CT203 queued product blockers

CT203 quick_check remained ok.

| Job | Job type | Model | Status | Attempts | Result rows |
|---:|---|---|---|---:|---:|
| 107 | stage16_fc_companion_chat_semantic_probe | gemma4:e4b | queued | 0 | 0 |
| 108 | stage16_fc_companion_chat_semantic_probe | gemma3:4b | queued | 0 | 0 |
| 109 | stage16_fc_study_tutor_semantic_probe | gemma4:e4b | queued | 0 | 0 |
| 110 | stage16_fc_flashcards_semantic_probe | gemma4:e4b | queued | 0 | 0 |
| 111 | stage16_fc_safe_refusal_semantic_probe | llama3.2:3b | queued | 0 | 0 |

Preserved known state:

- job105 remains running attempts=1 rows=0.
- jobs106, 112, 113, 114, 115, and 116 remain completed attempts=1 rows=1.
- jobs107-111 remain queued attempts=0 rows=0.

## CT101 read-only baseline

    profile_sha_fc_o25=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899
    worker_sha_fc_o25=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    ollama_container_state_fc_o25=running
    ollama_container_health_fc_o25=healthy
    OLLAMA_NUM_PARALLEL_fc_o25=2
    OLLAMA_KEEP_ALIVE_fc_o25=30m
    active_exact_services_fc_o25=0
    active_exact_timers_fc_o25=0
    active_general_services_fc_o25=0
    active_general_timers_fc_o25=0
    failed_general_units_fc_o25=6

## Gate evidence

Worker gate strings observed:

    REFUSE_NO_PROFILE_FOR_MODEL=true
    REFUSE_JOB_TYPE_NOT_ALLOWED_FOR_PROFILE=true
    REFUSE_PROFILE_NOT_PROVEN=true

Target profile presence observed:

    gemma4:e4b profile=missing
    gemma3:4b profile=missing
    llama3.2:3b profile=missing

## Diagnosis

The remaining product jobs are blocked by model/profile proof gates, not by queue execution.

qwen3:1.7b is proven as the first small structured-output tier, but the companion, study, flashcards, and safe-refusal jobs use gemma/llama models that are still not proven for their semantic job types.

Expected gate classes:

| Model | Jobs | Expected issue |
|---|---|---|
| gemma4:e4b | 107, 109, 110 | Candidate profile exists but needs explicit allowlist/policy proof for companion, study_tutor, and flashcards job types. |
| gemma3:4b | 108 | Candidate profile exists but needs explicit allowlist/policy proof for companion_chat. |
| llama3.2:3b | 111 | Requires confirmed profile mapping and explicit allowlist/policy proof for safe_refusal. |

The remediation should not blindly run jobs107-111 until the profile contract is documented and approved.

## Recommended FC-O26 profile remediation contract

FC-O26 should be no-apply and should document one exact profile mutation contract.

Required contract:

1. Back up `/etc/edge-ct101-worker/model-profiles.yaml`.
2. Preserve qwen profiles and worker code unchanged.
3. Keep `OLLAMA_NUM_PARALLEL=2`.
4. Do not process any jobs.
5. Do not enable persistent workers.
6. Do not reset failed unit evidence.
7. Add or confirm explicit allowlist entries for only the targeted semantic job types.
8. Keep each gemma/llama profile at max_concurrent_model_calls=1.
9. Keep one-model, one-job runtime proof sequencing until each model is proven.
10. Define success/failure semantics for each product job type before runtime.

## Recommended profile-policy direction

The safest remediation path is:

- gemma4:e4b:
  - allow companion_chat only for the first proof, or use a fresh companion proof clone first;
  - after companion proof, separately add study_tutor;
  - after study_tutor proof, separately add flashcards.
- gemma3:4b:
  - allow companion_chat only for its first proof.
- llama3.2:3b:
  - add/confirm model profile first if missing;
  - allow safe_refusal only for its first proof.

Do not enable concurrency above one for gemma/llama until one-model one-job proof passes.

## Recommended FC-O27+ proof order

1. gemma4:e4b companion_chat: job107 or fresh clone.
2. gemma3:4b companion_chat: job108 or fresh clone.
3. gemma4:e4b study_tutor: job109 or fresh clone.
4. gemma4:e4b flashcards: job110 or fresh clone.
5. llama3.2:3b safe_refusal: job111 or fresh clone.

Each runtime proof should use exactly one service instance and explicit approval.

## Decision

Do not run jobs107-111 yet.

Next recommended stage: FC-O26 gemma/llama profile remediation contract no-apply.
