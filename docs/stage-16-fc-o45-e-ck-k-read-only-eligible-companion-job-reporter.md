# Stage 16 FC-O45-E-CK-K — Read-Only Eligible Companion Job Reporter

Date: 2026-06-26

## Scope

Repo ops/docs/smoke only.

No frontend patch. No frontend deploy. No public /var/www mutation. No backend deploy. No CT203 runtime patch. No systemd install. No service start/stop/restart. No service enable. No timer install/enable/start. No DB write. No job mutation. No result insert. No model/helper/Ollama call. No scheduler/timer/persistent-worker activation. No CT/VM restart. No secret values printed.

## Reporter source

    ops/workers/list-eligible-deterministic-companion-jobs.sh

## Purpose

The reporter gives a read-only status view of jobs eligible for the deterministic Companion selector/manual-wrapper lane.

It is intended as a safer operator preflight before invoking the selector wrapper.

## Usage

List eligible queued Companion jobs:

    list-eligible-deterministic-companion-jobs.sh

Filter by exact expected marker:

    list-eligible-deterministic-companion-jobs.sh --expected-marker <marker>

JSON output:

    list-eligible-deterministic-companion-jobs.sh --json

## Eligibility rules

A job is eligible when all of these are true:

    job_type=companion.chat
    status=queued
    attempts=0
    result_rows=0

When `--expected-marker` is provided, the prompt must also contain that exact marker.

## Safety properties

The reporter opens SQLite in read-only mode.

It does not insert jobs.

It does not mutate jobs.

It does not insert results.

It does not start services.

It does not enable services.

It does not install or start timers.

It does not poll the queue.

It does not call the selector wrapper.

It does not call the manual wrapper.

It does not call the deterministic helper.

It does not call PVESO, Ollama, or any model endpoint.

## Output

Text output includes:

    eligible_companion_jobs_read_only=yes
    eligible_companion_jobs_marker=<marker-or-none>
    eligible_companion_jobs_total=<count>
    eligible_companion_jobs_returned=<count>
    eligible_job id=<id> ...
    eligible_companion_jobs_report_done=yes

## Next recommendation

Install this reporter on CT203, then run a read-only live status check before any further runtime selector proof.
