# Stage 5P-16 Full Host Wake Retest Proof

Stage 5P-16 proves the full logged-in web presence recovery path after the Stage 5P-15 host-first wake fix.

## Goal

Prove that when an admin user is actively logged into the website:

1. pveso can be powered off.
2. CT101 can be stopped.
3. The automatic power timer detects host/container demand.
4. The timer sends Wake-on-LAN before CT inventory is available.
5. pveso wakes.
6. CT101 starts.
7. The platform returns online.

## Preconditions

The admin presence precheck passed:

- `presence_ok=true`
- `active_authenticated=1`
- `active_admin=1`
- `desired_state.host_required=true`
- `desired_state.container_required=true`

The platform was online before shutdown:

- pveso: online, SSH reachable
- CT101: online, `status: running`
- Study API: online
- CT101 queue worker: online

## Test performed

The test intentionally:

1. Gracefully shut down CT101.
2. Powered off pveso.
3. Waited for pveso to become unreachable.
4. Waited for the automatic timer to recover the host and CT101.

## Key observed action

The expected Stage 5P-15 action was observed:

- `auto_wake_host_first_due_to_inventory_unavailable`
- `executed=true`

Reason:

`Host/container is required but Proxmox inventory is unavailable, so host Wake-on-LAN was attempted before CT start planning.`

## Recovery sequence

Observed recovery:

- pveso became offline/unreachable.
- The timer ran while pveso was offline.
- The host-first wake action executed.
- pveso became reachable.
- CT101 was initially still stopped after pveso returned.
- A later tick started CT101.
- CT101 returned to `status: running`.

## Final result

The test completed successfully:

- `host_first_action_seen=1`
- `host_online=1`
- `ct101_running=1`
- `PASS: Stage 5P-16 full host wake retest completed`

Final platform status:

- overall: online
- master laptop: online
- pveso: online, SSH reachable
- CT101: online, `status: running`
- Study API: online
- CT101 laptop queue worker: online

## Conclusion

The full logged-in admin presence power recovery path works.

The platform can now recover from a powered-off pveso host and stopped CT101 when logged-in website presence requires the system online.
