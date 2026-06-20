# Stage 16-E2K — CT101 No-Start Readiness Preflight

Date: 2026-06-20

## Summary

A no-start readiness preflight was completed for PVESO CT101 `llms`.

No containers were started, no services were started/restarted, no `pct mount` was used, no Ollama/model endpoint calls were made, no workers were registered, no scheduler lanes were activated, and no database writes occurred.

## Platform Safety State

Before and after the preflight:

- VM200 running
- CT203 running
- CT204 stopped
- private storage not mounted
- CT203 controller service active
- `EDGE_POWER_EXECUTE_WAKE=false`
- PVESO inventory path intact
- DB counts unchanged
- no worker/model/scheduler activation
- no Ollama/model endpoint calls

## CT101 Status

CT101 `llms` remains stopped.

Observed config:

- hostname: `llms`
- status: stopped
- onboot: 0
- arch: amd64
- cores: 20
- memory: 31943 MB
- swap: 2048 MB
- ostype: ubuntu
- unprivileged: 1
- rootfs: local-lvm 100G
- rootfs volume listed by Proxmox storage
- net0 on vmbr0 with firewall=1
- bind mount:
  - host `/mnt/ollama-storage`
  - container `/mnt/ollama-models`

## PVESO Host Capacity

PVESO host observed during preflight:

- CPU count: 20
- memory total: about 31945 MB
- memory available: about 29280 MB
- swap total/free: about 16383 MB
- load average low

CT101 resource shape is acceptable for a CPU-only readiness start, but it will consume most of the host memory if fully used.

## Storage Readiness

Required storage paths exist:

- `/mnt/ollama-storage`
  - about 17G used
  - about 227G available
  - mounted from `data-2tb-ollama-lv`
- `/mnt/ollama-storage/blobs`
- `/mnt/ollama-storage/manifests`
- `/mnt/ollama-storage/models`
- `/usr/share/ollama/.ollama/models`
  - about 48G
  - contains partial blobs
- `/var/lib/vz/ollama/models`
  - about 37G

Model inventory without endpoint calls:

- `/mnt/ollama-storage`: 6 manifests, 27 blobs, 0 partial blobs
- `/usr/share/ollama/.ollama/models`: 0 manifests, 69 blobs, 69 partial blobs
- `/var/lib/vz/ollama/models`: 2 manifests, 8 blobs, 0 partial blobs

Interpretation:

- `/mnt/ollama-storage` is the best current CT101 model-storage candidate because it has manifests/blobs and no partial blobs.
- `/usr/share/ollama/.ollama/models` appears polluted/incomplete because all discovered blobs are partial.
- `/var/lib/vz/ollama/models` may contain some usable model material but is not CT101’s configured bind mount.

## Runtime Conflict Notes

PVESO host-level Ollama remains:

- binary present
- service enabled
- service state observed as `activating`
- no tcp/11434 listener observed in previous inventory

This suggests CT101 should be brought up carefully without assuming host Ollama is healthy or available.

## Recommended Next Step

Proceed to a controlled CT101 start-readiness-only stage, with explicit approval, using a narrow activation boundary.

Recommended approval phrase:

`APPROVE_STAGE_16_E2L_START_CT101_LLMS_FOR_READINESS_ONLY_NO_WORKER_REGISTRATION_NO_MODEL_JOB`

The start-readiness-only stage should:

- start CT101 only
- verify CT101 boots
- verify network reachability only as needed
- inspect CT101 services and model paths
- avoid model endpoint calls unless separately approved
- avoid worker registration
- avoid scheduler activation
- avoid DB writes
- keep CT101 onboot=0 unless separately approved
- include a rollback/stop path before any further activation

## Hard Gates Retained

Until separately approved:

- do not start CT101
- do not call Ollama/model endpoints
- do not run user model jobs
- do not register workers
- do not enable persistent lane workers
- do not enable scheduler lane dispatch
- do not write DB state
- do not start CT204
- do not unlock/mount private storage
