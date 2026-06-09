# Stage 5G-29 — Runtime restart persistence smoke

## Goal

Verify the live queued-chat runtime survives controlled restarts of the laptop controller, wrapper, and CT101 managed worker service.

## Why

Stage 5G-27 proved live browser queued chat works.

Stage 5G-28 proved the runtime invariants are correct.

Stage 5G-29 proves those invariants survive a controlled restart sequence.

## What this smoke verifies

The smoke restarts:

- laptop controller on port 7070
- laptop wrapper on port 8787
- CT101 managed laptop queue worker service

Then it verifies:

- controller is listening on 0.0.0.0:7070
- wrapper is listening on 127.0.0.1:8787
- wrapper bridge env is still enabled
- controller token env is still present
- CT101 worker env and token are still valid
- CT101 can reach the laptop controller over Tailscale
- managed CT101 worker is active
- wrapper system status reports ct101-laptop-queue-worker online

## Safety

This stage does not change application code.

This stage does not rotate secrets.

This stage does not increase worker concurrency.

This stage does not send a queued chat message.

This stage only restarts existing runtime processes and verifies health.
