# Stage 16 E3Z-EK guarded service/timer/persistent-worker strategy no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 E3Z-EJ-C-R12-I2.
- Base HEAD/origin/main: `5c89dbb`.
- Base tag: `controller-stage-16-e3z-ej-c-r12-g3-foreground-oneshot-job48-completion-2026-06-22`.
- Base commit message: `docs: record stage 16 e3z ej c r12 g3 job48 completion`.
- Repository state at this stage entry: clean except for the recovered E3Z-EK doc/smoke files from the first failed smoke attempt.

## Mutation boundary for this stage

This E3Z-EK checkpoint is repo-only planning.

It does not:

- write the CT203 database,
- insert, reset, or mutate jobs,
- apply schema,
- start, stop, restart, reload, enable, or disable worker services,
- activate scheduler services or timers,
- start, stop, or restart CTs or VMs,
- mutate Docker containers,
- call Ollama generate, chat, embed, or model endpoints,
- download or pull models,
- mutate SSH config,
- mutate `/etc/hosts`.

## Read-only baseline captured for EK

### CT203 controller/API/queue/DB authority

```text
ct203_db_path=/var/lib/edge-queue-controller/edge_queue.sqlite3
ct203_db_readable=yes
ct203_sqlite_quick_check=ok
jobs_37_48_seen=12
jobs_37_48_completed_with_one_result=12
job48=completed,attempts=4,results=1,model=qwen2.5:0.5b
ct203_scheduler_timer_surface=
  edge-queue-controller-scheduler.service load=not-found active=inactive enabled=not-found
  edge-queue-controller-scheduler.timer load=not-found active=inactive enabled=not-found
  edge-controller-scheduler.service load=not-found active=inactive enabled=not-found
  edge-controller-scheduler.timer load=not-found active=inactive enabled=not-found
  edge-persistent-lane-workers.service load=not-found active=inactive enabled=not-found
  edge-persistent-lane-workers.timer load=not-found active=inactive enabled=not-found
  edge-queue-controller-worker.service load=not-found active=inactive enabled=not-found
  edge-queue-controller-worker.timer load=not-found active=inactive enabled=not-found
```

### PVESO / CT101 model runtime target

```text
pveso_tailscale_online=true
pveso_operator_route=openssh_root_at_pveso_tailscale_ip
pveso_hostname=pveso
ct101_status=running
edge-ct101-ollama-worker.service load=loaded active=inactive enabled=disabled
ai-platform-laptop-queue-worker.service load=masked active=inactive enabled=masked
ai-platform-laptop-queue-worker@model-tiny.service load=masked active=inactive enabled=masked
ai-platform-laptop-queue-worker@model-small.service load=masked active=inactive enabled=masked
ct101_matching_active_or_known_timer_rows=0
ct101_heartbeat_timer_unit_file=ai-platform-edge-heartbeat.timer masked   enabled
ollama_container=ollama status=Up 7 hours (healthy) image=ollama/ollama:latest
ollama_container_status=running health=healthy restart_count=0
ct101_ollama_11434_listener_present=yes
ct101_worker_sha256=69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f
ct101_profile_sha256=329118c8916917e538200ee5c0e6d2b4c2a214adf00cf075b810ee23d0baed1d
```

Key interpretation:

- PVESO is online in Tailscale.
- Local resolver/MagicDNS name resolution for `pveso` is not currently reliable in the laptop PPB shell.
- The working operator route is OpenSSH to root at the PVESO Tailscale IP, discovered dynamically from `tailscale status --json`.
- CT101 is running.
- `edge-ct101-ollama-worker.service` is loaded but inactive and disabled.
- Legacy laptop queue worker units are inactive and masked.
- The Ollama Docker container is running and healthy.
- Scheduler/timer activation remains off for the production queue path.

## Strategic goal

E3Z-EJ-C proved the bounded foreground one-shot CT101 worker path can claim one exact queued job, call CT101 Ollama, and complete the job with exactly one result row.

E3Z-EK plans the next transition: from manual foreground one-shot proof to a guarded service/timer strategy, while preserving the same safety posture.

The strategy is intentionally no-apply until a later explicitly approved stage.

## Guarded activation design

A future apply stage should only test a bounded worker service/timer path with a fresh exact-marker job. It must not turn on open-ended background processing.

Required constraints for a future apply:

1. Create or select one fresh queued test job only after explicit approval.
2. Require a known expected job id, expected marker, expected requested model, and expected response hash or exact response.
3. Require the CT203 DB quick check to be OK before activation.
4. Require jobs 37-48 to remain completed with exactly one result row each before activation.
5. Require CT101 Ollama container to be running and healthy before activation.
6. Require `edge-ct101-ollama-worker.service` to start only in a bounded mode.
7. Require the bounded worker to claim only the exact approved job.
8. Require no general queue drain.
9. Require no model download or pull.
10. Require no scheduler-wide activation.
11. Require no persistent timer enablement during the first test.
12. Require post-test service posture to return to inactive/disabled.
13. Require post-test timer posture to remain disabled or absent for the queue worker path.
14. Require final DB verification that the test job completed with exactly one result row.
15. Require a repo checkpoint after the apply result.

## Service strategy

The service unit should remain disabled by default.

The first service-path proof should prefer a bounded one-shot service invocation rather than a persistent daemon. The worker must preserve the exact-job guard already proven in foreground mode.

The service should only be considered eligible for persistent operation after multiple successful bounded proofs show:

- exact job selection,
- exact model routing,
- exact result-row behavior,
- no stale job replay,
- no accidental multi-job drain,
- clean post-run service posture,
- clear rollback.

## Timer strategy

No queue-processing timer should be enabled in E3Z-EK.

A later timer test may be considered only after a bounded service proof succeeds. The first timer proof should be a one-tick test with an exact fresh queued job, and the timer must remain disabled after the test.

The timer must not become the default platform scheduler until these are true:

- service proof is repeatable,
- exact-job guard is repeatable,
- stale job refusal is repeatable,
- CT203 scheduler posture is understood,
- rollback has been tested,
- the user explicitly approves timer activation.

## Persistent worker strategy

Persistent workers remain default-off.

A persistent worker path should not be enabled until there is evidence for:

- lane-specific eligibility,
- disabled-by-default registration metadata,
- bounded concurrency,
- safe lease behavior,
- clear service health reporting,
- controlled model profile selection,
- no fallback to unfiltered workers,
- no open queue drain without lane guard,
- rollback to inactive service posture.

The intended production architecture remains:

Frontend -> Backend API -> CT203 queue/DB -> scheduler/lease -> guarded worker -> CT101 Ollama/model runtime -> job result.

Users should never call model endpoints directly.

## PVESO route note

Because the local PPB shell did not resolve `pveso` through normal DNS/MagicDNS, future blocks should dynamically discover the PVESO Tailscale IP from `tailscale status --json` and use the known working operator route.

A future route-hardening stage may add a local SSH alias, but that is intentionally not part of this no-apply checkpoint.

## Recommended next stage

Recommended next stage: `Stage 16 E3Z-EL`.

Purpose: create a no-apply exact acceptance contract for the first bounded service-path proof.

The E3Z-EL contract should define:

- fresh test job requirements,
- expected exact marker,
- worker service invocation mode,
- refusal behavior for stale jobs,
- post-run DB checks,
- post-run service/timer checks,
- rollback and abort criteria.

E3Z-EL should still be repo-only unless separately approved for runtime mutation.
