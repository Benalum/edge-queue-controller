# Phase 11I Companion Ollama Latency and Model Availability Probe

Phase 11I follows Phase 11H and probes the configured Companion Ollama path.

## Baseline

Previous checkpoint:

- Phase: Phase 11H
- Commit: 291f8e1 docs: inspect companion ollama timeout phase 11h
- Tag: controller-phase-11h-companion-queued-ollama-timeout-inspection-2026-06-13
- Result: PASS

## Problem being investigated

A normal Companion chat job failed with:

- stage 5e21 bounded ollama failure
- Ollama request failed: timed out
- fallback model: gemma4:e4b

Phase 11H showed the browser route and polling path are working. The failure is likely in the worker to Ollama/model response path.

## Configured probe target

- OLLAMA_BASE_URL: http://100.88.245.33:11434
- OLLAMA_MODEL: gemma4:e4b

## Goal

Determine whether the configured Ollama endpoint and fallback model are reachable and fast enough for Companion chat.

## Safety posture

Allowed:

- GET /api/version
- GET /api/tags
- One tiny direct Ollama model probe with a bounded timeout
- Read-only logs/config inspection
- No service restart

Not allowed:

- No Companion job creation
- No queue mutation
- No model pulls
- No service restarts
- No router rollout
- No auth or route-boundary changes

## Done criteria

Phase 11I is done when:

- This doc exists.
- A bounded smoke exists.
- The smoke records Ollama reachability.
- The smoke records whether the fallback model appears in /api/tags.
- The smoke records whether a tiny direct model prompt completes or times out.
- The checkpoint is committed, tagged, and pushed only after the inspection completes.

## Phase 11I Smoke Evidence

Generated: 2026-06-13T00:55:01-06:00

### Git

```text
291f8e1 docs: inspect companion ollama timeout phase 11h
b9ede0e fix: use system status readiness phase 11g
2ab7fb2 fix: complete system loading render phase 11f
328ae3f fix: stabilize system page render phase 11e
e0d2f8e docs: inspect system page double render phase 11d
29805d9 style: polish admin system dashboard css phase 11c
3523ff3 docs: inspect admin system dashboard polish phase 11b
7e1501e docs: add phase 11a post-transition product quality plan
9c3572f test: checkpoint transition complete baseline stage 10o
d0f5b4f test: verify post cache system status stability stage 10n
e53b0e3 perf: cache system status briefly stage 10m
eadbe18 test: inspect system status backend dependencies stage 10l
controller-phase-11h-companion-queued-ollama-timeout-inspection-2026-06-13
```

### Ollama target

```text
OLLAMA_BASE_URL=http://100.88.245.33:11434
OLLAMA_MODEL=gemma4:e4b
version_http_code=200
tags_http_code=200
```

### Interpretation

If the tiny direct model probe is slow or times out, Phase 11J should either use a faster fallback model, increase the bounded worker timeout, or add a warmup/preflight path.
