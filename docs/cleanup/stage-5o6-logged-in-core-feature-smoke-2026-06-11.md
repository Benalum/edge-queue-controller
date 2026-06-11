# Stage 5O-6 Logged-In Core Feature Smoke — 2026-06-11

## Result

Logged-in core feature smoke was run after Stage 5O-5.

## Scope

Checked the logged-in path for:

- Login
- Account identity
- Study decks
- Study progress
- Companion context
- Queued chat create/poll

## Calendar rule

No local calendar API or database was added. Calendar remains Google/Apple provider-only direction.

## Safety expectations

The following should remain true:

- `edge-queue-controller.service` active
- `edge-wrapper-ui.service` active
- scheduler/remediation timers enabled
- power-auto/power-idle timers stopped
- no new 500/502/504 errors
