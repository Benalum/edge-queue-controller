# Stage 16 FC-O45-E-CK-B — Manual Deterministic Companion Wrapper Install

Date: 2026-06-26

## Summary

CK-B installed the manual deterministic Companion systemd wrapper on CT203.

The wrapper was installed only. It was not run.

## Installed wrapper

Runtime path:

    /opt/edge-queue-controller/ops/workers/run-deterministic-companion-systemd-once.sh

Verified SHA:

    481bbae24f683880bdbc67fffc8ae3605603aba84913613db7f5b2f7ace00595

No previous runtime wrapper existed before install.

Backup directory:

    /opt/edge-queue-controller/backups/stage-16-fc-o45-e-ck-b-install-manual-wrapper-20260626T044126Z

## Existing runtime dependencies verified

CT203 live backend SHA:

    1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2

Runtime deterministic helper SHA:

    7a72ae2d644f04dbcbf4c580722525fb32f19da992c557bc99207a4eefa28419

Runtime systemd unit SHA:

    265283d77df5ad9ff1bc5a151ee7faa882b754f26cc1fe41533b0c18f6737f7a

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

## Guardrails kept

No frontend patch, no frontend deploy, no public /var/www mutation, no backend deploy, no CT203 backend runtime patch, no systemd install, no daemon-reload, no service start, no service stop, no service restart, no service enable, no timer install, no timer enable/start, no DB write, no schema migration, no job mutation, no result insert, no model/helper/Ollama call, no scheduler/timer/persistent-worker activation, no CT/VM restart, no package install, and no secret values printed.

## Public smoke

Public GET requests returned HTTP 200 for:

    /api/system/status
    /api/companion/voice/status

## Next recommendation

Run one fresh exact-answer Companion job through the installed manual wrapper. The wrapper should create the per-job env file, start exactly one systemd instance, verify completion, and remove the env file.
