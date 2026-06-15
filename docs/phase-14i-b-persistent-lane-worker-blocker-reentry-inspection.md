# Phase 14I-B - Persistent Lane Worker Blocker Re-entry Inspection

Status: inspection recorded

## Purpose

Phase 14I-B records the first blocker re-entry inspection after the New Chat read-only baseline rule was committed.

This phase does not enable persistent lane workers.

## Scope

Allowed:

- Documentation
- Read-only smoke script
- Read-only worker registry inspection
- Read-only scheduler preview
- Read-only worker event inspection
- Read-only environment flag summary with secret-safe filtering
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

## Starting Checkpoint

- HEAD: aa948cd
- Tag: controller-phase-14i-a-new-chat-baseline-repo-rule-2026-06-15
- Phase 14I-A baseline smoke: passed
- Repo status: clean
- Compile: passed

## Inspection Findings

The read-only inspection found:

- Worker registry total: 0
- Available workers: 0
- Worker list: empty
- Scheduler queued jobs: 1
- Queued job observed: job_id 23
- Requested model observed: gemma4:e4b
- Selected worker: null
- Candidate workers: none

This confirms the platform cannot safely process queued model work through registered workers yet.

## Current Blockers Confirmed

- persistent_lane_workers_not_active
- worker_registry_empty
- queued_job_without_selected_worker
- primary_worker_unfiltered remains unresolved from prior Source/history
- router_rollout_parked
- warmup_execution_disabled
- ct101_runtime_protected

## Runtime Warnings

The inspection also observed runtime environment flags related to direct/tick readiness behavior:

- EDGE_TICK_USE_DIRECT_OLLAMA=1
- EDGE_TICK_AUTO_READY_WORKER=1
- EDGE_POWER_AUTO_START_WORKERS=1
- EDGE_POWER_EXECUTE_START_WORKERS=1

These flags are warnings for future worker phases. They do not unlock persistent lane worker activation.

Before any future activation phase, inspect the exact timer/service execution paths using redacted, read-only commands.

## Secret Handling Finding

The inspection command printed raw systemd unit drop-ins. Some drop-ins can contain secrets.

Future inspection commands should avoid full raw systemd unit dumps unless redacted. Prefer filtered environment summaries and explicitly exclude credentials, tokens, passwords, and secrets.

## Decision

Do not enable workers yet.

The next safe work should be one of:

1. Secret-safe runtime path inspection for remediation/tick behavior.
2. Docs-only design for the next controlled worker re-entry gate.
3. Source update to mark Phase 14I-A complete and record Phase 14I-B blocker state.

## Definition of Done

Phase 14I-B is complete when:

- This report exists.
- The read-only smoke script exists.
- The smoke script is executable.
- The smoke script does not call model generate/chat.
- The smoke script does not use mutating HTTP methods.
- The smoke script does not run systemctl start/restart/enable/disable.
- The smoke script does not print full raw systemd unit drop-ins.
- Compile passes.
- Smoke passes.
- Commit, tag, and push complete.
