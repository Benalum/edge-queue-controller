# Stage 5L-4I Queued Chat Real-User Smoke Fix — 2026-06-10

## Result

Real-user queued Chat smoke passed from the browser through /api/chat/queued.

Successful smoke job:

- job_id: s5f18-job-b6fdf8bef288125e
- requested_model: gemma4:e4b
- status: complete
- reply: queue smoke ok
- worker: ct101-stage5g21-managed-browser

## Source fix

Updated frontend/wrapper-ui/dev_server.py so direct browser calls to /api/chat/queued receive server-derived trusted identity headers.

The wrapper now resolves the edgeStudyToken cookie server-side through the controller session endpoint and forwards trusted X-Edge-* headers for direct queued-chat routes.

## Runtime config fix

Queued-chat controller flags were enabled through a reversible systemd drop-in:

- /etc/systemd/system/edge-queue-controller.service.d/185-queued-chat-real-user-smoke.conf

The controller also needed the same EDGE_TRUSTED_PROXY_SECRET as the wrapper:

- /etc/systemd/system/edge-queue-controller.service.d/186-trusted-wrapper-secret-for-queued-chat.conf

Do not commit or print the secret value. Runtime verification should compare presence, length, and hash only.

## Worker state

CT101 queue worker processed the real queued job successfully.

The worker service is active from manual start but remains disabled for permanent boot enablement.

Permanent enablement should wait for the next checkpoint.

## Remaining cleanup

- Decide whether to enable ai-platform-laptop-queue-worker.service permanently.
- Wire the Chat frontend submit path to queued-chat behavior if desired.
- Investigate the existing failed-count bucket separately; it was not changed by this stage.
