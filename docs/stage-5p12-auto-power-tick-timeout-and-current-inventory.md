# Stage 5P-12 Auto Power Tick Timeout and Current Inventory

Stage 5P-12 restores automatic power tick execution after confirming the full tick path is now safe enough to run from systemd.

## Problem

The auto power timer was active, but the service failed repeatedly because it used an 8 second curl timeout:

- `curl -fsS -m 8 -X POST http://127.0.0.1:7070/power/auto/tick`

The full `/power/auto/tick` route can take longer than 8 seconds when it checks Proxmox, inventory, worker state, wake policy, and web presence.

This caused `edge-queue-power-auto-tick.service` to fail with curl exit code 28.

## Confirmed current infrastructure

Current Proxmox inventory only contains CT101:

- `101 llms`

There are no active QEMU VMs.

The old protected inventory entries were stale and were removed from the live controller environment.

## Current power inventory policy

Auto-managed:

- `101`
- `llms`
- `llms_ollama`

Protected:

- empty

This means CT101 is allowed to be managed by the power automation policy.

## Auto tick service policy

The timer remains every minute.

The service now uses:

- `TimeoutStartSec=50`
- `RuntimeMaxSec=55`
- curl connect timeout of 3 seconds
- curl max time of 45 seconds
- last tick JSON captured at `/var/log/edge-queue-controller/power-auto-tick-last.json`

## Expected result

When a logged-in user is active:

- the host should be required
- CT101 should be required
- worker stop should be skipped
- host shutdown should be skipped
- wake/start execution flags should be enabled
- the auto tick service should finish successfully instead of failing

## Verified behavior

The service finished with `status=0/SUCCESS`.

The timer remained active and waiting.

The latest tick showed:

- `execute_wake_enabled=true`
- `execute_wake_and_start_enabled=true`
- `auto_recover_running_worker_executed`
- `skip_worker_stop_due_to_queue_demand`
- `skip_host_shutdown_due_to_web_presence_or_boot_grace`
