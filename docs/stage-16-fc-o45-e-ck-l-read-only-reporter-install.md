# Stage 16 FC-O45-E-CK-L — Read-Only Eligible Companion Reporter Install

Date: 2026-06-26

## Summary

CK-L installed the read-only eligible Companion job reporter on CT203.

The reporter was installed only. It was not run against the live DB during CK-L.

## Installed reporter

Runtime path:

    /opt/edge-queue-controller/ops/workers/list-eligible-deterministic-companion-jobs.sh

Verified SHA:

    81030f3544dde5dc7437318bbd857591d0c3b6518c8fe6a3dd923df1a000286d

No previous runtime reporter existed before install.

Backup directory:

    /opt/edge-queue-controller/backups/stage-16-fc-o45-e-ck-l-install-reporter-20260626T045802Z

## Existing runtime dependencies verified

CT203 live backend SHA:

    1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2

Runtime deterministic helper SHA:

    7a72ae2d644f04dbcbf4c580722525fb32f19da992c557bc99207a4eefa28419

Runtime systemd unit SHA:

    265283d77df5ad9ff1bc5a151ee7faa882b754f26cc1fe41533b0c18f6737f7a

Runtime manual wrapper SHA:

    481bbae24f683880bdbc67fffc8ae3605603aba84913613db7f5b2f7ace00595

Runtime selector SHA:

    1115a5c2e6759d75f9cbfe92b80b668659a91e86f58f6c5da68ee26532e52c41

## Systemd and worker posture

Template enabled state:

    static

Example instance active state:

    inactive

Scheduler one-shot timer:

    inactive

Scheduler one-shot service:

    inactive

No persistent, general, or deterministic worker process was active.

## Reporter behavior

The reporter lists eligible queued Companion jobs without starting anything.

Eligibility rules:

    job_type=companion.chat
    status=queued
    attempts=0
    result_rows=0

Optional marker filter:

    --expected-marker <marker>

Supported output:

    text
    json

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

## Guardrails kept

No frontend patch, no frontend deploy, no public /var/www mutation, no backend deploy, no CT203 backend runtime patch, no systemd install, no daemon-reload, no service start, no service stop, no service restart, no service enable, no timer install, no timer enable/start, no DB write, no schema migration, no job mutation, no result insert, no selector/manual-wrapper/helper invocation, no model/helper/Ollama call, no scheduler/timer/persistent-worker activation, no CT/VM restart, no package install, and no secret values printed.

## Public smoke

Public GET requests returned HTTP 200 for:

    /api/system/status
    /api/companion/voice/status

## Next recommendation

Run the reporter once against the live DB in read-only mode. Then record the live reporter output before doing any further selector/runtime proof.
