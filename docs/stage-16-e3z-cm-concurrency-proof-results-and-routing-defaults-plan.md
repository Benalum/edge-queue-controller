# Stage 16 E3Z-CM — Concurrency Proof Results and Routing Defaults Plan

## Purpose

Record the completed CT101 Ollama container small-model concurrency proofs and define the next safe routing/concurrency defaults.

This stage is repo-only documentation and smoke.

It does not mutate CT203 DB state, insert jobs, claim jobs, complete jobs, fail jobs, call models, start or stop containers, delete Docker or model data, unmask worker services, or activate scheduler or timer paths.

## Current repo checkpoint entering CM

- Previous repo checkpoint: 3409b96
- Previous tag: controller-stage-16-e3z-ci-deterministic-model-proof-summary-and-concurrency-probe-plan-2026-06-22

## Final live proof state after CL

CT203 DB after CL:

- DB integrity: ok
- jobs_total: 43
- job_results_total: 24
- jobs_status_running: 0

Completed proof jobs:

- job 37:
  - model: qwen2.5:0.5b
  - response: E3Z-MODEL-A-OK
  - result: endpoint transport exact success
- job 38:
  - model: qwen2.5:0.5b
  - response: ENDPOINT-PROOF-E3Z-MODEL-B OK
  - result: transport success with response adherence failure
- job 39:
  - model: qwen2.5:0.5b
  - response: E3Z-DET-QWEN25-OK
  - result: deterministic exact success
- job 40:
  - model: qwen3:0.6b
  - response: E3Z-DET-QWEN3-OK
  - result: deterministic exact success with thinking disabled
- job 41:
  - model: qwen2.5:0.5b
  - response: E3Z-CON-QWEN25-A-OK
  - result: concurrency proof exact success
- job 42:
  - model: qwen2.5:0.5b
  - response: E3Z-CON-QWEN25-B-OK
  - result: concurrency proof exact success
- job 43:
  - model: qwen3:0.6b
  - response: E3Z-CON-QWEN3-A-OK
  - result: concurrency proof exact success with thinking disabled
- job 44:
  - model: qwen3:0.6b
  - response: E3Z-CON-QWEN3-B-OK
  - result: concurrency proof exact success with thinking disabled

CT101 runtime after CL:

- CT101 worker service: inactive and masked
- Docker and containerd: active
- Running Docker containers: ollama only
- No scheduler activation
- No timer activation
- No broad compose stack activation

## Concurrency proof results

### qwen2.5:0.5b two-call proof

Stage CK proved that two qwen2.5:0.5b model calls can run concurrently inside the CT101 Ollama container.

Observed values:

- concurrency batch elapsed seconds: 1.695
- model call overlap seconds: 1.452
- job 41 model output: E3Z-CON-QWEN25-A-OK
- job 42 model output: E3Z-CON-QWEN25-B-OK

Both outputs were exact before any DB claim/complete mutation.

The CT203 claim endpoint returned only one claimed job when asked for two jobs. Job 41 was completed in a continuation step, and job 42 was later claimed and completed one at a time. This means client-side model concurrency is proven, but queue claiming should be treated as one-at-a-time until the claim endpoint is intentionally changed and retested.

### qwen3:0.6b two-call proof

Stage CL proved that two qwen3:0.6b model calls can run concurrently inside the CT101 Ollama container when thinking is disabled.

Required flags:

- --think=false
- --hidethinking

Observed values:

- concurrency batch elapsed seconds: 0.792
- model call overlap seconds: 0.566
- job 43 model output: E3Z-CON-QWEN3-A-OK
- job 44 model output: E3Z-CON-QWEN3-B-OK

Both outputs were exact before claim/complete mutation. Jobs 43 and 44 were then claimed and completed one at a time in the same stage.

## Key findings

1. CT203 to CT101 transport is proven.
2. CT101 to Ollama Docker model execution is proven.
3. CT101 completion back to CT203 is proven.
4. qwen2.5:0.5b supports exact-marker deterministic endpoint behavior.
5. qwen3:0.6b supports exact-marker deterministic endpoint behavior only when thinking is disabled and hidden.
6. Small-model client-side concurrency is proven for qwen2.5:0.5b and qwen3:0.6b.
7. The CT203 claim endpoint currently behaves as one-at-a-time for these proof calls.
8. Runtime containment remained intact: only the ollama container was running, with the persistent CT101 worker service inactive and masked.

## Initial routing and concurrency defaults

Recommended defaults before any persistent worker activation:

### qwen2.5:0.5b

- role: router_small
- endpoint flags: none
- initial concurrent model calls: 2
- claim policy: one-at-a-time
- complete policy: exact output only
- use cases:
  - fast intent routing
  - simple marker-gated proof tasks
  - low-cost queue plumbing tests

### qwen3:0.6b

- role: router_small
- endpoint flags: --think=false --hidethinking
- initial concurrent model calls: 2
- claim policy: one-at-a-time
- complete policy: exact output only
- use cases:
  - alternative small router candidate
  - exact-marker tasks only when thinking is disabled

### qwen3:1.7b

- role: router_small or study_light candidate
- endpoint flags: not yet proven
- initial concurrent model calls: 1
- next proof needed:
  - deterministic exact marker
  - thinking-disabled behavior
  - bounded latency profile

### gemma3:4b

- role: study_light candidate
- endpoint flags: not yet proven in this queue path
- initial concurrent model calls: 1
- next proof needed:
  - deterministic exact marker
  - latency profile
  - one-at-a-time queue completion

### gemma4:e4b

- role: companion_default candidate
- endpoint flags: not yet proven in this queue path
- initial concurrent model calls: 1
- next proof needed:
  - single-call exact marker or structured response
  - memory and latency profile
  - no concurrency until single-call proof passes

## Recommended next implementation path

### CN — repo-only worker claim behavior plan

Document the one-at-a-time claim behavior and decide whether to keep it or modify the endpoint.

Options:

1. Keep one-at-a-time claiming for safety.
2. Add a separate batch-claim endpoint after more review.
3. Update the existing claim endpoint to honor max_jobs and claim_job_ids as a batch.

Recommended choice for now:

- keep one-at-a-time claiming for runtime safety
- let the worker launch bounded model subprocesses concurrently only after it has safely selected work
- revisit batch claim after the first persistent worker design is documented

### CO — repo-only model profile configuration plan

Define a model profile configuration artifact that records:

- model name
- role
- required CLI flags
- max concurrent calls
- timeout
- exact-marker support
- thinking mode requirements
- queue claim policy
- allowed job types

### CP — no-apply CT101 minimal worker design

Design a minimal CT101 worker service that:

- remains disabled by default
- claims one job at a time initially
- can run bounded model calls according to model profile defaults
- never starts broad compose stacks
- talks only to CT203 internal worker API
- uses exact output verification for proof jobs
- preserves container containment

## Non-goals

Do not rerun jobs 37 through 44.

Do not delete models.

Do not prune Docker data.

Do not start CT101 persistent worker service.

Do not activate scheduler or timer.

Do not start broader /opt/ai-platform compose stacks.

Do not expose model endpoints directly to public users.

Do not change the claim endpoint behavior without a separate repo plan and explicit approval.
