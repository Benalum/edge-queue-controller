# Stage 7P Proxmox Inventory Nonblocking Runtime Guard

Stage 7P fixes a production responsiveness issue discovered during authenticated shadow comparison testing.

The authenticated comparison runner exposed that the controller could become unresponsive while Proxmox inventory was being queried.

Observed failure mode:

- A child SSH command queried Proxmox inventory with `pct list` and `qm list`.
- The SSH command ran from the async controller request path.
- While the SSH inventory command was active, `/health`, login, Study, Companion, and session routes could time out.
- Restarting the controller temporarily fixed responsiveness until the next inventory call.
- Pausing power automation with `EDGE_POWER_AUTO_PAUSED=1` prevented the blocking SSH child and restored fast responses.

Root cause:

`proxmox_inventory()` is an async route but ran blocking `subprocess.run()` directly in the event loop.

Fix:

- Keep the same Proxmox inventory behavior.
- Keep the same timeout.
- Keep the same response schema.
- Move the blocking SSH subprocess call into `asyncio.to_thread(...)`.
- This prevents the async event loop from being monopolized by the Proxmox SSH inventory command.

Safety boundaries:

- No router runtime wiring is enabled.
- No Universal Intent Router dispatch is enabled.
- No model calls are enabled.
- No Study or Companion behavior is intentionally changed.
- No secrets are stored.
- Power automation remains paused until explicitly resumed after verification.
- This stage only prevents Proxmox inventory SSH from blocking unrelated web/login routes.

Validation:

- Static smoke verifies `asyncio.to_thread(...)` is used inside the Proxmox inventory route.
- Static smoke verifies direct `result = subprocess.run(...)` is not used inside the Proxmox inventory route body.
- Runtime verification should confirm `/health` remains responsive while `/power/proxmox/inventory` is executing or timing out.

## Runtime Proof

Runtime verification was performed with power automation paused.

Observed result:

- `/power/proxmox/inventory` was started manually.
- The Proxmox SSH inventory subprocess remained active.
- Ten `/health` probes were made while inventory was running.
- Every `/health` probe returned HTTP 200 quickly.
- The inventory request timed out with HTTP 504 after its bounded timeout.
- Final `/health` returned HTTP 200 quickly.

Conclusion:

The Proxmox inventory SSH timeout no longer monopolizes the async controller event loop.

Follow-up:

The Proxmox SSH inventory path still needs separate investigation because the inventory command itself timed out, but this is now isolated from web/login responsiveness.
