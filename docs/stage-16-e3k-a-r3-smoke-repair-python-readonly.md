# Stage 16 E3K-A-R3 — Smoke Repair Python Read-Only

Date: 2026-06-20

## Scope

Repair the E3K-A smoke after the E3K-A DB insert succeeded and the R2 smoke repair still failed due to brittle nested shell/SQLite quoting.

## Method

E3K-A-R3 replaces the synthetic job marker check with a Python read-only SQLite query over the live CT203 DB.

## Validation target

The repaired smoke verifies:

- `jobs=24`
- `job_results=6`
- `synthetic_e3k_a_jobs=1`
- `synthetic_e3k_a_id=25`
- `synthetic_e3k_a_status=queued`
- `synthetic_e3k_a_job_type=stage16_e3k_synthetic_model_smoke`
- `synthetic_e3k_a_requested_model=qwen2.5:32b-instruct-q4_K_M`
- Public routes healthy.
- CT203 DB integrity `ok`.
- PVESO Ollama active and localhost-only.
- CT101 stopped/onboot=0.
- Adapter remains blocked without approval.

## Explicit non-actions

- No DB write.
- No job insert/update/delete.
- No `job_results` insert/update/delete.
- No model call.
- No approved adapter execution.
- No prompt/completion/generate/chat/embed calls.
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

## Next recommended stage

Stage 16 E3K-B should be a separate explicit approval boundary to manually complete the one E3K-A synthetic queued job. That approval must state whether E3K-B may update `jobs`, insert one `job_results` row, or both.
