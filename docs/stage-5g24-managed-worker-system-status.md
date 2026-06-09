# Stage 5G-24 — Surface managed worker status in system status

## Goal

Expose the managed CT101 laptop queue worker in system status.

## What was added

The laptop controller `/system/status` response now includes a dedicated service item:

- id: ct101-laptop-queue-worker
- name: CT101 Laptop Queue Worker

The controller also includes the worker in the normalized platform block.

The wrapper `/api/system/status` exposes the worker through its normalized platform block, which is the safe UI-facing system summary path.

## Safe status fields

The controller service item exposes operational health only:

- state
- service_active
- paused
- preflight_ok
- worker_id
- worker_node_id
- model
- max_jobs_per_run
- real_user_jobs_enabled
- synthetic_only
- base_url_set
- ollama_url_set
- queue counts

No secrets, tokens, prompts, raw environment values, or user message contents are exposed.

## Verified state

The managed worker reports:

- state: online
- service_active: true
- preflight_ok: true
- paused: false
- model: gemma4:e4b
- max_jobs_per_run: 1

## Safety

This stage does not change worker behavior.

This stage does not increase worker concurrency.

This stage does not modify wrapper app.js queued submit.

This stage only surfaces safe status information.
