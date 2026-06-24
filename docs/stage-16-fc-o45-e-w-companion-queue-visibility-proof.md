# Stage 16 FC-O45-E-W — Companion queue visibility proof

Date: 2026-06-24

## Result

Companion job `124`, created by the signed-in public Companion UI in FC-O45-E-V, remains visible in the controller queue and is still unprocessed.

## Verified job

- Job id: `124`
- Status: `queued`
- Job type: `companion.chat`
- Requested model: `mock/no-model`
- Attempts: `0`
- Forwarded: no
- Result rows: `0`
- Completed: no

## Queue snapshot

- Jobs total: `119`
- Status counts: `{"completed": 61, "failed": 3, "forwarded": 18, "queued": 27, "running": 10}`

## Public guard verification

- Public `/api/system/status`: HTTP 200
- Signed-out `/api/me`: HTTP 401
- Signed-out `/api/companion/chat`: HTTP 401
- Signed-out `/api/jobs`: HTTP 404

## Guardrails

This phase was read-only against CT203 SQLite. It did not mutate the DB, complete the job, start workers, call models, call helpers, invoke runtime execution, activate scheduler/timer, restart services, deploy code, change schema, restart CT/VMs, or mutate nginx/cloudflared/storage.

## Next recommended step

Continue to either a queue/admin UI visibility proof or a separately approved bounded worker/model execution proof for job `124`.
