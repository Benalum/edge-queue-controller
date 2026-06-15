# Phase 14I-A - New Chat Read-Only Baseline Repository Rule

Status: implementation phase

## Purpose

Phase 14I-A adds repository-level documentation and a smoke script for the New Chat read-only system baseline check.

The goal is to make every future new chat begin by verifying the live system before any implementation work continues.

## Scope

Allowed:

- Documentation
- Smoke script
- Read-only repository inspection
- Read-only controller health checks
- Read-only scheduler preview
- Read-only worker registry inspection
- Read-only systemd summaries
- Read-only power environment summary
- Compile validation

Blocked:

- Runtime behavior changes
- CT101 modification
- Persistent lane worker activation
- Router rollout
- Warmup execution
- Model execution calls
- Model unloading
- Authentication weakening
- Power automation mutation

## Current Baseline Before This Phase

Expected starting checkpoint:

- HEAD: da63bc1
- Tag: controller-phase-14h-profile-preferences-complete-rollup-2026-06-14
- Origin/main: da63bc1
- Compile: python3 -m py_compile edge_controller.py passes

The new-chat baseline inspection confirmed the repository baseline matched Source before this phase began.

## Baseline Rule

Before a new chat chooses or implements the next task, it must run the read-only baseline smoke script added by this phase.

The baseline must inspect:

1. Repository status
2. HEAD, tag, branch, and origin/main
3. Python compile status
4. Smoke script availability
5. Controller health, when running
6. Scheduler preview, when available
7. Worker registry, when available
8. systemd edge/cloudflared service and timer summary
9. Power automation environment summary
10. Safety marker grep for warmup, router, lane, worker, authHeaders, and profile preferences

## Failure Classification

If a baseline check finds an issue, do not immediately patch feature code.

Classify the issue as one of:

- BLOCKER: must repair or document before continuing
- WARNING: safe to continue limited scoped work
- EXPECTED_OFFLINE: known offline runtime state
- OUT_OF_SCOPE: unrelated to current safe phase

## Worker Warning Boundary

A scheduler preview with queued jobs and zero available workers is not automatically a blocker for docs-only work.

It is a blocker for router rollout, model execution, persistent lane worker activation, and study/companion model behavior work.

## Definition of Done

Phase 14I-A is complete when:

- This document exists
- The smoke script exists
- The smoke script is executable
- The smoke script is read-only by default
- Compile baseline passes
- Phase smoke passes
- Git commit is created
- Git tag is created
- Main branch and tag are pushed
- No CT101 runtime modifications were made
- No workers were enabled
- No router rollout was enabled
- No warmup execution was started
