# Phase 14I-C - Secret-Safe Runtime/Timer Path Inspection

Status: inspection recorded

## Purpose

Phase 14I-C records the secret-safe inspection of active runtime timer paths before any future persistent lane worker activation work.

This phase does not enable workers.

## Scope

Allowed:

- Documentation
- Read-only smoke script
- Secret-safe systemd timer inspection
- Secret-safe controller environment flag inspection
- Read-only worker registry inspection
- Read-only scheduler preview
- Read-only worker event inspection
- Compile validation

Blocked:

- CT101 modification
- Persistent lane worker activation
- Router rollout
- Warmup execution
- Model generate/chat calls
- Model unloading
- Authentication weakening
- Runtime service mutation
- Power automation changes
- Raw controller unit dumps containing secrets

## Starting Checkpoint

- HEAD: 1b6b13d
- Tag: controller-phase-14i-b-persistent-lane-worker-blocker-reentry-2026-06-15
- Phase 14I-A baseline smoke: passed
- Phase 14I-B blocker smoke: passed
- Repo status: clean
- Compile: passed

## Timer Findings

The inspection found these active timers:

- edge-queue-power-auto-tick.timer
- edge-queue-remediation-tick.timer

The power auto timer executes a bounded flock-protected request:

- POST http://127.0.0.1:7070/power/auto/tick
- connect timeout: 2 seconds
- max time: 10 seconds
- lock: /tmp/edge-queue-power-auto-tick.lock

The remediation timer executes a bounded flock-protected request:

- POST http://127.0.0.1:7070/workers/remediation/tick
- connect timeout: 2 seconds
- max time: 20 seconds
- lock: /tmp/edge-queue-remediation-tick.lock

## Runtime Flag Findings

The inspection found these worker-start-relevant flags:

- EDGE_POWER_AUTO_START_WORKERS=1
- EDGE_POWER_EXECUTE_START_WORKERS=1
- EDGE_TICK_AUTO_READY_WORKER=1
- EDGE_TICK_USE_DIRECT_OLLAMA=1

These flags are warnings before any worker activation phase.

## Current Worker State

The inspection reconfirmed:

- Worker registry total: 0
- Available workers: 0
- Worker list: empty
- Queued jobs: 1
- Queued job observed: job_id 23
- Requested model observed: gemma4:e4b
- Selected worker: null
- Candidate workers: none

## Runtime Path Interpretation

The legacy `/tick` route is guarded by a compatibility shim and returns before direct forwarding when the shim is active.

The remediation route defaults to dry_run=true when no payload is supplied.

Current remediation is not starting workers because the registry is empty.

The power-auto timer is active, but the observed environment includes EDGE_POWER_AUTO_TICK_FULL=0, so full power-auto execution should remain quarantined unless the environment changes.

## Decision

Do not activate workers yet.

Before any future worker activation, the project needs a separate controlled plan that accounts for:

1. Existing active power-auto and remediation timers.
2. Worker registry being empty.
3. Queued job 23 having no selected worker.
4. Worker-start-capable flags being present.
5. CT101 remaining protected.
6. Router rollout remaining parked.
7. Warmup execution remaining disabled.

## Definition of Done

Phase 14I-C is complete when:

- This report exists.
- The read-only smoke script exists.
- The smoke script is executable.
- The smoke script avoids raw controller unit dumps.
- The smoke script does not call mutating HTTP methods.
- The smoke script does not start/stop/restart/enable/disable services.
- The smoke script does not call model generate/chat endpoints.
- Compile passes.
- Smoke passes.
- Commit, tag, and push complete.
