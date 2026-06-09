# Stage 5G-30 — Final queued-chat cutover readiness report

## Goal

Summarize and verify that the live browser queued-chat path is ready for controlled cutover decisions.

## Proven path

The completed path is:

Browser queued submit → laptop wrapper bridge → laptop controller queue → managed CT101 worker → Ollama → completed laptop job → browser-visible assistant reply.

## Final proven milestones

- Stage 5G-27 proved a live browser queued chat completed through the managed CT101 worker.
- Stage 5G-28 proved runtime invariants required for queued chat.
- Stage 5G-29 proved those runtime invariants survive controlled restarts.

## Current runtime requirements

The working runtime requires:

- laptop controller listening on `0.0.0.0:7070`
- wrapper listening on `127.0.0.1:8787`
- wrapper runtime env has `WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED=1`
- wrapper runtime env has `EDGE_CONTROLLER_URL=http://127.0.0.1:7070`
- controller runtime env has `LAPTOP_QUEUE_INTERNAL_TOKEN`
- CT101 worker token file has `LAPTOP_QUEUE_INTERNAL_TOKEN`
- CT101 worker base URL points to the laptop Tailscale URL on port 7070
- CT101 managed worker service is active
- wrapper system status reports `ct101-laptop-queue-worker` online

## Current safety posture

Queued chat is proven through the live browser path.

The wrapper app.js queued submit remains guarded.

Queued chat is not globally enabled by wrapper `AI_PLATFORM_QUEUED_CHAT_ENABLED`.

The managed CT101 worker concurrency remains one job per bounded run.

The worker exposes safe health/status only, not secrets, prompts, raw environment values, or user message contents.

## Known limitation

The active browser queued mode still depends on the CT101 ChatPage queued mode/localStorage behavior.

A separate product decision is still needed before making queued chat default-on for every user.

## Cutover options

### Option A — Keep current controlled mode

Keep queued chat available only when the CT101 ChatPage queued mode is enabled.

This is safest and matches the current tested runtime.

### Option B — Make queued chat default-on for admin/test users

Enable queued chat automatically for selected users or admin sessions.

This should be done only after adding an admin/user flag check.

### Option C — Make queued chat default-on globally

This should wait until more multi-user, timeout, cancellation, and worker-capacity protections are added.

## Recommended next step

Keep current controlled queued mode and move to the next feature only after creating a small operational runbook for:

- restart controller
- restart wrapper
- restart CT101 worker
- verify queued chat health
- pause/resume worker
- diagnose queue failures
