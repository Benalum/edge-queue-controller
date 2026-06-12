# Stage 7X-6 Normalized Wrapper Queue Power Service Records

Stage 7X-6 fills in the remaining `unknown` platform status cards.

## Problem

The System UI normalized platform block expected service IDs:

- `frontend-wrapper`
- `queue`
- `power-automation`

But `/system/status` only included:

- `study-api`
- `ct101-laptop-queue-worker`

Because the service records were missing, the normalized UI showed:

- Frontend Wrapper: `unknown`
- Queue: `unknown`
- Power Automation: `unknown`

## Fix

The controller now adds public-safe service records for:

- `frontend-wrapper`
- `queue`
- `power-automation`

## Expected states

When current services are healthy:

- Frontend Wrapper: `online`
- Queue: `online`
- Power Automation: `degraded`

Power Automation is `degraded` because the modern power/remediation timers are active, but the legacy `/tick` scheduler timer is intentionally disabled until the controlled restart.

## Safety boundary

This stage does not restart the controller.

This stage does not call `/tick`.

This stage does not re-enable the legacy scheduler timer.

This stage does not change router dispatch behavior.

This stage only changes the source for future `/system/status` normalized platform records after a controlled controller restart.
