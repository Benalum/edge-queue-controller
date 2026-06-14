# Phase 14A Runtime Power-Auto Quarantine and Timer Non-Overlap

Phase 14A records the runtime repair after unpausing power automation exposed that /power/auto/tick could block the controller when the old full Proxmox/SSH-backed planner was enabled.

Required runtime state:

- EDGE_POWER_AUTO_PAUSED=0
- EDGE_POWER_AUTO_TICK_FULL=0

This keeps power automation unpaused while keeping the old full SSH-backed planner quarantined.

Required controller override:

- /etc/systemd/system/edge-queue-controller.service.d/zzz-power-auto-safe-runtime.conf

Required timer behavior:

- /usr/bin/flock -n /tmp/edge-queue-power-auto-tick.lock
- curl --connect-timeout 2 --max-time 10 -X POST http://127.0.0.1:7070/power/auto/tick
- TimeoutStartSec=15

Expected /power/auto/tick behavior:

- quarantined=true
- source=stage_5o2_power_auto_tick_nonblocking_default
- automation.full_power_auto_tick=false
- automation.paused=false
- actions[0].action=power_auto_tick_quarantined_nonblocking

Verified soak result: health stayed HTTP 200, system status stayed HTTP 200, pveso stayed online, CT101 stayed online, worker stayed online, queue stayed online, and timer output stayed quarantined nonblocking.

Safety contract: Phase 14A does not modify edge_controller.py, does not enable the full SSH-backed power planner, does not pause automation, does not change CT101 runtime code, does not change Study or Companion behavior, and does not call Ollama or enqueue model jobs.

Until the full planner is made overlap-safe and timeout-safe in code, EDGE_POWER_AUTO_TICK_FULL must remain 0.
