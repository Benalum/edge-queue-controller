# Stage 7R Authenticated Runner Public API Key Header

Stage 7R updates the authenticated shadow comparison runner so it can call existing routes that require both user auth and the public API key.

Observed behavior:

- `/system/session/me` can validate the bearer token.
- Study and Companion existing routes also call `_require_public_api_key(...)`.
- `_require_public_api_key(...)` expects the `x-edge-api-key` request header.
- Without that header, existing route calls return `401 Unauthorized` even when bearer auth is valid.

Fix:

- The runner continues to support runtime-only bearer or cookie auth.
- The runner now also supports a runtime-only public API key:
  - `EDGE_AUTH_SHADOW_COMPARE_PUBLIC_API_KEY`
  - fallback: `EDGE_PUBLIC_API_KEY`
- When present, the runner sends `x-edge-api-key`.
- The runner does not print or store the key.
- The sanitized comparison artifact remains secret-free.

Safety boundaries:

- No router runtime wiring is enabled.
- No Universal Intent Router dispatch is enabled.
- No model calls are enabled by the router.
- No auth secrets are written to artifacts.
- Existing Study and Companion route behavior is not changed.
- Power automation remains paused until separately resumed.

Validation:

- Static smoke verifies the runner reads the runtime-only public API key env var.
- Static smoke verifies the runner sends `x-edge-api-key`.
- Static smoke verifies the artifact output path remains ignored by git.
