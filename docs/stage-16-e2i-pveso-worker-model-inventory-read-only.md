# Stage 16-E2I — PVESO Worker/Model Inventory Read-Only

Date: 2026-06-20

## Summary

PVESO is now reachable from CT203 through the persistent inventory path, and a read-only worker/model inventory was completed without starting containers, activating workers, calling Ollama/model endpoints, or mutating the database.

This phase confirms PVESO is the likely primary on-demand model host, but still requires a separate readiness plan before any worker/model activation.

## Confirmed Platform Safety State

Before and after inventory:

- VM200 running
- CT203 running
- CT204 stopped
- private storage not mounted
- CT203 controller service active
- `EDGE_POWER_EXECUTE_WAKE=false`
- PVESO inventory endpoint returns HTTP 200 and `ok=true`
- no DB count changes
- no CT/VM start/stop/restart
- no worker/model/scheduler activation
- no Ollama/model endpoint calls

## PVESO Proxmox Inventory

PVESO containers:

- CT101 `llms`: stopped
- CT201 `edge-data`: stopped
- CT202 `edge-controller`: stopped

PVESO VMs:

- none reported

## CT101 `llms` Inventory

CT101 is the historical model/LLM container candidate.

Observed read-only config:

- status: stopped
- onboot: 0
- architecture: amd64
- cores: 20
- memory: about 31 GB
- swap: 2048 MB
- ostype: ubuntu
- unprivileged: 1
- rootfs: local-lvm 100G
- mountpoint:
  - host `/mnt/ollama-storage`
  - container `/mnt/ollama-models`

No `pct start`, `pct mount`, worker activation, model load, or runtime endpoint call was performed.

## PVESO Host Runtime Inventory

PVESO host:

- Ollama binary present at `/usr/local/bin/ollama`
- Ollama service enabled
- Ollama service state observed as `activating`
- Docker absent/inactive
- Podman absent/inactive
- Node/npm absent
- Python 3 present

No `ollama list`, `curl :11434`, or other Ollama/model endpoint call was performed.

## Model/Storage Paths

Observed read-only model/storage paths:

- `/usr/share/ollama/.ollama/models`
  - exists
  - about 48G
  - includes `manifests` and `blobs`
  - includes many `partial` blob files, which may indicate incomplete/interrupted model pulls or partial downloads
- `/mnt/ollama-storage`
  - exists
  - includes `manifests`, `blobs`, `models`, `cache`, `ollama`, and backup/data directories
- `/var/lib/vz/ollama/models`
  - exists under `/var/lib/vz/ollama`
- `/root/.ollama`
  - exists, minimal
- `/var/lib/ollama`
  - missing

## Hardware Notes

PVESO hardware inventory found:

- Intel UHD Graphics 630 visible
- no NVIDIA GPU detected
- `nvidia-smi` absent

This implies near-term model serving is likely CPU-only unless additional GPU hardware is added or discovered later.

## Network/Listeners

PVESO host listeners observed:

- SSH on tcp/22
- no Ollama tcp/11434 listener observed in the read-only listener check

## Current Interpretation

PVESO has meaningful local model storage and a stopped CT101 `llms` container wired to `/mnt/ollama-storage`. However, Ollama on the PVESO host appears enabled but stuck/activating, and CT101 remains stopped. The safest next step is a no-start readiness plan that inspects exactly what would be required to choose between:

1. PVESO host-level Ollama repair/readiness, or
2. CT101 `llms` container start/readiness, or
3. a new controlled model worker container path.

## Next Safe Step

Recommended next phase:

**Stage 16-E2J — PVESO model runtime readiness plan no-apply**

Constraints:

- no CT starts
- no service starts/restarts
- no Ollama endpoint calls
- no model loads
- no worker registration
- no scheduler activation
- no DB writes
- produce a clear activation plan and approval boundary
