# Stage 16 FC-O45-E-CK-F — Marker-Selected Manual Companion Wrapper

Date: 2026-06-26

## Scope

Repo ops/docs/smoke only.

No frontend patch. No frontend deploy. No public /var/www mutation. No backend deploy. No CT203 runtime patch. No systemd install. No service start/stop/restart. No service enable. No timer install/enable/start. No DB write. No job mutation. No result insert. No model/helper/Ollama call. No scheduler/timer/persistent-worker activation. No CT/VM restart. No secret values printed.

## Selector wrapper source

    ops/workers/run-next-deterministic-companion-systemd-once.sh

## Purpose

The selector wrapper is a safer manual admin/runbook layer above:

    run-deterministic-companion-systemd-once.sh

Instead of requiring the operator to pass a job id directly, it finds exactly one queued `companion.chat` job by exact expected marker.

## Required invocation

    run-next-deterministic-companion-systemd-once.sh --expected-marker <marker>

## Selection rules

The selector only chooses a job when exactly one row matches all of these conditions:

    job_type=companion.chat
    status=queued
    attempts=0
    prompt contains the exact expected marker
    result_rows=0

If no job matches, it refuses.

If more than one job matches, it refuses.

## Delegation

After selecting exactly one job id, the selector delegates to:

    /opt/edge-queue-controller/ops/workers/run-deterministic-companion-systemd-once.sh --job-id <job_id> --expected-marker <marker>

The delegate wrapper then creates the per-job env file, starts exactly one systemd one-shot instance, verifies final DB state, and removes the env file.

## Explicitly not included

The selector does not insert jobs.

The selector does not poll the queue.

The selector does not enable a service.

The selector does not install or enable a timer.

The selector does not activate a persistent worker.

The selector does not call PVESO, Ollama, or any model endpoint.

## Next recommendation

Install this selector wrapper on CT203, then prove one fresh exact-answer Companion job through the selector.
