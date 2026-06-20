# Stage 16-E2J — PVESO Model Runtime Readiness Plan No-Apply

Date: 2026-06-20

## Purpose

Define the safest next path for bringing model runtime capacity back into the AI Platform Control system after PVESO inventory access was restored.

This is a **no-apply** plan. It does not start containers, start/restart services, load models, call Ollama endpoints, register workers, dispatch scheduler lanes, or write the database.

## Current Baseline

Latest stable repo checkpoint before this plan:

- Stage 16-E2H: PVESO persistent firewall inventory path verified
- Stage 16-E2I: PVESO worker/model inventory read-only verified

Current known platform state:

- PVEW is the always-on Proxmox host for the live platform.
- VM200 is the public website edge.
- CT203 is the controller/API/queue authority.
- CT204 is stopped, backup-data-only, and private storage remains locked/unmounted.
- PVESO is reachable on demand and now has durable CT203 inventory access.
- CT101 `llms` exists on PVESO but remains stopped with `onboot=0`.
- No persistent model workers are active.
- No scheduler lane dispatch activation has occurred.
- No worker/model activation occurred in E2H or E2I.

## E2I Read-Only Findings

PVESO containers:

- CT101 `llms`: stopped
- CT201 `edge-data`: stopped
- CT202 `edge-controller`: stopped

CT101 `llms`:

- stopped
- onboot: 0
- cores: 20
- memory: about 31 GB
- Ubuntu
- unprivileged
- rootfs: local-lvm 100G
- bind mount:
  - host `/mnt/ollama-storage`
  - container `/mnt/ollama-models`

PVESO host runtime:

- Ollama binary present
- Ollama service enabled
- Ollama service observed as `activating`
- no Ollama tcp/11434 listener observed
- no NVIDIA GPU detected
- `nvidia-smi` absent
- model/storage paths present:
  - `/usr/share/ollama/.ollama/models` about 48G
  - `/mnt/ollama-storage`
  - `/var/lib/vz/ollama/models`

## Runtime Path Options

### Option A — Repair/use PVESO host-level Ollama

Pros:

- Avoids starting CT101.
- Ollama binary and model storage already exist on the host.
- May be fastest if service activation issue is simple.

Cons:

- Host service was observed as `activating`.
- No tcp/11434 listener was observed.
- Host-level runtime may mix platform host concerns with model runtime concerns.
- Needs separate diagnosis before any service restart or endpoint call.

Status: not selected yet.

### Option B — Start/use CT101 `llms`

Pros:

- CT101 appears purpose-built for model runtime.
- It has substantial CPU/RAM allocation.
- It has the `/mnt/ollama-storage` bind mount mapped into `/mnt/ollama-models`.
- Keeps model runtime separated from the PVESO host.

Cons:

- CT101 is stopped and onboot=0.
- Starting CT101 is a real mutation and needs explicit approval.
- Need a no-start preflight first to confirm expected mount/storage, network, and service expectations.
- No GPU is available, so runtime will likely be CPU-only.

Status: preferred candidate path after no-start preflight.

### Option C — New clean model-worker container

Pros:

- Could avoid legacy CT101 surprises.
- Cleaner long-term runtime layout.

Cons:

- More work.
- Requires build/install/configuration.
- Not needed until CT101 and host-level Ollama are ruled out.

Status: fallback only.

## Recommended Direction

Proceed with **CT101-first readiness**, but only after one more no-start preflight.

Reason:

- CT101 is already the `llms` container.
- CT101 is isolated from the PVESO host.
- CT101 has the intended model-storage bind mount.
- Host-level Ollama is currently ambiguous because it is enabled but `activating`.

## Next Phase: E2K No-Start CT101 Readiness Preflight

Before approving any CT start, run a no-start preflight that verifies:

- CT101 remains stopped.
- CT101 config is stable.
- CT101 rootfs and mountpoint references are valid from the host perspective.
- `/mnt/ollama-storage` exists and has expected model directories.
- enough PVESO free memory and disk space exist.
- PVESO firewall/inventory path remains intact.
- CT203 DB counts remain unchanged.
- no Ollama/model endpoint calls are made.
- no service starts/restarts are performed.

## Future Explicit Approval Boundary

Only after E2K no-start preflight passes, the next real mutation would require an approval phrase similar to:

`APPROVE_STAGE_16_E2L_START_CT101_LLMS_FOR_READINESS_ONLY_NO_WORKER_REGISTRATION_NO_MODEL_JOB`

That approval would still keep these protections:

- no scheduler activation
- no persistent worker enablement
- no job dispatch
- no model request from users
- no DB writes except explicitly approved readiness metadata if later needed
- stop/rollback path documented before activation

## Safety Gates Retained

Until separately approved:

- do not start CT101
- do not start/restart Ollama
- do not call `ollama list`
- do not call tcp/11434 endpoints
- do not register workers
- do not enable persistent lane workers
- do not enable scheduler lane dispatch
- do not mutate jobs or DB state
- do not start CT204
- do not unlock/mount private storage
- do not change Cloudflare/DNS/tunnels
