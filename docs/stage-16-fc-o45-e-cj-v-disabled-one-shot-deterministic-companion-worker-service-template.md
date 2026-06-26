# Stage 16 FC-O45-E-CJ-V — Disabled One-Shot Deterministic Companion Worker Service Template

Date: 2026-06-26

## Scope

Repo ops/systemd/docs/smoke only.

No frontend patch. No frontend deploy. No public /var/www mutation. No backend deploy. No CT203 runtime patch. No systemd install. No service start/stop/restart. No service enable. No DB write. No schema migration. No job mutation. No result insert. No model/helper/Ollama call. No scheduler/timer/persistent-worker activation. No CT/VM restart. No secret values printed.

## Unit source

    ops/systemd/edge-deterministic-companion-worker-once@.service

## Purpose

This service template is a disabled-by-default one-shot wrapper around:

    ops/workers/run-deterministic-companion-exact-once.py

It is intended to run one approved exact-answer `companion.chat` job id through the internal edge-worker claim and complete endpoints.

## Runtime contract

The instance id is the job id:

    edge-deterministic-companion-worker-once@<job_id>.service

The per-job runtime environment file is:

    /run/edge-queue-controller/deterministic-companion-worker/<job_id>.env

That file must provide:

    EDGE_EXPECTED_MARKER=<exact expected marker>

Optional overrides:

    EDGE_ALLOWED_MODEL=qwen2.5:0.5b
    EDGE_RESULT_MODEL=backend-deterministic/no-model

The internal token still comes only from:

    /etc/edge-queue-controller/edge-queue-controller.env

under:

    LAPTOP_QUEUE_INTERNAL_TOKEN

The token is sent as:

    X-Laptop-Queue-Token

## Disabled-by-default posture

The template has no `WantedBy`.

It must not be enabled.

It must not be scheduled by a timer.

It must only be started explicitly for one approved job id.

## Safety boundary

The helper must:

    - claim exactly one caller-provided job id,
    - handle claim response key claimed,
    - require deterministic exact-answer companion_execution,
    - require complete_without_model=true,
    - require model_call_allowed=false,
    - store result model backend-deterministic/no-model,
    - never call PVESO, Ollama, or a model endpoint.

## Next recommendation

Install this helper and service template on CT203 without enabling it, then prove one explicit systemd start for one fresh exact-answer Companion job.
