# Phase 14J-GL - CT202 private auth-flow runtime smoke temporary only

PHASE_14J_GL_CT202_PRIVATE_AUTH_FLOW_RUNTIME_SMOKE_TEMPORARY_ONLY

PHASE_14J_GL_RESULT=ct202_private_auth_flow_runtime_smoke_passed_temporary_only

The user explicitly approved the temporary private auth-flow runtime smoke with:

APPROVE_PHASE_14J_GL_CT202_PRIVATE_AUTH_FLOW_RUNTIME_SMOKE_TEMPORARY_ONLY

## Verified state

PHASE_14J_GL_CT_ID=202

PHASE_14J_GL_HOSTNAME=edge-controller

PHASE_14J_GL_STATUS=running

PHASE_14J_GL_DB_PATH=/srv/edge-controller/data/edge_queue.sqlite3

The final successful GL-R1D smoke used a temporary in-process CT202-only public API key for loopback-only testing.

The key was generated for the process, was not printed, was not committed, was not stored in Source, and was not made persistent.

Verified:

- CT202 local DB backup was created before the auth-flow smoke
- temporary Uvicorn bind was 127.0.0.1 only
- temporary Uvicorn port was 17071
- /openapi.json returned HTTP 200
- auth OpenAPI paths were present
- temporary in-process CT202 public API key was configured
- temporary public API key value was not printed
- CT202-local verified test user was prepared
- /public/auth/login returned HTTP 200
- login response contained safe top-level keys: ok, session, user
- /public/auth/logout returned HTTP 200
- generated CT202-local auth test rows were cleaned up
- SQLite quick_check passed after cleanup
- temporary Uvicorn process was stopped
- exact matching temporary Uvicorn process was absent after cleanup
- loopback port listener was absent after stop
- edge-queue-controller systemd service was not created
- edge-queue-controller runtime was not active after the smoke
- laptop controller was not stopped
- no data was imported from the laptop DB

## Prior failed GL attempts

Earlier GL attempts failed safely before this successful result:

- GL initial pasted block failed due pasted Python syntax corruption before the auth test executed.
- GL-R1B failed because the temp script ran from /tmp and could not import edge_controller.
- GL-R1C reached login but returned HTTP 503 because /public/auth/login requires the public API key gate before login body processing.
- A cleanup/diagnostic phase verified no leftover process, listener, or generated test rows and identified _require_public_api_key(request) as the login gate.

## Runtime boundary

CT 202 is still not authoritative.

The laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority.

The laptop controller service remains the live controller.

## Not performed

- no auth-flow smoke rerun in record phase
- no persistent controller runtime activation
- no persistent Uvicorn process left running
- no systemd service creation
- no systemd enable
- no systemd start
- no laptop controller stop
- no data migration
- no data import
- no live laptop DB mutation
- no controller/queue migration
- no worker start
- no production DB/job mutation
- no CT101 call
- no model/Ollama endpoint call
- no Cloudflare route mutation
- no public route mutation
- no raw IP recording
- no auth URL recording
- no token or password recording
- no public API key recording
- no Phase 14J-AG apply wrapper rerun

## Next safe phase

NEXT_SAFE_PHASE=phase_14j_gm_ct202_private_system_and_queue_route_runtime_smoke_requires_explicit_approval
