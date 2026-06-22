# Stage 16 E3Z-CO — Model Profile Artifact Plan — No Apply

## Purpose

Define the repo artifact shape for CT101 model profiles before any persistent worker design or runtime activation.

This is a repo-only no-apply stage.

It does not mutate CT203 DB state, insert jobs, claim jobs, complete jobs, fail jobs, call models, start or stop containers, delete Docker or model data, unmask worker services, create systemd units, enable timers, or activate scheduler paths.

## Prior checkpoint

Stage 16 E3Z-CN established:

- claim exactly one job at a time
- never assume max_jobs greater than 1 is honored
- model subprocess concurrency is allowed only after model profile gates exist
- qwen3:0.6b exact-marker use requires --think=false --hidethinking
- qwen2.5:0.5b and qwen3:0.6b can each run two concurrent model calls in bounded proof mode
- all profiles remain enabled_by_default=false until a later explicit activation boundary

## Proposed artifact path

Recommended repo path:

```text
ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml
```

This path is intentionally under ops because it is runtime/operator configuration, not application source logic.

## Proposed schema

Each profile should include:

```yaml
profile_id: string
model_name: string
role: string
endpoint_type: ollama_cli_in_container
container_name: ollama
cli_flags: list[string]
timeout_seconds: integer
max_concurrent_model_calls: integer
claim_policy: one_at_a_time
exact_marker_supported: boolean
thinking_mode: none|disabled|unknown|must_be_proven
hidethinking_required: boolean
allowed_job_types: list[string]
completion_validation_policy: exact_marker_only|no_default_until_proven
enabled_by_default: boolean
notes: string
```

## Initial profiles

### qwen25_router_small

```yaml
profile_id: qwen25_router_small
model_name: qwen2.5:0.5b
role: router_small
endpoint_type: ollama_cli_in_container
container_name: ollama
cli_flags: []
timeout_seconds: 90
max_concurrent_model_calls: 2
claim_policy: one_at_a_time
exact_marker_supported: true
thinking_mode: none
hidethinking_required: false
allowed_job_types:
  - stage16_e3z_cj_concurrency_model_proof
  - future_router_small_probe
completion_validation_policy: exact_marker_only
enabled_by_default: false
notes: Proven exact marker and two-call bounded concurrency in Stage 16 E3Z.
```

### qwen3_router_small

```yaml
profile_id: qwen3_router_small
model_name: qwen3:0.6b
role: router_small
endpoint_type: ollama_cli_in_container
container_name: ollama
cli_flags:
  - --think=false
  - --hidethinking
timeout_seconds: 90
max_concurrent_model_calls: 2
claim_policy: one_at_a_time
exact_marker_supported: true
thinking_mode: disabled
hidethinking_required: true
allowed_job_types:
  - stage16_e3z_cj_concurrency_model_proof
  - future_router_small_probe
completion_validation_policy: exact_marker_only
enabled_by_default: false
notes: Proven exact marker and two-call bounded concurrency only with thinking disabled and hidden.
```

### qwen3_1_7b_candidate

```yaml
profile_id: qwen3_1_7b_candidate
model_name: qwen3:1.7b
role: router_small_or_study_light_candidate
endpoint_type: ollama_cli_in_container
container_name: ollama
cli_flags: []
timeout_seconds: 120
max_concurrent_model_calls: 1
claim_policy: one_at_a_time
exact_marker_supported: false
thinking_mode: must_be_proven
hidethinking_required: false
allowed_job_types:
  - future_single_model_probe_only
completion_validation_policy: no_default_until_proven
enabled_by_default: false
notes: Installed model candidate, not yet proven through CT203 queue path.
```

### gemma3_study_light_candidate

```yaml
profile_id: gemma3_study_light_candidate
model_name: gemma3:4b
role: study_light_candidate
endpoint_type: ollama_cli_in_container
container_name: ollama
cli_flags: []
timeout_seconds: 180
max_concurrent_model_calls: 1
claim_policy: one_at_a_time
exact_marker_supported: false
thinking_mode: unknown
hidethinking_required: false
allowed_job_types:
  - future_single_model_probe_only
completion_validation_policy: no_default_until_proven
enabled_by_default: false
notes: Installed study-light candidate, not yet proven through CT203 queue path.
```

### gemma4_companion_candidate

```yaml
profile_id: gemma4_companion_candidate
model_name: gemma4:e4b
role: companion_default_candidate
endpoint_type: ollama_cli_in_container
container_name: ollama
cli_flags: []
timeout_seconds: 240
max_concurrent_model_calls: 1
claim_policy: one_at_a_time
exact_marker_supported: false
thinking_mode: unknown
hidethinking_required: false
allowed_job_types:
  - future_single_model_probe_only
completion_validation_policy: no_default_until_proven
enabled_by_default: false
notes: Installed companion candidate, not yet proven through CT203 queue path. Keep single-call only until proof passes.
```

## Validation rules for the future artifact

A smoke test should verify:

1. YAML parses.
2. profile_id values are unique.
3. model_name values are non-empty.
4. every profile uses claim_policy: one_at_a_time.
5. qwen3_router_small includes --think=false and --hidethinking.
6. qwen25_router_small has max_concurrent_model_calls: 2.
7. qwen3_router_small has max_concurrent_model_calls: 2.
8. unproven candidate profiles have max_concurrent_model_calls: 1.
9. every profile has enabled_by_default: false.
10. no profile allows scheduler, timer, broad compose, Docker deletion, or public model exposure.

## Recommended next stages

### CP — create model profile artifact repo-only

Create the YAML artifact and a smoke test that parses and validates it.

Still no model calls and no runtime activation.

### CQ — CT101 minimal worker design no-apply

Design a default-off worker that reads the model profile artifact and keeps claim_policy one_at_a_time.

### CR — worker implementation plan no-apply

Plan code/service changes without installing or starting any service.

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

Do not create the actual model profile artifact in this plan stage.

Do not change claim endpoint behavior in this stage.
