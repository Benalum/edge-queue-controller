# Stage 16 E3Z-CP — Create Model Profile Artifact — Repo Only

## Purpose

Create the first repo-only CT101 Ollama model profile artifact and validation smoke test.

This stage is repository-only.

It does not mutate CT203 DB state, insert jobs, claim jobs, complete jobs, fail jobs, call models, start or stop containers, delete Docker or model data, unmask worker services, create systemd units, enable timers, or activate scheduler paths.

## Artifact created

```text
ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml
```

## Smoke created

```text
ops/smoke/check-stage-16-e3z-cp-create-model-profile-artifact-repo-only.sh
```

## Contract captured

The artifact records:

- CT101 as runtime owner
- Ollama Docker container as model runtime
- `ollama` as container name
- one-at-a-time CT203 claim policy
- disabled-by-default posture
- qwen2.5:0.5b proven router-small profile
- qwen3:0.6b proven router-small profile with `--think=false --hidethinking`
- qwen3:1.7b, gemma3:4b, and gemma4:e4b as unproven disabled candidates

## Proven model defaults

### qwen25_router_small

- model: qwen2.5:0.5b
- role: router_small
- max_concurrent_model_calls: 2
- claim_policy: one_at_a_time
- completion_validation_policy: exact_marker_only
- enabled_by_default: false

### qwen3_router_small

- model: qwen3:0.6b
- role: router_small
- flags:
  - --think=false
  - --hidethinking
- max_concurrent_model_calls: 2
- claim_policy: one_at_a_time
- completion_validation_policy: exact_marker_only
- enabled_by_default: false

## Candidate model defaults

Unproven candidates are kept at single-call only:

- qwen3:1.7b
- gemma3:4b
- gemma4:e4b

Each remains:

- max_concurrent_model_calls: 1
- completion_validation_policy: no_default_until_proven
- enabled_by_default: false

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
