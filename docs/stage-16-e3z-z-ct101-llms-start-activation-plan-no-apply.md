# Stage 16 E3Z-Z — CT101 `llms` start activation plan (no apply)

E3Z_Z_DOC_MARKER_NO_APPLY=1
E3Z_Z_DOC_MARKER_CT101_TARGET=1
E3Z_Z_DOC_MARKER_APPROVAL_REQUIRED=1
E3Z_Z_DOC_MARKER_NO_TIMER_ACTIVATION=1
E3Z_Z_DOC_MARKER_NO_DB_WRITE=1
E3Z_Z_DOC_MARKER_COMPANION_VERTICAL_SLICE_PREP=1

## Purpose

This no-apply checkpoint documents the next safe transition from the legacy temporary PVESO host-level Ollama proof path to the desired model-worker architecture:

- CT203 remains the controller, scheduler, queue, and SQLite DB authority.
- PVESO remains the Proxmox model-worker host.
- CT101 `llms` becomes the replicable model-worker unit.
- VM200 remains the public wrapper/edge.
- PVESO host-level Ollama is treated as legacy or temporary only.

The immediate next live phase should not try to finish the whole companion. It should start CT101 only, observe what is already present, and stop before service/model calls unless separately approved.

## Facts established before this plan

Recent read-only phases established these facts:

- CT203 can reach the selected PVESO LAN target non-interactively over SSH.
- The selected remote host identifies as `pveso` and exposes Proxmox inventory.
- CT101 exists as VMID `101`, is named `llms`, and is currently stopped.
- CT101 `onboot` is absent or default-off in observed config context.
- CT203 scheduler service is inactive/static and timer is inactive/disabled.
- Jobs `35` and `36` remain queued with attempts `0` and result rows `0`.
- Jobs `29`, `30`, `31`, `32`, `33`, and `34` remain hard no-rerun items.

## Why not use host-level PVESO Ollama now

Earlier Stage 16 model proofs called PVESO host-level `http://127.0.0.1:11434/api/generate` over SSH. Those dispatch scripts explicitly refused unless CT101 was stopped. That was useful for proving scheduler/helper safety, but it is not the desired long-term worker shape.

Using CT101 `llms` as the model-worker unit is better because it can be replicated across future Proxmox hosts with the same container contract, resource shape, service layout, and queue-worker integration.

## Proposed next live phase: CT101 start-only observation

The next live phase requires explicit approval because it starts a container. The scope should be:

1. Guard the repo at the current expected checkpoint.
2. Verify CT203 controller/timer idle posture before any action.
3. Verify CT203 can reach PVESO LAN target with non-interactive SSH.
4. Verify CT101 exists, is stopped, and is named `llms`.
5. Verify CT101 onboot remains off or absent/default-off.
6. Start CT101 only with `pct start 101` on PVESO.
7. Wait for CT101 to report `running`.
8. Read CT101 config and minimal runtime facts.
9. Read service posture inside CT101 only if accessible through `pct exec 101`.
10. Do not start or enable services inside CT101 in this phase.
11. Do not call any Ollama/model endpoint.
12. Do not mutate CT203 DB, jobs, timers, scheduler artifacts, or persistent workers.
13. Leave CT101 running only if the explicit approval allows it; otherwise shut it down as bounded cleanup.

## Required approval boundary

Suggested approval phrase for the future live phase:

`APPROVE_STAGE_16_E3Z_AA_START_CT101_LLMS_OBSERVE_ONLY_NO_MODEL_CALLS`

The live phase must be clear about whether CT101 is allowed to remain running afterward. If not explicitly allowed, cleanup should shut CT101 back down.

## CT101 observation checklist after start

The start-only phase should collect:

- CT101 `pct status 101`.
- CT101 `pct config 101`, redacted as needed.
- CT101 hostname, OS release, CPU/memory/disk view.
- CT101 network address and default route.
- Whether `systemctl is-active ollama` is active/inactive/missing.
- Whether port `11434` is listening inside CT101.
- Whether model directories or Ollama storage paths exist.
- GPU/device visibility if configured.
- No calls to `/api/generate`, `/api/chat`, `/api/embed`, `/api/tags`, or `/api/version`.

## Later phase: CT101 model runtime readiness

Only after CT101 start-only observation succeeds should we plan the model runtime step. That later phase may need separate approval for one or more of:

- start Ollama inside CT101,
- install/repair Ollama inside CT101,
- move host-level model storage into CT101,
- attach GPU/device passthrough,
- configure model-worker service inside CT101,
- create a CT101-specific bounded model proof job.

## Later phase: companion vertical slice

The companion proof should remain narrow:

`Frontend/API -> CT203 durable job queue -> scheduler -> CT101 llms model runtime -> DB result -> API/UI readback`

The first companion slice should not include broad persistent workers, broad scheduler dispatch, production route changes, user data migrations, or storage encryption changes. Those remain separate gated tracks.

## Rollback posture

If CT101 start-only observation fails or reveals unexpected autostart behavior, rollback should be bounded to CT101 only:

- collect status/log snippets,
- stop CT101 if the approval did not allow it to remain running,
- verify CT203 scheduler/timer/DB remain untouched,
- do not modify repo or services during rollback unless a separate recovery is approved.

## Hard safety boundaries retained

- No job `34` reuse.
- No rerun of E3V-Q or jobs `29`, `30`, `31`, `32`, `33`, `34`.
- No broad queue activation.
- No persistent worker activation.
- No DB write without explicit DB mutation approval.
- No timer/service activation without explicit activation approval.
- No model endpoint call without explicit model-call approval.
- No CT101 start without explicit CT start approval.
