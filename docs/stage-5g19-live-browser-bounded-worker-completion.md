# Stage 5G-19 — Live browser bounded worker completion

## Goal

Prove a real browser-created queued chat job can be completed by a bounded CT101 laptop-queue worker run.

## Why

Stage 5G-15 proved the browser sends queued messages.

Stage 5G-18 proved the default model alias is resolved and CT101 can complete real-user queued jobs.

This stage combines both paths:

browser queued submit -> laptop app_jobs row -> CT101 bounded worker -> complete job.

## What this proves

- The active browser /chat page creates a queued laptop job.
- The queued job stores the resolved model, not the literal `default` alias.
- CT101 bounded real-user worker claims that browser-created job.
- CT101 Ollama completes the job.
- Laptop app_jobs status becomes complete.
- result_json reply is written.
- No duplicate matching jobs are created for the exact prompt.

## Limitation

This stage does not enable persistent worker runtime.

The worker is still run manually/bounded from the terminal.

Stage 5G-20 should convert this into a safe persistent or supervised worker runtime.

## Safety

- Does not enable wrapper app.js queued submit.
- Does not send client-provided user_id.
- Does not modify CT101 docker-compose.
- Uses bounded worker settings:
  - max jobs per run = 1
  - max idle polls = 1
  - real-user jobs explicitly enabled
