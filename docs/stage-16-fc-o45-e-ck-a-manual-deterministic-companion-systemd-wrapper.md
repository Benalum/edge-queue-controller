# Stage 16 FC-O45-E-CK-A — Manual Deterministic Companion Systemd Wrapper

Date: 2026-06-26

## Scope

Repo ops/docs/smoke only.

No frontend patch. No frontend deploy. No public /var/www mutation. No backend deploy. No CT203 runtime patch. No systemd install. No service start/stop/restart. No service enable. No timer install/enable/start. No DB write. No job mutation. No result insert. No model/helper/Ollama call. No scheduler/timer/persistent-worker activation. No CT/VM restart. No secret values printed.

## Wrapper source

    ops/workers/run-deterministic-companion-systemd-once.sh

## Purpose

The wrapper is a manual admin/runbook tool for one approved deterministic Companion job.

It creates the per-job runtime env file, starts exactly one systemd one-shot instance, verifies final DB state, and removes the env file.

## Required invocation

    run-deterministic-companion-systemd-once.sh --job-id <job_id> --expected-marker <marker>

## Safety checks

The wrapper refuses unless:

    - job id is explicit and numeric,
    - expected marker is explicit,
    - result model is backend-deterministic/no-model,
    - systemd template is installed,
    - systemd template is static/disabled/indirect,
    - runtime helper is executable,
    - job exists,
    - job is queued,
    - job attempts are zero,
    - job type is companion.chat,
    - prompt contains the expected marker,
    - result rows are zero.

## Runtime behavior

The wrapper creates:

    /run/edge-queue-controller/deterministic-companion-worker/<job_id>.env

with mode:

    0600

Then it starts:

    edge-deterministic-companion-worker-once@<job_id>.service

After success, it verifies:

    status=completed
    attempts=1
    result_rows=1
    result_model=backend-deterministic/no-model
    response=<expected marker>
    error=None

Then it removes the per-job env file.

## Explicitly not included

The wrapper does not insert jobs.

The wrapper does not enable a service.

The wrapper does not install or enable a timer.

The wrapper does not poll the queue.

The wrapper does not activate a persistent worker.

The wrapper does not call PVESO, Ollama, or any model endpoint.

## Next recommendation

Install this wrapper on CT203, then prove one fresh job through the wrapper.
