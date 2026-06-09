# Stage 5H-2 — Companion Queued Route Ownership

## Purpose

Stage 5H-2 makes the laptop queued-chat ownership path mode-aware for companion without enabling companion queued UI.

This is a runtime-code preparation stage.

It does not make queued chat globally default-on.

It does not increase worker concurrency.

It does not expose secrets, tokens, prompts, raw environment values, or user message contents in system status.

It does not accept client-provided `user_id`.

## What changed

Stage 5H-2 adds guarded mode propagation for the existing queued-chat bridge:

- wrapper can forward a non-identity `mode` / `chat_mode` value when it is exactly `chat` or `companion`
- controller queued-chat request model accepts optional `mode`
- trusted CT101 chat mirror preserves `mode = chat` or `mode = companion`
- real-user queued chat guard validates mode
- real-user queued chat creation stores `payload_json.mode`
- companion mode still uses the existing `ollama_chat` queue job type for this stage

## What did not change

- CT101 frontend companion queue is not enabled in this stage.
- The browser companion submit path is not flipped in this stage.
- Worker max jobs per run remains 1.
- Existing normal queued chat remains unchanged.
- Wrapper trusted identity checks remain required.
- Client-provided `user_id` remains refused.
- Stage 5G smokes must keep passing.

## Why this is needed

Stage 5H-1 found that companion mode was being lost before queue creation.

The wrapper bridge could already transform completed queued jobs into CT101-compatible `assistant_message` responses, but the controller mirror created every trusted CT101 chat as normal `chat` mode.

Stage 5H-2 fixes that ownership shape first, before changing any companion UI behavior.

## Expected next stage

Stage 5H-3 should add a companion queued create/status lifecycle smoke.

That smoke should prove:

1. a companion-mode queued request can be created
2. the job stores `payload_json.mode = companion`
3. the mirrored chat stores `mode = companion`
4. status polling still returns the same CT101-compatible final response shape
5. normal queued chat still passes existing Stage 5G smokes

