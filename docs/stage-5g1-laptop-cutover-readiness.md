# Stage 5G-1 — Laptop cutover readiness

## Goal

Move toward laptop-hosted website/control-plane cutover with fewer, larger practical steps.

## Target

- Laptop owns wrapper/frontend entry.
- Laptop owns controller/control-plane path.
- Laptop owns laptop Postgres path.
- CT101/PVESO remains the bounded Ollama/model worker for now.
- Queued chat remains disabled by default.

## This stage

This stage fixes the wrapper syntax blocker, adds cutover readiness checks, and adds a real Postgres restore drill.

## Safety rules

- Do not enable queued chat by default.
- Do not remove legacy submit.
- Do not send user_id, authenticated_user_id, or X-Synthetic-User-Id from frontend app.js.
- Do not create duplicate queued jobs, placeholders, polling loops, or final assistant messages.
- Do not commit full lifecycle wiring unless CT101/PVESO verification passes.

## Remaining cutover blockers

1. Prove restore, not just backup.
2. Confirm all routes/tabs are served by laptop wrapper or intentionally proxied.
3. Keep CT101 as worker until laptop hosting is stable.
4. Wire queued chat behind flags only.
5. Prove flag-off legacy submit remains unchanged.
6. Prove flag-on browser to laptop to queue to worker to assistant response.
7. Prepare Cloudflare/public route cutover.
8. Keep rollback simple.

## Rollback

Use git reset to return to the previous checkpoint and delete the Stage 5G-1 tag if created.
