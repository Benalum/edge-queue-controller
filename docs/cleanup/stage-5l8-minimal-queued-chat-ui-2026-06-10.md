# Stage 5L-8 Minimal Queued Chat UI — 2026-06-10

## Result

Added and hooked a minimal wrapper-native Chat UI at /chat.

The /chat page now has:

- message textarea
- Send queued message button
- Clear button
- conversation render area
- queued job status text

## Behavior

The visible Chat UI now POSTs to /api/chat/queued, polls /api/chat/queued/{job_id}, and renders the completed assistant reply.

## Known-good backend foundation

- Direct browser queued-chat API smoke already passed.
- CT101 worker is active and enabled.
- Worker processed real queued job s5f18-job-b6fdf8bef288125e with reply: queue smoke ok.

## Browser smoke

The visible /chat UI was tested with: Reply with exactly: visible chat ui ok.

Expected result: assistant reply renders visible chat ui ok.

## Boundary

This stage wires normal Chat only.
Companion mode remains separate/compatibility-only for now.
