# Stage 16 E3Z-CN — Worker Claim and Model Profile Contract Plan — No Apply

## Purpose

Define the contract for the next CT101 worker design after the successful CT101 Ollama small-model concurrency proofs.

This is a repo-only no-apply stage.

It does not mutate CT203 DB state, insert jobs, claim jobs, complete jobs, fail jobs, call models, start or stop containers, delete Docker or model data, unmask worker services, create systemd units, enable timers, or activate scheduler paths.

## Prior milestone

Stage 16 E3Z-CM recorded:

- repo checkpoint: b81ffdd
- jobs_total: 43
- job_results_total: 24
- jobs_status_running: 0
- jobs 37 through 44 completed attempts=1 result_rows=1
- qwen2.5:0.5b two-call concurrency overlap: 1.452 seconds
- qwen3:0.6b two-call concurrency overlap: 0.566 seconds
- qwen3 exact-marker mode requires --think=false --hidethinking
- CT101 runtime containment remained ollama-only
- CT101 persistent worker service remained inactive and masked

## Claim endpoint behavior

Observed behavior:

- The CT203 internal worker claim endpoint returned only one claimed job when called with claim_job_ids containing two jobs and max_jobs=2.
- This happened during the qwen2.5 concurrency proof.
- Client-side model calls can run concurrently.
- Queue claiming should be treated as one-at-a-time until intentionally changed.

Current contract:

- Claim exactly one job at a time.
- Complete exactly the job that was claimed.
- Never assume that max_jobs greater than 1 is honored.
- Never claim a second job while a previously claimed proof job is left running.
- If a stage exits after claim but before completion, run a read-only validator first, then complete or fail the exact running job by explicit continuation.

## Worker execution contract

The next CT101 worker design should use this sequence:

1. Read model profile.
2. Select eligible queued job.
3. Claim one exact job.
4. Run one model call for that job.
5. Verify output according to job/profile policy.
6. Complete only exact/successful results.
7. Fail only explicitly allowed job IDs when a fail path is approved.
8. Return to idle.

Concurrency should not mean multiple DB claims at first.

Instead:

- model subprocess concurrency is allowed only after model profile gates exist
- claim policy remains one-at-a-time initially
- multi-claim behavior is a later intentional endpoint change

## Model profile contract

A model profile must specify:

- profile_id
- model_name
- role
- endpoint_type
- cli_flags
- timeout_seconds
- max_concurrent_model_calls
- claim_policy
- exact_marker_supported
- thinking_mode
- hidethinking_required
- allowed_job_types
- default_temperature_policy
- completion_validation_policy
- enabled_by_default

## Initial model profiles

### qwen25_router_small

- model_name: qwen2.5:0.5b
- role: router_small
- endpoint_type: ollama_cli_in_container
- cli_flags: none
- timeout_seconds: 90
- max_concurrent_model_calls: 2
- claim_policy: one_at_a_time
- exact_marker_supported: true
- thinking_mode: none
- hidethinking_required: false
- allowed_job_types:
  - stage16_e3z_cj_concurrency_model_proof
  - future_router_small_probe
- completion_validation_policy: exact_marker_only
- enabled_by_default: false

### qwen3_router_small

- model_name: qwen3:0.6b
- role: router_small
- endpoint_type: ollama_cli_in_container
- cli_flags:
  - --think=false
  - --hidethinking
- timeout_seconds: 90
- max_concurrent_model_calls: 2
- claim_policy: one_at_a_time
- exact_marker_supported: true
- thinking_mode: disabled
- hidethinking_required: true
- allowed_job_types:
  - stage16_e3z_cj_concurrency_model_proof
  - future_router_small_probe
- completion_validation_policy: exact_marker_only
- enabled_by_default: false

### qwen3_1_7b_candidate

- model_name: qwen3:1.7b
- role: router_small_or_study_light_candidate
- endpoint_type: ollama_cli_in_container
- cli_flags: not_yet_proven
- timeout_seconds: 120
- max_concurrent_model_calls: 1
- claim_policy: one_at_a_time
- exact_marker_supported: unknown
- thinking_mode: must_be_proven
- hidethinking_required: unknown
- allowed_job_types:
  - future_single_model_probe_only
- completion_validation_policy: no_default_until_proven
- enabled_by_default: false

### gemma3_study_light_candidate

- model_name: gemma3:4b
- role: study_light_candidate
- endpoint_type: ollama_cli_in_container
- cli_flags: not_yet_proven
- timeout_seconds: 180
- max_concurrent_model_calls: 1
- claim_policy: one_at_a_time
- exact_marker_supported: unknown
- thinking_mode: none_or_unknown
- hidethinking_required: false
- allowed_job_types:
  - future_single_model_probe_only
- completion_validation_policy: no_default_until_proven
- enabled_by_default: false

### gemma4_companion_candidate

- model_name: gemma4:e4b
- role: companion_default_candidate
- endpoint_type: ollama_cli_in_container
- cli_flags: not_yet_proven
- timeout_seconds: 240
- max_concurrent_model_calls: 1
- claim_policy: one_at_a_time
- exact_marker_supported: unknown
- thinking_mode: none_or_unknown
- hidethinking_required: false
- allowed_job_types:
  - future_single_model_probe_only
- completion_validation_policy: no_default_until_proven
- enabled_by_default: false

## Persistent worker activation boundary

Do not start, unmask, enable, or install any persistent CT101 worker service from this stage.

A later no-apply worker design stage must explicitly define:

- worker unit name
- environment file path
- token handling
- CT203 API base
- job type allowlist
- model profile file path
- max runtime per job
- log path
- rollback
- masked/default-off posture

A later apply stage must require explicit approval before:

- creating or modifying systemd units
- unmasking worker services
- starting worker services
- enabling worker services
- activating scheduler or timer
- changing CT203 claim endpoint behavior

## Recommended next phases

### CO — model profile artifact plan no-apply

Create a repo-only model profile artifact design and smoke test.

### CP — CT101 minimal worker design no-apply

Design a minimal CT101 worker that remains default-off and uses the model profile contract.

### CQ — CT203 claim endpoint behavior decision no-apply

Decide whether to keep one-at-a-time claiming or implement a separate batch-claim endpoint.

Recommended order:

1. CO model profile artifact plan.
2. CP CT101 minimal worker design.
3. CQ claim endpoint decision.
4. Only after those: explicit apply boundary.

## Non-goals

Do not rerun jobs 37 through 44.

Do not insert new jobs.

Do not call models.

Do not delete models.

Do not prune Docker data.

Do not start CT101 persistent worker service.

Do not unmask CT101 persistent worker service.

Do not activate scheduler or timer.

Do not start broader /opt/ai-platform compose stacks.

Do not expose model endpoints directly to public users.

Do not change claim endpoint behavior in this stage.
