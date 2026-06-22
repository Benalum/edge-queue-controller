# CT101 Minimal Ollama Worker Skeleton

This directory contains the Stage 16 E3Z repo-only CT101 worker skeleton.

The skeleton is default-off and safe to test without live runtime access.

## Safety posture

The worker must not run live unless explicitly enabled with:

```text
EDGE_WORKER_ENABLED=1
```

The repo smoke uses only:

```text
python3 ops/workers/ct101_minimal_ollama_worker.py --self-test
```

The self-test does not connect to CT203, CT101, Docker, Ollama, systemd, scheduler, or timers.

## Contract

- Claim one job at a time.
- Complete only the claimed job.
- Use model profile artifact gates.
- Use qwen3 flags exactly as:
  - `--think=false`
  - `--hidethinking`
- Never use `--think false`.
- Preserve ollama-only containment.
- Keep service installation/start behind a later explicit approval boundary.

## Model profiles

Current artifact:

```text
ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml
```

All profiles remain `enabled_by_default: false`.
