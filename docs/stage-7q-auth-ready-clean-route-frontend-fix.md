# Stage 7Q Auth Ready Clean Route Frontend Fix

Stage 7Q fixes a frontend login-after-auth rerender bug.

Observed browser console error:

- `ReferenceError: cleanRoute is not defined`
- The error occurred inside `rerenderCurrentRouteAfterAuthReady()`.
- Login still stored `edgeStudyToken`, but the post-login page rerender could be skipped.

Root cause:

`rerenderCurrentRouteAfterAuthReady()` called `cleanRoute(...)`, but the available `cleanRoute` helpers were scoped inside later route-state helper blocks and were not visible to the auth-ready helper.

Fix:

- Add a small auth-specific route normalizer named `normalizeWrapperAuthRoute(...)`.
- Use it inside the auth-ready rerender helper.
- Avoid changing later route-state helpers.
- Bump the wrapper `app.js` cache version so the browser loads the patched frontend.

Safety boundaries:

- No auth token values are logged.
- No backend auth behavior is changed.
- No router runtime wiring is changed.
- No Universal Intent Router dispatch is enabled.
- No Study, Companion, Profile, Calendar, Support, or Credits backend behavior is changed.
- Power automation remains paused until separately resumed.

Validation:

- Static smoke verifies `rerenderCurrentRouteAfterAuthReady()` no longer calls undefined `cleanRoute`.
- Static smoke verifies the auth-specific normalizer exists.
- Static smoke verifies the wrapper index cache-busts to the Stage 7Q app version.
