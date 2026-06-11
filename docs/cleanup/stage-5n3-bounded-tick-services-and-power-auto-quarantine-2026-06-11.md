# Stage 5N-3 Bounded Tick Services and Power Auto Quarantine — 2026-06-11

## Result

The tick services were changed from long-running or unbounded curl calls into bounded, non-overlapping systemd oneshots.

## Why

The old scheduler/remediation/idle/auto tick units could overlap or hang for too long. This contributed to the controller on port 7070 becoming unavailable during login and Companion queue testing.

## What changed

The remediation, scheduler, and power-idle tick services now use:

- `flock -n` lock files
- `curl --connect-timeout 2`
- `curl --max-time 20`
- `TimeoutStartSec=25`
- `RuntimeMaxSec=30`

The power-auto tick service is intentionally quarantined as a `/usr/bin/true` no-op because `/power/auto/tick` still blocks controller health when pveso / Proxmox inventory is unreachable.

## Current safe state

All tick timers remain stopped.

Power-auto timer should not be restarted until `/power/auto/tick` is made non-blocking or moved out of the controller request path. The service itself currently exits successfully without contacting the controller.

## Follow-up

Create a later stage to refactor `/power/auto/tick` so SSH / Proxmox checks are bounded internally and cannot block `/health`, login, Companion, Study, Calendar, or Chat.
