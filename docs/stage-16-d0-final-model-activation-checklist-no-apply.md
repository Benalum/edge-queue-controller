# Stage 16-D0 — Final Model Activation Checklist, No Apply

Date: 2026-06-19
Base checkpoint: Stage 16-C / HEAD a2f5aeb

## Scope

Stage 16-D0 is a final read-only pre-activation checklist.

It does not approve or perform model activation.

It does not deploy backend code.

It does not deploy frontend code.

It does not write the database.

It does not start, stop, restart, reload, enable, or disable services.

It does not start or stop CTs or VMs.

It does not call Ollama.

It does not call model endpoints.

It does not run ollama list, ollama pull, ollama run, or ollama show.

It does not call /tick/ollama-direct.

## Stage 16-C contract baseline

The default-off contract currently defines:

- selected target: pvew-local-ollama-candidate
- worker id: stage16-local-model-worker-1
- queue job type: companion.chat
- first small model candidate: qwen2.5:0.5b
- result table: job_results
- required confirmation phrase: APPROVE_STAGE_16_D_ONE_CONTROLLED_QUEUE_MODEL_TEST

The contract remains disabled unless both are set:

- EDGE_STAGE16_MODEL_WORKER_ENABLED=true
- EDGE_STAGE16_MODEL_WORKER_CONFIRM=APPROVE_STAGE_16_D_ONE_CONTROLLED_QUEUE_MODEL_TEST

## Required activation path

Users must never talk directly to models.

The only acceptable future test path is:

Frontend -> CT203 API -> durable job row -> explicit decision/scheduler policy -> default-off worker path -> model runtime -> job_results row -> frontend poll.

Direct /tick/ollama-direct remains blocked for this rollout path.

## Expected one-test DB delta

For a future approved Stage 16-D one-job test:

- jobs: +1
- job_results: +1
- router_logs: +0
- router_resolution_steps: +0
- router_feedback: +0

Any broader delta requires separate approval.

## Required Stage 16-D approval

Do not run Stage 16-D unless the user explicitly provides:

APPROVE_STAGE_16_D_ONE_CONTROLLED_QUEUE_MODEL_TEST

## Stage 16-D must specify before execution

Before any activation block is provided, the execution plan must state:

- exact target host or container;
- exact model runtime command or service;
- exact model name;
- exact queue job type;
- exact worker identity;
- exact environment flags;
- exact DB rows expected to change;
- exact rollback or disable path;
- exact post-checks proving CT204 remains stopped;
- exact post-checks proving private storage remains locked;
- exact post-checks proving no broad scheduler activation occurred.

## Stop conditions

Do not proceed to activation if any of these are true:

- repo is dirty;
- CT204 is running;
- private storage is mounted;
- private storage mapper exists;
- CT203 controller service is unhealthy;
- VM200 public path is unhealthy;
- target runtime is absent and no default-off install plan exists;
- selected model is unavailable and no bounded pull/install approval exists;
- rollback path is unclear;
- DB delta cannot be bounded to one job and one result row.

## Recommended next step

If the checklist proves target runtime and rollback are ready, ask for the Stage 16-D approval phrase.

If the checklist shows runtime or model availability is blocked, perform a no-apply Stage 16-D-blocker plan instead.
