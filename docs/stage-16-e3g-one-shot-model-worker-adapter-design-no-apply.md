# Stage 16 E3G — One-Shot Model Worker Adapter Design No-Apply

Date: 2026-06-20

## Scope

No-apply design checkpoint for the first one-shot queue/model adapter after E3E-R2 proved PVESO-local model generation works.

## Current checkpoint

- Repo HEAD before E3G: `fd5b394`
- PVESO Ollama is active.
- PVESO Ollama remains bound to `127.0.0.1:11434`.
- Non-localhost `11434` listener count remains 0.
- Available local model tags: `2`
- CT101 remains stopped/onboot=0.
- CT203 remains controller/API/queue authority.
- Public login/API routes remain healthy.
- CT203 DB guard counts remain unchanged.

## Design choice

For the first adapter apply stage, use an **operator-invoked one-shot adapter** rather than a persistent worker, scheduler lane, or public route.

Selected path for E3H:

1. Add a repo script such as `ops/model/pveso-one-shot-generate.sh` or `ops/model/pveso_one_shot_generate.py`.
2. The script is run manually through PPB from the repo.
3. The script discovers PVESO by Tailscale status.
4. The script SSHes to PVESO as root.
5. The remote command calls PVESO-local `http://127.0.0.1:11434/api/generate`.
6. The script prints a structured JSON result to stdout/log.
7. No CT203 DB writes occur.
8. No worker row mutation occurs.
9. No scheduler activation occurs.
10. No persistent service is installed or enabled.
11. No public model endpoint is exposed.
12. CT101 remains stopped/onboot=0.

## Rejected paths for first adapter

### CT203 direct network call to PVESO Ollama

Rejected for the first adapter because Ollama is intentionally bound to localhost only. Opening a network bind/proxy should wait until a separate private transport design gate.

### Persistent PVESO worker service

Rejected for the first adapter because it would introduce service lifecycle, onboot, restart, and worker-registration concerns before the one-shot path is proven.

### Scheduler-dispatched queue worker

Rejected for the first adapter because scheduler activation should come only after manual one-shot model execution is reliable and DB mutation boundaries are explicitly approved.

## E3H proposed apply scope

E3H should require explicit approval and may add a one-shot adapter script only. The script should:

- Default model: `qwen2.5:32b-instruct-q4_K_M`
- Default endpoint: PVESO-local `127.0.0.1:11434`
- Default prompt: tiny deterministic smoke prompt
- Default generation options:
  - `stream=false`
  - `keep_alive=0s`
  - `temperature=0`
  - `num_predict=4`
  - `num_ctx=512`
- Include progress output every 10 seconds.
- Capture response JSON.
- Print sanitized summary.
- Exit nonzero on empty response, missing model, non-localhost listener, CT101 running, or public route/DB guard drift.

## E3H explicit non-actions

- No DB writes.
- No worker registration mutation.
- No worker activation.
- No scheduler activation.
- No model pull/download.
- No CT101 start.
- No CT/VM start/stop/restart.
- No service restart/reload/start/stop.
- No private storage mount/unlock.
- No Cloudflare/DNS/tunnel/nginx mutation.
- No CT203 service restart/reload/env mutation.
- No public model endpoint exposure.

## Later stages

### E3I — manual adapter execution

After E3H adds the adapter script, E3I can run it once with explicit approval and preserve DB/public/CT101 guards.

### E3J — DB-backed one-job design

After the one-shot adapter script passes, design a one-test-job path with DB writes still gated separately.

### E3K — controlled one-job apply

Only after explicit approval, insert/dispatch/complete one controlled test job with before/after DB snapshots.

## Non-actions in E3G

- No prompt/completion/generate/chat/embed calls.
- No DB writes.
- No worker activation.
- No scheduler activation.
- No model pull/download.
- No CT101 start.
- No CT/VM start/stop/restart.
- No service restart/reload/start/stop.
- No private storage mount/unlock.
- No Cloudflare/DNS/tunnel/nginx mutation.
- No CT203 service restart/reload/env mutation.
- No public model endpoint exposure.

## Inventory note

E3G inspected local repo and CT203 deployed runtime for queue, worker, scheduler, lane, job, model, and Ollama references.

Approximate matching source lines captured during scan: `685`
