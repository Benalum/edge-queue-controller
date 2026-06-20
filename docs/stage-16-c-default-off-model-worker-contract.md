# Stage 16-C — Default-Off Model Worker Contract

Date: 2026-06-19
Base checkpoint: Stage 16-B / HEAD 5db1b1d

## Scope

Stage 16-C is a repo-only code/docs/smoke checkpoint.

It adds a default-off model worker contract helper:

- edge_model_worker_contract.py

It does not deploy this helper to CT203.

It does not wire this helper into the live controller.

It does not start a worker.

It does not start a scheduler.

It does not call Ollama.

It does not call any model endpoint.

It does not write the database.

## Purpose

Stage 16-C converts the Stage 16-A and Stage 16-B plan into a small, inspectable, testable contract before any runtime activation is approved.

The contract defines:

- the explicit enable flag;
- the explicit confirmation phrase;
- the default test job type;
- the default first small-model candidate;
- the default worker id;
- the queue-owned-only rule;
- the direct-Ollama-blocked rule;
- the expected one-job DB delta for the later controlled activation phase.

## Default-off controls

The future model-worker path is disabled unless both are present:

- EDGE_STAGE16_MODEL_WORKER_ENABLED=true
- EDGE_STAGE16_MODEL_WORKER_CONFIRM=APPROVE_STAGE_16_D_ONE_CONTROLLED_QUEUE_MODEL_TEST

The required approval phrase for any future runtime test is:

APPROVE_STAGE_16_D_ONE_CONTROLLED_QUEUE_MODEL_TEST

## Initial contract defaults

Selected target:

pvew-local-ollama-candidate

Default worker id:

stage16-local-model-worker-1

Default job type:

companion.chat

Default first small model candidate:

qwen2.5:0.5b

Default result table:

job_results

## Required future activation path

Users must never talk directly to models.

The future Stage 16-D test must use:

Frontend -> CT203 API -> durable job row -> explicit decision/scheduler policy -> default-off worker path -> model runtime -> job_results row -> frontend poll.

Direct /tick/ollama-direct remains blocked for this rollout path.

## Expected later Stage 16-D DB delta

For one controlled future model test, the expected DB delta is:

- jobs: +1
- job_results: +1
- router_logs: +0
- router_resolution_steps: +0
- router_feedback: +0

Any broader delta requires separate approval.

## Not allowed in Stage 16-C

No PVEW SSH.

No backend deploy.

No frontend deploy.

No DB write.

No service reload or restart.

No CT or VM restart.

No worker activation.

No scheduler activation.

No Ollama endpoint calls.

No live model endpoint calls.

No ollama list, ollama pull, ollama run, or ollama show.

No /tick/ollama-direct calls.

No CT204 start.

No private storage unlock or mount.

No PVESO mutation.

## Next recommended phase

Stage 16-D0 should be a final pre-activation read-only checklist that selects the exact runtime command and rollback path before asking for the Stage 16-D approval phrase.
