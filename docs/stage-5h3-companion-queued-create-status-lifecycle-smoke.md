# Stage 5H-3 — Companion Queued Create/Status Lifecycle Smoke

## Purpose

Stage 5H-3 proves the companion-mode queued create/status lifecycle can pass through the existing wrapper/controller queue bridge.

This stage adds a smoke test only.

It does not enable companion queued browser submit globally.

It does not make queued chat globally default-on.

It does not increase worker concurrency.

It does not expose secrets, raw tokens, prompts, raw environment values, or user message contents in system status.

It does not accept client-provided `user_id`.

## What the smoke proves

The smoke creates a temporary local session and calls the same wrapper bridge route shape used by CT101:

- `POST /api/backend/chats/{chat_id}/messages/queued`
- `GET /api/backend/chats/{chat_id}/messages/jobs/{job_id}`

The request includes the non-identity mode hint:

- `mode = companion`

The wrapper forwards only allowed mode values to the laptop controller.

The controller mirrors trusted CT101 ownership and preserves:

- `app_chats.mode = companion`
- `app_jobs.payload_json.mode = companion`

When the worker completes the job, the wrapper status response must expose:

- `status = complete`
- `assistant_message`
- `assistant_message.role = assistant`
- non-empty assistant content

## Cleanup

The smoke uses a temporary stage-specific user, session, chat, messages, and job.

On successful terminal completion, it deletes its temporary rows.

If the job does not reach terminal state, the smoke leaves rows in place for inspection rather than deleting a job that the managed worker may still be processing.

## Safety

The smoke never prints the raw session token.

The smoke never prints the test prompt content.

The smoke never prints the assistant reply content.

The smoke does not send or accept client-provided `user_id`.

