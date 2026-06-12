# Stage 5P-7A Controller Restart Helper

Adds a safe local development helper for restarting the controller on port `7070`.

Purpose:

- avoid repeated manual restart blocks
- avoid duplicate `address already in use` bind attempts
- keep future smokes cleaner
- keep the terminal open by avoiding `exit`

Helper:

- `ops/dev/restart-controller-7070.sh`

Behavior:

- finds the current listener on `:7070`
- stops it
- waits for the port to become free
- starts `uvicorn edge_controller:app` from the repo virtualenv when available
- writes logs to `logs/controller-7070-dev.log`
- verifies the Study session status endpoint responds with `401` or `200`

This stage does not change runtime app behavior.
