# Stage 16 E3Z-CS — CT101 Worker Skeleton — Repo Only

## Purpose

Create a repository-only CT101 minimal Ollama worker skeleton, README, service example, and smoke test.

This stage is repo-only.

It does not mutate CT203 DB state, insert jobs, claim jobs, complete jobs, fail jobs, call models, connect to live CT203, connect to live CT101, start or stop containers, delete Docker or model data, unmask worker services, create live systemd units, enable timers, or activate scheduler paths.

## Files created

```text
ops/workers/ct101_minimal_ollama_worker.py
ops/workers/README-ct101-minimal-ollama-worker.md
ops/systemd/ct101/edge-ct101-ollama-worker.service.example
ops/smoke/check-stage-16-e3z-cs-ct101-worker-skeleton-repo-only.sh
```

## Worker skeleton behavior

The skeleton includes functions for:

- load_env
- load_token
- load_model_profiles
- validate_model_profile_document
- runtime_preflight
- get_eligible_profile_for_job
- claim_one_job
- build_ollama_command
- run_ollama_call
- clean_model_output
- extract_expected_marker
- validate_completion
- complete_job
- main_once
- main_loop

The skeleton refuses live execution unless explicitly enabled.

## Repo-only self-test

The self-test validates:

- model profile YAML loads
- qwen2.5 command construction
- qwen3 command construction with flags before model name
- no incorrect `--think false` syntax
- ANSI/control output cleaning
- exact-marker parsing
- exact-marker validation refusal on mismatch
- disabled worker refuses runtime

## Runtime posture

No runtime service is installed.

No runtime service is started.

No runtime files are copied to `/etc` or `/var/log`.

The systemd file is example-only.

## Non-goals

Do not rerun jobs 37 through 44.

Do not insert new jobs.

Do not call models.

Do not connect to live CT203 API.

Do not connect to live CT101.

Do not delete models.

Do not prune Docker data.

Do not start CT101 persistent worker service.

Do not unmask CT101 persistent worker service.

Do not activate scheduler or timer.

Do not start broader `/opt/ai-platform` compose stacks.

Do not expose model endpoints directly to public users.

Do not change CT203 claim endpoint behavior in this stage.

Do not create live systemd units in this stage.

Do not create runtime files under `/etc` or `/var/log` in this stage.
