# Stage 16 E3F — Queue-to-Model Worker Path Design No-Apply

Date: 2026-06-20

## Scope

No-apply design checkpoint for connecting CT203 queue/controller authority to PVESO local Ollama after E3E-R2 proved a captured local model prompt can run.

## Current checkpoint

- Repo HEAD before E3F: `58b1e42`
- PVESO Ollama is active.
- PVESO Ollama remains bound to `127.0.0.1:11434`.
- Non-localhost `11434` listener count remains 0.
- Available local model tags: `2`
- CT101 remains stopped/onboot=0.
- CT203 remains controller/API/queue authority.
- Public login/API routes remain healthy.
- CT203 DB guard counts remain unchanged.

## E3E-R2 result carried forward

- A local-only PVESO `/api/generate` call succeeded.
- Model: `qwen2.5:32b-instruct-q4_K_M`
- Response was captured and non-empty.
- No DB write, worker activation, scheduler activation, model pull, CT101 start, or public exposure occurred.

## Repo/runtime inventory

E3F inspected local repo and CT203 deployed runtime for queue, worker, scheduler, lane, job, model, and Ollama references.

Approximate matching source lines captured during scan: `390`

## Design decision

Do not expose PVESO Ollama publicly and do not bind Ollama to a non-localhost address yet.

The next queue-to-model path should be staged in three separate gates:

### E3G — one-shot worker adapter no-apply/design

Design a one-shot model-worker adapter that can be invoked manually and isolated from the scheduler. It should:
- Accept a single synthetic/test payload.
- Use PVESO localhost Ollama through a controlled transport.
- Write no CT203 DB rows in the first design phase.
- Avoid persistent worker registration.
- Avoid scheduler dispatch.
- Avoid public endpoint exposure.
- Keep CT101 stopped.

### E3H — one-shot worker adapter dry-run/apply

Only after explicit approval, add or run a one-shot adapter path with:
- One controlled test payload.
- One model call.
- Output printed to terminal/log only.
- No DB write unless separately approved.
- No persistent worker process.
- No scheduler activation.

### E3I — queue-to-model DB path

Only after the one-shot adapter passes, consider a controlled DB-backed queue test:
- Create one test job only if explicitly approved.
- Dispatch one job only through a manual one-shot worker.
- Insert one job result only if explicitly approved.
- Preserve DB guard snapshots before and after.
- Keep scheduler/persistent workers disabled.

## Non-actions in E3F

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

## Next recommended step

Stage 16 E3G should be a no-apply one-shot worker adapter design. It should inspect the existing controller code enough to choose between:
1. SSH-executed PVESO localhost adapter,
2. CT203-side adapter that reaches a future private-only model proxy, or
3. deploying a tiny PVESO-local worker service later.

E3G should still avoid DB writes and worker/scheduler activation.
