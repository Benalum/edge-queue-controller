# Stage 5G-18 — Default model alias and bounded real-user completion

## Goal

Resolve the queued-chat `default` model alias from a single environment-controlled default model and prove CT101 can complete a real-user laptop queued job.

## Why

Browser-created queued jobs were storing `requested_model=default`.

The CT101 bounded Ollama poller treated `default` as a literal Ollama model name, which failed because CT101 currently has `gemma4:e4b`.

## Fix

Real-user queued job creation now treats:

- missing model
- empty model
- default

as a logical alias resolved through:

1. AI_PLATFORM_DEFAULT_CHAT_MODEL
2. EDGE_OLLAMA_DEFAULT_MODEL
3. LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK
4. gemma4:e4b fallback

## What this proves

- The laptop controller creates real-user queued jobs with the resolved model.
- `default` is not stored as the literal worker model.
- CT101 bounded real-user poller can claim the job.
- CT101 Ollama completes the job.
- Laptop app_jobs status becomes complete.
- result_json reply is written.

## Safety

- Does not enable persistent worker runtime.
- Does not change wrapper app.js queued submit.
- Does not send client-provided user_id.
- Still requires trusted CT101 edge identity headers.
