# Stage 16 FC-O26 gemma/llama profile remediation contract no-apply

Date: 2026-06-23

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O26_GEMMA_LLAMA_PROFILE_REMEDIATION_CONTRACT_NO_APPLY

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O25.
- Base HEAD/origin/main: `15c5af9`.
- Base tag: `controller-stage-16-fc-o25-gemma-llama-profile-gate-diagnosis-no-apply-2026-06-23`.

## Mutation boundary

This stage is repo documentation and smoke only.

It does not mutate CT101, CT203, jobs, services, timers, systemd units, Docker, Ollama, scheduler state, persistent worker state, CTs, VMs, or the queue.

## FC-O25 diagnosis summary

FC-O25 confirmed the queue path is not the blocker.

The remaining queued product jobs are:

| Job | Job type | Model | Status | Attempts | Result rows |
|---:|---|---|---|---:|---:|
| 107 | stage16_fc_companion_chat_semantic_probe | gemma4:e4b | queued | 0 | 0 |
| 108 | stage16_fc_companion_chat_semantic_probe | gemma3:4b | queued | 0 | 0 |
| 109 | stage16_fc_study_tutor_semantic_probe | gemma4:e4b | queued | 0 | 0 |
| 110 | stage16_fc_flashcards_semantic_probe | gemma4:e4b | queued | 0 | 0 |
| 111 | stage16_fc_safe_refusal_semantic_probe | llama3.2:3b | queued | 0 | 0 |

FC-O25 observed worker gate support for:

    REFUSE_NO_PROFILE_FOR_MODEL=true
    REFUSE_JOB_TYPE_NOT_ALLOWED_FOR_PROFILE=true
    REFUSE_PROFILE_NOT_PROVEN=true
    no_default_until_proven=true
    exact_marker_only=true
    completion_validation_policy=true
    allowed_job_types=true
    max_concurrent_model_calls=true

FC-O25 observed target profile presence as:

    gemma4:e4b profile=missing
    gemma3:4b profile=missing
    llama3.2:3b profile=missing

## Remediation principle

Do not run jobs107-111 until the missing profile entries are added or corrected.

Do not use qwen3 proof success to bypass gemma/llama proof gates.

Do not enable persistent workers.

Do not bulk drain the queue.

Do not increase `OLLAMA_NUM_PARALLEL` above 2.

Do not set gemma/llama model concurrency above 1 before single-job proofs.

## Intended FC-O27 apply stage

The next mutating stage should be a profile-file-only apply stage.

Recommended stage name:

    stage-16-fc-o27-apply-gemma-llama-minimal-profile-gates-no-runtime

Required approval phrase:

    APPROVE_STAGE_16_FC_O27_APPLY_GEMMA_LLAMA_MINIMAL_PROFILE_GATES_NO_RUNTIME_NO_JOB_PROCESSING

## FC-O27 mutation scope

Allowed mutation:

- write `/etc/edge-ct101-worker/model-profiles.yaml` only, after backup.

Required non-mutations:

- no CT203 DB write,
- no job insert,
- no job reset,
- no job retry,
- no job deletion,
- no job_results insert,
- no runtime,
- no service start,
- no service enable,
- no timer start,
- no timer enable,
- no systemd unit write,
- no daemon-reload,
- no reset-failed,
- no clearing failed unit evidence,
- no worker code mutation,
- no Docker mutation,
- no Ollama mutation,
- no model pull,
- no scheduler activation,
- no persistent worker activation,
- no queue drain,
- no CT/VM restart.

## Required FC-O27 preflight

FC-O27 must verify before profile mutation:

    repo HEAD/origin/main is the FC-O26 checkpoint
    CT203 quick_check=ok
    job105 running attempts=1 rows=0
    jobs107-111 queued attempts=0 rows=0
    jobs106,112,113,114,115,116 completed attempts=1 rows=1
    CT101 worker sha unchanged
    CT101 profile sha matches FC-O25 baseline
    Ollama container running/healthy
    OLLAMA_NUM_PARALLEL=2
    active exact services=0
    active general services=0
    active exact timers=0
    active general timers=0
    failed_general_units=6

Known FC-O25 baseline shas:

    profile_sha_fc_o25=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899
    worker_sha_fc_o25=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca

## Required backup

Before writing profile changes, FC-O27 must create a root-owned backup:

    /etc/edge-ct101-worker/model-profiles.yaml.stage16-fc-o27-pre-gemma-llama-profile-gates.<UTC>.bak

The backup sha must be printed and included in the repo doc.

## Minimal profile entries to add or correct

FC-O27 should add or correct exactly these candidate profile entries.

The profile ids should be stable and explicit:

    gemma4_companion_candidate
    gemma3_companion_candidate
    gemma4_study_flashcards_candidate
    llama32_safe_refusal_candidate

### gemma4_companion_candidate

Purpose:

- first gemma4 companion proof for job107.

Required fields:

    model: gemma4:e4b
    role: companion_candidate
    max_concurrent_model_calls: 1
    claim_policy: one_at_a_time
    completion_validation_policy: exact_marker_only
    enabled_by_default: false
    thinking_mode: off
    hidethinking_required: false
    cli_flags: []
    allowed_job_types:
      - stage16_fc_companion_chat_semantic_probe

### gemma3_companion_candidate

Purpose:

- first gemma3 companion proof for job108.

Required fields:

    model: gemma3:4b
    role: companion_candidate
    max_concurrent_model_calls: 1
    claim_policy: one_at_a_time
    completion_validation_policy: exact_marker_only
    enabled_by_default: false
    thinking_mode: off
    hidethinking_required: false
    cli_flags: []
    allowed_job_types:
      - stage16_fc_companion_chat_semantic_probe

### gemma4_study_flashcards_candidate

Purpose:

- later gemma4 study and flashcards proofs for jobs109 and 110.

Required fields:

    model: gemma4:e4b
    role: study_flashcards_candidate
    max_concurrent_model_calls: 1
    claim_policy: one_at_a_time
    completion_validation_policy: exact_marker_only
    enabled_by_default: false
    thinking_mode: off
    hidethinking_required: false
    cli_flags: []
    allowed_job_types:
      - stage16_fc_study_tutor_semantic_probe
      - stage16_fc_flashcards_semantic_probe

### llama32_safe_refusal_candidate

Purpose:

- first llama3.2 safe-refusal proof for job111.

Required fields:

    model: llama3.2:3b
    role: safe_refusal_candidate
    max_concurrent_model_calls: 1
    claim_policy: one_at_a_time
    completion_validation_policy: exact_marker_only
    enabled_by_default: false
    thinking_mode: off
    hidethinking_required: false
    cli_flags: []
    allowed_job_types:
      - stage16_fc_safe_refusal_semantic_probe

## Important model mapping correction

FC-O25 showed no parsed profile for `llama3.2:3b`.

If an existing profile uses `llama32` naming but maps to a different model string, do not assume it covers job111.

The profile must map to exactly:

    llama3.2:3b

because job111 requested_model is exactly `llama3.2:3b`.

## Duplicate model rule

Because both gemma4 companion and gemma4 study/flashcards use `gemma4:e4b`, FC-O27 must avoid ambiguous model-to-profile routing.

Preferred safe option:

- use one `gemma4:e4b` profile with all intended gemma4 job types if the worker maps model string to a single profile;
- or prove the worker supports multiple profiles per same model before adding duplicate `gemma4:e4b` profile entries.

If worker profile lookup is model-keyed, use this merged profile instead:

    profile_id: gemma4_product_candidate
    model: gemma4:e4b
    role: companion_study_flashcards_candidate
    max_concurrent_model_calls: 1
    claim_policy: one_at_a_time
    completion_validation_policy: exact_marker_only
    enabled_by_default: false
    thinking_mode: off
    hidethinking_required: false
    cli_flags: []
    allowed_job_types:
      - stage16_fc_companion_chat_semantic_probe
      - stage16_fc_study_tutor_semantic_probe
      - stage16_fc_flashcards_semantic_probe

FC-O27 must inspect the actual worker profile lookup behavior before choosing split or merged gemma4 entries.

## FC-O27 post-apply verification

After profile write, FC-O27 must verify:

    profile YAML parses
    profile sha changed
    worker sha unchanged
    qwen profiles still present
    qwen3_small_structured_tier behavior not removed
    gemma4:e4b profile present
    gemma3:4b profile present
    llama3.2:3b profile present
    each target profile max_concurrent_model_calls=1
    each target profile completion_validation_policy=exact_marker_only
    each target profile enabled_by_default=false
    each target job type appears exactly where intended
    OLLAMA_NUM_PARALLEL remains 2
    no active exact/general services
    no active exact/general timers
    failed_general_units remains 6
    jobs107-111 remain queued attempts=0 rows=0

## Runtime proof sequence after FC-O27

No runtime may occur in FC-O27.

After FC-O27, use separate one-job runtime stages.

Recommended order:

1. FC-O28: run only job107, gemma4:e4b companion_chat.
2. FC-O29: run only job108, gemma3:4b companion_chat.
3. FC-O30: run only job109, gemma4:e4b study_tutor.
4. FC-O31: run only job110, gemma4:e4b flashcards.
5. FC-O32: run only job111, llama3.2:3b safe_refusal.

Each stage must:

- use explicit approval,
- start exactly one service instance,
- preserve job105,
- preserve unrelated queued/completed jobs,
- not enable persistent workers,
- not bulk drain,
- not reset failed unit evidence,
- document exact semantic pass/fail criteria.

## Semantic pass/fail handling

For gemma/llama jobs, mechanical completion is not enough.

Each proof stage must classify:

    mechanical_pass
    semantic_pass
    output_hygiene_pass
    product_surface_candidate

A job can complete mechanically and still fail product semantics.

Failures should be documented and should not trigger automatic retries without a new contract.

## Decision

FC-O26 does not apply profile changes.

Next recommended stage: FC-O27 apply gemma/llama minimal profile gates, no runtime, no job processing.
