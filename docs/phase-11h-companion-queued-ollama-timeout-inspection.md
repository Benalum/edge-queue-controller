# Phase 11H Companion Queued Ollama Timeout Inspection

Phase 11H starts from the Phase 11G clean frontend/system baseline and inspects a Companion queued Ollama timeout.

## Baseline

Previous checkpoint:

- Phase: Phase 11G
- Commit: b9ede0e fix: use system status readiness phase 11g
- Tag: controller-phase-11g-system-render-readiness-variable-repair-2026-06-13
- Result: PASS

## User test result

Study command flow worked:

- Start study session
- Select Balanced
- Start questions
- Mark wrong/correct
- Stop study session

Normal Companion chat then failed:

- User message: What is a pimple
- Job: s5f18-job-d0425f23fd07bf0c
- Error: stage 5e21 bounded ollama failure
- Detail: Ollama request failed: timed out
- UI status: Error
- Queue: Failed
- Worker: Companion queue worker
- Model: fallback: gemma4:e4b

## Interpretation

The frontend route and Study command handling are working.

The failure is in the queued Companion model path:

Browser
→ /api/chat/queued
→ queue job
→ Companion queue worker
→ Ollama request
→ timeout

## Phase 11H-R1 repair note

The first Phase 11H smoke did not commit because it treated unavailable/slow status checks as hard failures and the optional CT101 SSH inspection was interrupted.

Phase 11H-R1 keeps this stage read-only and records evidence without requiring protected queue endpoints or optional CT101 SSH to succeed.

## Safety posture

Allowed:

- GET-only HTTP checks from this smoke.
- Read-only systemctl inspection.
- Read-only journalctl inspection.
- Read-only source/config inspection.
- Optional bounded CT101 SSH read-only inspection.
- Documentation and smoke checkpoint.

Not allowed:

- No service restarts.
- No new Companion jobs.
- No model pulls.
- No backend router rollout.
- No backend router dry-run enablement.
- No frontend router POST traffic.
- No persistent rollout mutation routes.
- No auth/route boundary changes.

## Questions this inspection should answer

1. Is the Companion route available?
2. Are protected queue endpoints correctly protected?
3. Is the queue worker heartbeating and claiming jobs?
4. Did the specific failed job get polled by the browser?
5. Did the worker complete the job with an error payload?
6. Is the likely failure a bounded Ollama timeout, model cold start, slow model, or CT101/Ollama availability issue?

## Candidate Phase 11I repair paths

Possible repairs after inspection:

1. Increase bounded Ollama timeout only if model responses are healthy but slow.
2. Switch fallback model to a known faster/smaller model if current model is too slow.
3. Add a clearer user-facing timeout message.
4. Add a preflight model availability check to System/Admin.
5. Add worker warmup/keepalive if cold-start model load causes the timeout.
6. Add safer retry behavior only if it will not duplicate jobs or overload the worker.

## Done criteria

Phase 11H is done when:

- This inspection document exists.
- A read-only smoke exists.
- The smoke sends no Companion job creation traffic.
- The smoke restarts no services.
- The smoke captures Companion route, auth boundary, worker log, and Ollama/config evidence.
- Optional CT101 SSH failures do not block the checkpoint.
- The checkpoint is committed, tagged, and pushed only after the smoke passes.

## Phase 11H-R1 Smoke Evidence

Generated: 2026-06-13T00:51:34-06:00

### Git

```text
b9ede0e fix: use system status readiness phase 11g
2ab7fb2 fix: complete system loading render phase 11f
328ae3f fix: stabilize system page render phase 11e
e0d2f8e docs: inspect system page double render phase 11d
29805d9 style: polish admin system dashboard css phase 11c
3523ff3 docs: inspect admin system dashboard polish phase 11b
7e1501e docs: add phase 11a post-transition product quality plan
9c3572f test: checkpoint transition complete baseline stage 10o
d0f5b4f test: verify post cache system status stability stage 10n
e53b0e3 perf: cache system status briefly stage 10m
eadbe18 test: inspect system status backend dependencies stage 10l
169393b docs: plan system status optimization stage 10k
controller-phase-11g-system-render-readiness-variable-repair-2026-06-13
```

### Failed job

```text
FAILED_JOB_ID=s5f18-job-d0425f23fd07bf0c
Observed user-facing error: stage 5e21 bounded ollama failure: Ollama request failed: timed out
```

### Selected gateway

```text
FRONTEND_BASE=http://127.0.0.1:8787
```

### Key evidence from repaired smoke

- /companion was reachable from the selected frontend gateway.
- Queue job status endpoints are protected and reject unauthenticated reads, which is expected outside the browser session.
- Local controller and wrapper services were inspected without restarts.
- Worker heartbeat/claim/complete log markers were collected for the failed job window.
- Optional CT101/Ollama SSH inspection was bounded and does not block the checkpoint.

### Recommended Phase 11I direction

Use the collected source/log evidence to choose the smallest reliability repair: bounded timeout adjustment, faster fallback model, Ollama warmup/preflight, or clearer timeout handling.
