# Stage 5P-13 Controlled CT101 Auto-Start Live Test

Stage 5P-13 proves that the automatic power timer can restart CT101 without manual intervention.

## Goal

Prove that when CT101 is stopped while the website has active logged-in demand, the automatic power policy timer starts CT101 again.

## Preconditions

Stage 5P-12 was already completed:

- `edge-queue-power-auto-tick.timer` is active.
- `edge-queue-power-auto-tick.service` uses a bounded 45 second curl max time.
- `/power/auto/tick` runs with full execution enabled.
- Proxmox current inventory only includes CT101.
- Stale protected entries for deleted VMs/CTs were removed.

## Test performed

CT101 was intentionally stopped using Proxmox:

- Before stop: `status: running`
- After shutdown: `status: stopped`
- Final stopped status: `status: stopped`

The test then waited for the existing automatic timer to run.

## Result

CT101 auto-started successfully.

Observed sequence:

- Wait attempt 1: `status: stopped`
- Wait attempt 2: `status: stopped`
- Wait attempt 3: `status: stopped`
- Wait attempt 4: timer service was activating
- Wait attempt 5: `status: running`

The final platform status returned:

- Controller node: online
- Proxmox server `pveso`: online
- CT101: online, `status: running`
- Study API: online
- CT101 laptop queue worker: online

## Conclusion

The automatic CT101 start path works.

When logged-in web presence requires the core container, the scheduled power tick can recover CT101 without manual Wake-on-LAN or manual `pct start 101`.

This confirms the Stage 5P-12 timer/service fix was effective for container auto-start behavior.
