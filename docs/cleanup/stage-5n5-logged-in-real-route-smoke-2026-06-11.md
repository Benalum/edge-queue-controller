# Stage 5N-5 Logged-In Real Route Smoke — 2026-06-11

## Result

The logged-in real-route smoke passed for the user-facing recovery path.

## Checkpoint before smoke

- Commit: `3e82276`
- Tag: `controller-stage-5n4-post-recovery-user-facing-smoke-2026-06-11`

## Confirmed working

The wrapper login route worked with a real active account:

- `POST /api/auth/login`
- Result: `200`
- Session token returned.

The authenticated account route worked:

- `GET /api/me`
- Result: `200`
- Returned active user profile with admin/pro account details.

The Study routes worked:

- `GET /api/study/decks`
- Result: `200`
- Returned the recovered math deck.

- `GET /api/study/progress`
- Result: `200`
- Returned deck progress and recent reviews.

The Companion context route worked:

- `GET /api/companion/context`
- Result: `200`
- Returned study context.
- Calendar context reported `calendar_not_enabled_yet`, which is expected for the current controller route set.

The queued Companion route worked end-to-end:

- `POST /api/chat/queued`
- Result: `200`
- Created job: `s5f18-job-07ab0e68fdf5293d`

Polling confirmed:

- `queued`
- `running`
- `complete`

The completed job returned:

- Model: `gemma4:e4b`
- Worker: `ct101-stage5g21-managed-browser`
- Reply: `stage 5n5 ok`

## Safety state

All tick timers remained stopped during and after the smoke:

- `edge-queue-power-auto-tick.timer`
- `edge-queue-power-idle-tick.timer`
- `edge-queue-remediation-tick.timer`
- `edge-queue-scheduler-tick.timer`

This matches the Stage 5N-3 quarantine state.

## Known smoke-script-only issues

The helper script attempted to read `is_admin` directly from the local SQLite `app_users` table.

That column does not exist in the local auth table, so the user-list helper produced:

- `sqlite3.OperationalError: no such column: is_admin`

This did not affect login or authenticated route behavior. `/api/me` still returned enriched admin/account fields correctly.

The helper script also attempted to read `app_jobs` from `edge_queue.sqlite3`.

That table was not present there:

- `ERROR: app_jobs table not found`

This did not affect queued chat. The live queued route itself created, ran, and completed the queued job successfully.

## Conclusion

Stage 5N-5 confirms the recovered logged-in wrapper flow is working for:

- auth
- account profile
- study decks
- study progress
- companion context
- queued Companion chat

The remaining follow-up is to clean up the smoke helper so it dynamically handles local SQLite columns and reads queued job proof from the correct job store.
