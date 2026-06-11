# Stage 5O-20 Admin Status Frontend Caller Fix — 2026-06-11

## Result

Frontend admin/system status caller was corrected to use the existing system status route.

## Why

The frontend was calling:

- `/system/admin-status`

Through the wrapper this became:

- `/api/system/admin-status`
- `/system/admin-status`

That controller route does not exist, causing a 404.

## Fix

Use the existing route instead:

- `/system/status`

No new backend surface area was added.

## Safety

This stage does not enable power-idle or full power-auto planning.
