# Stage 5G-26 — Normalized managed worker detail

## Goal

Expose safe managed CT101 laptop queue worker details through the normalized platform status path used by the System page and System drawer.

## Why

Stage 5G-24 exposed the full worker service object from the controller.

Stage 5G-25 made the worker a first-class normalized platform item in the wrapper UI.

The wrapper `/api/system/status` already exposes the normalized worker item, but not the full controller service object in `services[]`.

## What changed

The controller now adds a safe `detail` field to the normalized `ct101-laptop-queue-worker` platform item.

The detail includes:

- service active state
- preflight state
- pause state
- model fallback
- max jobs per run
- queue counts for queued, running, and failed jobs

## Safety

This stage does not expose secrets, tokens, prompts, raw environment values, or user message contents.

This stage does not change worker behavior.

This stage does not change queue behavior.

This stage does not increase concurrency.

This stage uses the normalized UI path instead of changing wrapper `services[]`.
