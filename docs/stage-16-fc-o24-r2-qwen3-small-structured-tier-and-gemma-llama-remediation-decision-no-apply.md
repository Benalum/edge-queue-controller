# Stage 16 FC-O24-R2 qwen3 small structured tier and gemma/llama remediation decision no-apply

Date: 2026-06-23

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O24_QWEN3_SMALL_STRUCTURED_TIER_AND_GEMMA_LLAMA_REMEDIATION_DECISION_NO_APPLY

## R2 reason

The first FC-O24 attempt failed before mutation on a brittle verification assumption about older proof document names or exact phrases.

No file write, DB mutation, runtime, profile mutation, Docker/Ollama mutation, service mutation, or repo commit occurred in the failed attempt.

This R2 uses the recent hard evidence chain from FC-O20 through FC-O23 and records older qwen3 proof facts as historical context.

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O23.
- Base HEAD/origin/main: `f3ca576`.
- Base tag: `controller-stage-16-fc-o23-run-only-jobs115-116-qwen3-parallel-two-service-proof-2026-06-23`.

## Mutation boundary

This stage is repo documentation and smoke only.

It does not mutate CT101, CT203, jobs, services, timers, systemd units, Docker, Ollama, scheduler state, persistent worker state, CTs, VMs, or the queue.

## Proven qwen3:1.7b facts

qwen3:1.7b is now the first reliable small structured-output tier candidate.

It has passed:

| Stage | Job(s) | Proof |
|---|---:|---|
| FC-O14 | 113 | Summary hygiene passed with no visible thinking |
| FC-O16 | 106 | JSON strict pass before Ollama concurrency change |
| FC-O20 | 114 | JSON strict pass after `OLLAMA_NUM_PARALLEL=2` |
| FC-O23 | 115 and 116 | Two explicitly targeted parallel JSON jobs both passed |

The hard post-concurrency evidence is:

    job114_strict_json_pass_fc_o20=true
    dual_active_observed_fc_o23=true
    job115_status_after_fc_o23=completed
    job115_result_rows_after_fc_o23=1
    job115_strict_json_pass_fc_o23=true
    job116_status_after_fc_o23=completed
    job116_result_rows_after_fc_o23=1
    job116_strict_json_pass_fc_o23=true
    job115_json_profile_id_fc_o23=qwen3_1_7b_candidate
    job116_json_profile_id_fc_o23=qwen3_1_7b_candidate
    OLLAMA_NUM_PARALLEL_after_fc_o23=2
    CT203 remained durable queue authority
    persistent workers remained off
    bulk queue drain remained prohibited

Jobs115 and 116 returned the same response SHA as jobs106 and 114:

    61067975d9dc6d70f9eb50d376f0de45996f343d8f8daffbb17bf43b76d33817

## Decision: promote qwen3:1.7b to first reliable small structured tier

qwen3:1.7b should be treated as the first proven small structured-output model tier for the controller queue.

Recommended role:

    qwen3_small_structured_tier

Appropriate initial use cases:

- router labels,
- strict JSON outputs,
- summary-style controller responses,
- light study structured responses,
- deterministic small-task queue outputs.

Not yet approved:

- persistent worker enablement,
- broad queue draining,
- production default for all task types,
- companion default,
- long-form tutor default,
- voice/speaking/listening model authority.

## Concurrency decision

`OLLAMA_NUM_PARALLEL=2` is validated for explicitly targeted qwen3:1.7b JSON jobs.

Keep this setting for now:

    OLLAMA_NUM_PARALLEL=2

Do not increase above 2 yet.

Do not raise profile-level concurrency for gemma or llama yet.

Do not enable persistent workers yet.

Do not bulk drain the queue yet.

## Remaining blocked product surfaces

The next product blockers are jobs107-111:

| Job | Job type | Model | Current state | Blocker class |
|---:|---|---|---|---|
| 107 | companion_chat | gemma4:e4b | queued attempts=0 rows=0 | model/profile proof gate |
| 108 | companion_chat | gemma3:4b | queued attempts=0 rows=0 | model/profile proof gate |
| 109 | study_tutor | gemma4:e4b | queued attempts=0 rows=0 | model/profile proof gate |
| 110 | flashcards | gemma4:e4b | queued attempts=0 rows=0 | model/profile proof gate |
| 111 | safe_refusal | llama3.2:3b | queued attempts=0 rows=0 | model/profile proof gate |

These jobs should not be run blindly yet because prior FC-O analysis showed unproven profile gates for gemma/llama candidate profiles.

## Recommended remediation path

Use a separate remediation sequence for gemma/llama.

### FC-O25: gemma/llama profile gate diagnosis no-apply

Read-only/no-apply objective:

- inspect current CT101 profile YAML,
- inspect worker gate logic,
- inspect queued jobs107-111,
- identify exact refusal paths expected for:
  - gemma4:e4b,
  - gemma3:4b,
  - llama3.2:3b,
- decide whether remediation should use:
  - profile policy update,
  - proof job insertion,
  - job type allowlist update,
  - model-specific prompt changes,
  - or a combination.

No runtime and no profile mutation in FC-O25.

### FC-O26: profile remediation contract no-apply

Only after FC-O25, document the exact profile mutation plan.

Required contract:

- backup profile file,
- mutate only explicitly selected profile keys,
- no job processing,
- no service/timer enablement,
- no reset-failed,
- no persistent workers,
- no queue drain,
- verify profile sha before/after,
- verify worker sha unchanged,
- verify OLLAMA_NUM_PARALLEL remains 2.

### FC-O27+: one-model, one-job proof sequence

Run one candidate at a time.

Recommended order:

1. gemma4:e4b companion_chat proof job107 or fresh clone.
2. gemma3:4b companion_chat proof job108 or fresh clone.
3. gemma4:e4b study_tutor proof job109 or fresh clone.
4. gemma4:e4b flashcards proof job110 or fresh clone.
5. llama3.2:3b safe_refusal proof job111 or fresh clone.

Each runtime stage should target exactly one job unless a prior stage has proven concurrency for that model.

## Product interpretation

After FC-O23:

- The queue/controller execution path is no longer the main blocker for structured outputs.
- qwen3:1.7b can support controller-owned structured work.
- The remaining product blocker is model-specific semantic/profile validation for companion, study, flashcards, and safe-refusal.
- Speaking and listening should remain downstream surfaces until companion/study model behavior is proven.

## Decision

Lock qwen3:1.7b as the first proven small structured-output tier.

Keep Ollama at `OLLAMA_NUM_PARALLEL=2`.

Do not enable persistent workers or bulk queue draining yet.

Next recommended stage: FC-O25 gemma/llama profile gate diagnosis no-apply.
