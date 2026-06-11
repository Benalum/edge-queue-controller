# Stage 5L-6 Chat UI Submit Path Audit — 2026-06-10

## Result

Audited whether the visible /chat page submit path uses the working queued-chat API.

## Known-good foundation

- Direct browser POST to /api/chat/queued works.
- CT101 queue worker is active and enabled.
- CT101 completed real queued job s5f18-job-b6fdf8bef288125e with reply: queue smoke ok.

## Browser finding

The fetch logger showed no fetch requests after attempting the visible Chat UI send path.

This means the current visible Chat UI is likely not wired to /api/chat/queued yet, or no active send handler is attached.

## Next decision

Wire the visible Chat form/input/button to POST /api/chat/queued, poll the returned job_id, and render the completed reply.
