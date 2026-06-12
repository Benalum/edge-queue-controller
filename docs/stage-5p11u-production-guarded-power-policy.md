# Stage 5P-11U Production Guarded Power Policy

Stage 5P-11U records the final production power policy after proving logged-in presence protection.

Goal when a logged-in user is active on alexhartel.com:

- pveso should be online or booting.
- CT101 should be running or starting.
- The worker registry should be recoverable.
- Worker stop should be blocked.
- Host shutdown should be blocked.

Goal when no logged-in users are active, no jobs are queued/running, and idle windows expire:

- Auto-managed worker containers may stop.
- pveso may shut down only through guarded inventory checks.

Final systemd override path:

/etc/systemd/system/edge-queue-controller.service.d/zz-production-guarded-power.conf

Expected enabled flags:

EDGE_POWER_AUTO_TICK_FULL=1
EDGE_POWER_AUTO_START_WORKERS=1
EDGE_POWER_EXECUTE_START_WORKERS=1
EDGE_POWER_EXECUTE_WAKE=1
EDGE_POWER_EXECUTE_WAKE_AND_START=1
WEB_POWER_POLICY_EXECUTE_WAKE=1
WEB_POWER_POLICY_EXECUTE_CONTAINERS=1
EDGE_POWER_AUTO_STOP_WORKERS=1
EDGE_POWER_EXECUTE_STOPS=1
EDGE_POWER_AUTO_SHUTDOWN_HOST=1
EDGE_POWER_EXECUTE_HOST_SHUTDOWN=1
WEB_POWER_POLICY_EXECUTE_SHUTDOWN=1
WEB_PRESENCE_ACTIVE_WINDOW_SECONDS=180
WEB_PRESENCE_ANON_WAKE_SECONDS=15
WEB_POWER_CONTAINER_IDLE_SECONDS=1800
WEB_POWER_HOST_IDLE_SECONDS=1800
WEB_POWER_MIN_HOST_ON_SECONDS=600
WEB_POWER_WAKE_DEBOUNCE_SECONDS=60

Proven behavior with logged-in admin presence active:

- has_start_demand becomes true.
- Reason is web_presence_container_required.
- active_authenticated is 1.
- host_required is true.
- container_required is true.
- Host shutdown is skipped due to active web presence.
- CT101 and the worker registry recover to available.
