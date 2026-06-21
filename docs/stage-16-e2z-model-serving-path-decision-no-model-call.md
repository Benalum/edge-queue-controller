# Stage 16 E2Z — Model Serving Path Decision, No Model Call

Date: 2026-06-20  
Scope: read-only model-serving path inventory and decision after E2Y.

## Boundary

This phase performed read-only inventory only.

Explicitly not performed:

- No CT start/stop/restart.
- No service restart/reload/start/stop.
- No pct mount/unmount.
- No DB write.
- No worker activation.
- No scheduler activation.
- No Ollama/model endpoint calls.
- No package install/download.
- No public routing changes.
- No private-storage mount/unlock.

## Current Platform Guard

Before E2Z:

- Repo HEAD/origin: `dd99327`.
- Public `/`: HTTP 200.
- Public `/login`: HTTP 200.
- Public `/api/me`: HTTP 401.
- Public `/api/system/status`: HTTP 200.
- VM200 running.
- CT203 running.
- CT204 stopped.
- Private storage not mounted.
- CT203 controller active.
- CT203 health/status HTTP 200.

## E2Y Carry-Forward

E2Y proved CT101 can start cleanly without reactivating masked legacy autostarts, then shut down safely.

E2Y also found:

- CT101 `ollama_binary` absent/not found.
- CT101 `/mnt/ollama-models` existed.
- CT101 model manifest count: 0.
- CT101 model blob count: 0.
- CT101 partial count: 0.

Therefore CT101 is no longer an immediate legacy-autostart hazard, but it is not yet proven as the model-serving authority.

## Read-Only Inventory Summary

Host Ollama binary present: `yes`  
Host 11434 listener present: `no`  
Any host model manifest count positive: `no`

The raw inventory was captured in the PPB run output with secrets/IPs sanitized.

## Decision

At this checkpoint, the safest decision is:

1. Do not make CT101 the canonical model-serving path yet.
2. Do not activate workers or scheduler lanes yet.
3. Use a separate first-model-call approval only after confirming the host/container serving path and model inventory.
4. Prefer the path that has both:
   - a real Ollama binary/service/listener, and
   - non-empty model manifests/blobs.

If the host Ollama path has the real inventory, PVESO host Ollama is the likely first endpoint to validate. If not, CT101 needs a clean model install/bind decision before any model-call phase.

## Recommended Next Approval

Use a separate approval for the first actual model endpoint call.

Suggested approval phrase:

`APPROVE_STAGE_16_E3A_FIRST_MODEL_ENDPOINT_HEALTH_AND_LIST_CALL_ONLY_NO_WORKER_ACTIVATION_NO_SCHEDULER_ACTIVATION_NO_DB_WRITE`

Expected E3A constraints:

- One endpoint health/list call only.
- No prompt/completion generation yet.
- No DB writes.
- No worker activation.
- No scheduler activation.
- No public routing changes.
- No model download/install.
- Record model inventory and endpoint source.
