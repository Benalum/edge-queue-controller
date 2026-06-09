# Stage 5H-5 — Companion HTML/Error Response Regression Smoke

## Purpose

Stage 5H-5 verifies that companion queued completion does not regress into raw HTML/error-style browser behavior.

This is a smoke-only stage.

It does not change runtime behavior.

It does not make queued chat globally default-on.

It does not increase worker concurrency.

It does not expose secrets, tokens, prompts, raw environment values, or user message contents in system status.

It does not accept client-provided `user_id`.

## What is verified

The smoke verifies:

- CT101 companion browser queued submit is enabled only through the existing queued-chat flag.
- CT101 `ChatPage.tsx` still uses the queued create route.
- CT101 `ChatPage.tsx` still uses the queued status route.
- CT101 `ChatPage.tsx` still renders final text from `assistant_message`.
- The old companion blocker `!isCompanion && useQueuedChat` is absent.
- The patched frontend file does not send client-provided `user_id`.
- The laptop wrapper still converts completed laptop queued jobs into CT101-compatible `assistant_message`.
- The wrapper still has HTML/error-response guard behavior so raw gateway HTML is not exposed as assistant text.

## Safety

The smoke does not print prompts, assistant reply content, secrets, tokens, or raw environment values.

## Expected result

Companion queued completion should return structured JSON and final companion text through `assistant_message`, not raw HTML/error-style content requiring a page refresh.
