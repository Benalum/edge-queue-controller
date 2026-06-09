# Stage 5G-25 — Managed worker System drawer detail

## Goal

Make the managed CT101 laptop queue worker appear as an explicit System page and System drawer platform item.

## What was changed

The wrapper UI now treats `ct101-laptop-queue-worker` as a first-class normalized platform item.

The UI detail text says:

- Managed CT101 worker processing queued chat jobs with guarded one-at-a-time execution.

## Why

Stage 5G-24 surfaced the worker through `/system/status`.

The wrapper normalized platform already receives:

- ct101-laptop-queue-worker
- state: online

Stage 5G-25 makes the UI schema and fallback detail text explicitly know about that worker.

## Safety

This stage is UI-only.

This stage does not change worker behavior.

This stage does not change queue behavior.

This stage does not increase concurrency.

This stage does not expose secrets, tokens, prompts, or raw environment values.
