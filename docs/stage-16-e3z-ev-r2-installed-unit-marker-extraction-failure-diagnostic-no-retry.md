# Stage 16 E3Z-EV-R2 installed-unit marker extraction failure diagnostic no-retry

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 E3Z-EU.
- Base HEAD/origin/main: `5ffb140`.
- Base tag: `controller-stage-16-e3z-eu-installed-unit-fresh-retry-contract-no-apply-2026-06-22`.

## Why this checkpoint exists

E3Z-EV attempted a fresh-job installed-unit one-tick runtime retry using job 54.

The installed timer path fired and started the matching installed service instance, but the worker failed with:

    REFUSE_EXPECTED_MARKER_NOT_FOUND

Because job 54 was claimed and attempted, job 54 must not be reset, deleted, reused, manually completed, or retried silently.

## Timeout reconciliation

A first attempt to write this diagnostic checkpoint timed out in PPB and reset the tmux session.

The follow-up read-only timeout reconciliation confirmed:

- repo HEAD/origin/main remained `5ffb140`,
- repo status remained clean,
- no EV-R2 diagnostic files were present,
- no EV-R2 commit or tag was created,
- CT203 remained consistent,
- CT101 remained default-off.

## E3Z-EV failure evidence

- Fresh job id: `54`.
- Marker: `E3Z-EV-OK`.
- Prompt: `Return exactly E3Z-EV-OK`.
- Expected response sha256: `68350735e9c90900032dad7d435f3d8e7057e6cb907aafff4ecd40b0f32338ae`.
- Timer instance: `edge-ct101-exact-job-worker@54.timer`.
- Service instance: `edge-ct101-exact-job-worker@54.service`.
- Service result: `exit-code`.
- Service exec status: `1`.
- Worker refusal: `REFUSE_EXPECTED_MARKER_NOT_FOUND`.

Read-only CT203 evidence after timeout reconciliation:

    quick_check_after_timeout=ok
    jobs_37_52_seen_after_timeout=16
    jobs_37_52_completed_with_one_result_after_timeout=16
    job53_status_after_timeout=running
    job53_attempts_after_timeout=1
    job53_result_rows_after_timeout=0
    job54_status_after_timeout=running
    job54_attempts_after_timeout=1
    job54_result_rows_after_timeout=0
    max_job_id_after_timeout=54

Read-only CT101 evidence after timeout reconciliation:

    timer54_active=inactive
    timer54_enabled=disabled
    timer54_unit_file_state=disabled
    service54_active=failed
    service54_enabled=static
    service54_unit_file_state=static
    service54_result=exit-code
    service54_exec_status=1
    edge_service_active=inactive
    edge_service_enabled=disabled
    active_exact_job_units=0
    active_exact_job_timers=0
    service_template_enabled=static
    timer_template_enabled=disabled
    ollama_container_status=running health=healthy restart_count=0
    ct101_default_off_after_timeout=true

## Diagnosis

E3Z-EV changed the prompt to:

    Return exactly E3Z-EV-OK

The worker refused with `REFUSE_EXPECTED_MARKER_NOT_FOUND`, which indicates the worker did not find the expected marker in the job payload before exact response comparison.

This is different from E3Z-ET job 53, which failed with:

    REFUSE_WORKER_EXACT_MARKER_MISMATCH

The likely cause is that the shortened prompt did not match the worker's expected-marker extraction rule. The prior successful proofs used the longer extraction-compatible prompt shape:

    Return exactly this text and nothing else: <MARKER>

## Preservation rule

Both failed installed-unit jobs are now evidence:

- job 53: `running`, attempts `1`, result rows `0`,
- job 54: `running`, attempts `1`, result rows `0`.

Neither job may be reset, deleted, reused, manually completed, or retried silently.

Future runtime retries must use a fresh job id only and must not include job 53 or job 54 in `EDGE_ALLOWED_JOB_IDS`.

## Known-good baseline

Jobs 37 through 52 remain the known-good completed proof window.

Any future runtime retry must verify:

- jobs 37 through 52 completed with exactly one result row each,
- job 53 preserved as running, attempts 1, result rows 0,
- job 54 preserved as running, attempts 1, result rows 0,
- max job id is 54 before inserting any new fresh job.

## Installed-unit baseline

The installed CT101 unit files remain unchanged from E3Z-ES-R2:

- service template: `edge-ct101-exact-job-worker@.service`,
- service sha256: `16f76e1414def112bbd73f8f1edd0fda23d8a9d796124c44bb982301e9deac8e`,
- timer template: `edge-ct101-exact-job-worker@.timer`,
- timer sha256: `7bf2492ad123b2eb4950f80ec7b0bc412728f05099d18f362f446e4d2e235390`,
- worker sha256: `69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f`,
- profile sha256: `329118c8916917e538200ee5c0e6d2b4c2a214adf00cf075b810ee23d0baed1d`.

## Next recommended stage

Recommended next stage: `Stage 16 E3Z-EW`.

Purpose: create a no-apply contract for a second fresh installed-unit retry using job 55, preserving jobs 53 and 54 as evidence, restoring the known marker-extraction-compatible prompt shape, and using a short marker inside that compatible shape.

Recommended future marker:

    E3Z-EW-OK

Recommended future prompt:

    Return exactly this text and nothing else: E3Z-EW-OK

E3Z-EW should be no-apply only. A later runtime stage requires explicit approval because it would insert a fresh job, start one installed timer instance, and call Ollama once.
