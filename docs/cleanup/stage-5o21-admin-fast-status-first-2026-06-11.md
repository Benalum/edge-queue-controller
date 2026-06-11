# Stage 5O-21 Admin Fast Status First — 2026-06-11

## Result

Admin initial status loading now uses the fast wrapper public status endpoint.

## Why

`/api/system/status` can take several seconds when Proxmox/SSH checks time out. That is acceptable for a deep infrastructure check, but not for initial Admin page rendering.

## Change

Admin initial data load now calls:

- `/system/public-status`

instead of:

- `/system/status`

## Future

Add an explicit "Refresh infrastructure" or "Deep check" button for full `/system/status` later.
