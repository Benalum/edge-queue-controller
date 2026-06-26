# Stage 16 FC-O45-E-CJ-W-R3 — Disabled One-Shot Worker Install

Date: 2026-06-26

## Summary

CJ-W-R3 installed the reusable deterministic Companion helper and the disabled one-shot systemd template on CT203.

Nothing was started or enabled.

## Installed helper

Runtime path:

    /opt/edge-queue-controller/ops/workers/run-deterministic-companion-exact-once.py

Expected and verified SHA:

    7a72ae2d644f04dbcbf4c580722525fb32f19da992c557bc99207a4eefa28419

## Installed systemd template

Runtime path:

    /etc/systemd/system/edge-deterministic-companion-worker-once@.service

Expected and verified SHA:

    265283d77df5ad9ff1bc5a151ee7faa882b754f26cc1fe41533b0c18f6737f7a

## Systemd state

`systemctl daemon-reload` completed.

Template enabled state:

    static

Example instance:

    edge-deterministic-companion-worker-once@999999.service

Example instance active state:

    inactive

Example instance enabled state:

    static

This is expected for a template with no `WantedBy`.

## Backup path

    /opt/edge-queue-controller/backups/stage-16-fc-o45-e-cj-w-r3-install-disabled-one-shot-worker-20260626T043409Z

No previous runtime helper or unit existed before install.

## Controller state

CT203 live backend SHA remained:

    1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2

The controller remained active.

## Guardrails kept

No frontend patch, no frontend deploy, no public /var/www mutation, no backend deploy, no CT203 backend runtime patch, no DB write, no schema migration, no job mutation, no result insert, no service start, no service stop, no service restart, no service enable, no timer install, no timer enable/start, no model/helper/Ollama call, no scheduler/timer/persistent-worker activation, no CT/VM restart, no package install, and no secret values printed.

## Public smoke

Public GET requests returned HTTP 200 for:

    /api/system/status
    /api/companion/voice/status

## Next recommendation

Run one bounded systemd start proof for one fresh exact-answer Companion job by creating the required per-job runtime env file and starting only that one service instance.
