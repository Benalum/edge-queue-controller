# Stage 8U Router Dry-Run Evidence Review and No-Browser-Traffic Checkpoint

Generated: 2026-06-12

## Stage purpose

Stage 8U reviews the Stage 8T controlled live backend router dry-run activation evidence and records a safety checkpoint before any browser/frontend router traffic is considered.

Stage 8U is non-invasive.

It does not:

- Restart live services.
- Enable backend dry-run.
- Enable browser/frontend router traffic.
- Enable frontend router shadow-read.
- Add `/api/router/dry-run` to frontend code.
- Change `/tick`.
- Change queue behavior.
- Change power automation.

## Stage 8T evidence summary

Stage 8T proved:

- Backend dry-run was disabled before activation.
- Temporary backend dry-run activation succeeded.
- POST `/api/router/dry-run` returned HTTP 200 only during the controlled activation window.
- Dry-run response was valid JSON.
- `dispatch_performed` was represented in the response contract.
- Queue remained clean after the dry-run call.
- Rollback removed `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1`.
- POST `/api/router/dry-run` returned HTTP 404 again after rollback.
- Timers stayed in the expected state.
- Port 7076 was not listening.

## Current checkpoint decision

Decision: do not enable browser/frontend router traffic yet.

Reason:

- Backend dry-run has now been proven live and rollback-safe.
- The next risk boundary is browser/frontend traffic.
- Browser traffic should only be enabled after a separate plan/smoke stage defines:
  - exact user surfaces allowed,
  - exact sampling/feature flag behavior,
  - no-dispatch guarantees,
  - logging/evidence format,
  - rollback procedure,
  - and a clear manual go/no-go decision.

## Safety state to preserve

After Stage 8U:

- POST /api/router/dry-run remains HTTP 404.
- Live backend dry-run remains disabled.
- POST `/api/router/dry-run` remains HTTP 404.
- `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1` is absent from the live controller environment.
- Frontend app/stub contain no `/api/router/dry-run` string.
- `ROUTER_SHADOW_READ_ENABLED = false`.
- `ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false`.
- Queue remains clean.
- Modern timers remain active:
  - `edge-queue-power-auto-tick.timer`
  - `edge-queue-remediation-tick.timer`
- Legacy scheduler timer remains inactive/disabled:
  - `edge-queue-scheduler-tick.timer`
- Port 7076 remains closed.

## Next recommended stage

Stage 8V should prepare a frontend/browser shadow-read activation plan only.

Stage 8V should not enable browser traffic yet unless explicitly chosen.
