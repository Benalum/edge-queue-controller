# Stage 16 FC-O45-E-CK-R — Guarded Mock Companion Backlog Cleanup Plan

Date: 2026-06-26

## Summary

CK-R adds a source-only read-only dry-run tool and cleanup plan for the old `mock/no-model` queued `companion.chat` backlog identified in CK-P.

This checkpoint does not touch CT203, does not read the live DB, and does not mutate any queue data.

## Tool

    ops/db/plan-companion-mock-backlog-cleanup-read-only.py

## Purpose

The tool identifies the exact candidate set for a later cleanup phase, while opening SQLite in read-only mode.

Candidate criteria:

    job_type=companion.chat
    status=queued
    attempts=0
    result_rows=0
    requested_model=mock/no-model

## Why this exists

CK-P found 440 eligible queued `companion.chat` rows. All 440 used `requested_model=mock/no-model`.

The backlog is old test traffic:

    437 say_hello_one_sentence prompts
    2 other prompts
    1 stage15e_mock_validation prompt

Before any broader dispatch, timer, or automation path is enabled, those old mock rows need either cleanup or an exclusion policy so they cannot be accidentally executed.

## Safety properties

The dry-run tool:

- opens SQLite using `mode=ro`
- reports candidate count
- reports min/max candidate ids
- reports a SHA-256 over the candidate id list
- reports day and prompt-bucket counts
- reports oldest/newest samples
- supports text and JSON output
- supports `--expected-count`
- refuses if the expected count does not match
- does not update jobs
- does not insert job results
- does not start services
- does not call the selector wrapper
- does not call the manual wrapper
- does not call the deterministic helper
- does not call PVESO/Ollama/model endpoints

## Future cleanup policy

A later cleanup phase must be separately approved.

Before any DB mutation, the next runtime step should:

1. Run this dry-run tool on CT203 against the live DB.
2. Confirm the candidate count is still 440 or explicitly explain any drift.
3. Record the candidate id SHA-256.
4. Read the live jobs status taxonomy.
5. Choose the safest non-executable status or exclusion mechanism.
6. Create a DB backup.
7. Mutate only the exact candidate set confirmed by the dry-run.
8. Verify before/after counts.
9. Verify no service, timer, worker, model, or helper path ran.

## Recommended direction

Prefer an exclusion policy in worker/selector eligibility before destructive cleanup.

The selector/manual wrapper path already requires an explicit marker. Future automatic or broader dispatch must also exclude `requested_model=mock/no-model` and/or require an approved marker family.

## Guardrails kept in CK-R

No frontend patch, no frontend deploy, no public /var/www mutation, no backend deploy, no CT203 runtime patch, no systemd install, no service start/stop/restart, no service enable, no timer install/enable/start, no DB write, no schema migration, no job mutation, no result insert, no model/helper/Ollama call, no selector/manual-wrapper/helper invocation, no scheduler/timer/persistent-worker activation, no CT/VM restart, and no secret values printed.

## Next recommendation

Run CK-S to install this dry-run tool on CT203 and execute it read-only against the live DB with `--expected-count 440`.
