# Stage 16 FC-O45-E-BN-R2 — Companion Model-Worker Readiness Read-Only

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `eba85d4`
- Prior deploy tag: `controller-stage-16-fc-o45-e-bm-deploy-companion-delegated-enter-over-tailscale-restricted-path-2026-06-24`

## User observation

The user confirmed Enter-to-send works live after BM.

Remaining issue:

- Companion jobs create successfully.
- The visible assistant message says the job is queued / `mock/no-model`.
- Example observed job: `568`.

## Purpose

BN-R2 is a read-only readiness checkpoint to explain `mock/no-model` and prepare the next bounded worker/model activation step.

BN-R1 failed safely because the read-only DB query assumed `job_results.id` existed. The live table does not have an `id` column.

## Scope

Read-only runtime checks plus repo docs/smoke commit/tag only.

Explicitly not allowed and not performed:

- NO live deploy.
- NO public `/var/www` mutation.
- NO DB write.
- NO job mutation.
- NO result insert.
- NO model/helper/Ollama generation call.
- NO scheduler activation.
- NO timer activation.
- NO persistent worker activation.
- NO backend API deploy.
- NO nginx/cloudflared config mutation.
- NO sshd config mutation.
- NO service restart/reload/start/stop/enable/disable.
- NO CT/VM restart.
- NO storage mutation.
- NO file deletion.

## Interpretation

The key expected finding is:

```
companion.chat jobs are queued with requested_model=mock/no-model
```

That means the UI is creating jobs, but they are not configured for a real model worker path yet.

To get real assistant replies, the next phase must explicitly approve a bounded model-worker activation proof.

Recommended next phase after BN-R2:

```
FC-O45-E-BO — bounded Companion model-worker activation proof
```

That future phase is expected to require explicit approval because it would claim a job and call a model/helper path.

## Output

```
=== Stage 16 FC-O45-E-BN-R2 Companion model-worker readiness read-only ===
MUTATION_SCOPE=read_only_runtime_preflight_plus_repo_doc_smoke_commit_tag_push
FIX=schema_aware_job_results_query_and_controller_port_discovery
NO live deploy
NO public /var/www mutation
NO DB write
NO job mutation
NO result insert
NO model/helper/Ollama generation call
NO scheduler activation
NO timer activation
NO persistent worker activation
NO backend API deploy
NO nginx/cloudflared config mutation
NO sshd config mutation
NO service restart/reload/start/stop/enable/disable
NO CT/VM restart
NO storage mutation
NO file deletion

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=eba85d4
head_now=eba85d4
origin_main_now=eba85d4
git_preflight=PASS

=== public read-only checks ===
public_root_http=200
public_app_js_http=200
public_unauth_job568_http=401
{"detail":"Missing bearer token."}
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045ebm"
<script src="/queued_chat_config.js"

=== CT203/PVEW read-only runtime checks ===
--- PVEW host basics ---
pvew
2026-06-25T01:50:02Z
status: running

--- CT203 controller/service posture ---
ct203_hostname=edge-controller-pvew
controller_service_active=active
controller_service_enabled=enabled
worker_timer_active=inactive
worker_timer_enabled=not-found
worker_service_active=inactive
worker_service_enabled=not-found
listening_ports:
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                                              
LISTEN 0      2048         0.0.0.0:7070      0.0.0.0:*    users:(("python",pid=13158,fd=14))                  
LISTEN 0      100        127.0.0.1:25        0.0.0.0:*    users:(("master",pid=235,fd=12))                    
LISTEN 0      100            [::1]:25           [::]:*    users:(("master",pid=235,fd=13))                    
LISTEN 0      4096               *:22              *:*    users:(("sshd",pid=87,fd=3),("systemd",pid=1,fd=56))
env_flags:
EDGE_CT203_SQLITE_WORKER_API_ENABLED=1

--- CT203 internal API read-only probes, discovered ports ---
curl: (7) Failed to connect to 127.0.0.1 port 8000 after 0 ms: Could not connect to server
ct203_http port=8000 path=/internal/edge-worker/summary code=000

curl: (7) Failed to connect to 127.0.0.1 port 8000 after 0 ms: Could not connect to server
ct203_http port=8000 path=/system/status code=000

curl: (7) Failed to connect to 127.0.0.1 port 8000 after 0 ms: Could not connect to server
ct203_http port=8000 path=/api/system/status code=000

curl: (7) Failed to connect to 127.0.0.1 port 8080 after 0 ms: Could not connect to server
ct203_http port=8080 path=/internal/edge-worker/summary code=000

curl: (7) Failed to connect to 127.0.0.1 port 8080 after 0 ms: Could not connect to server
ct203_http port=8080 path=/system/status code=000

curl: (7) Failed to connect to 127.0.0.1 port 8080 after 0 ms: Could not connect to server
ct203_http port=8080 path=/api/system/status code=000

curl: (7) Failed to connect to 127.0.0.1 port 18080 after 0 ms: Could not connect to server
ct203_http port=18080 path=/internal/edge-worker/summary code=000

curl: (7) Failed to connect to 127.0.0.1 port 18080 after 0 ms: Could not connect to server
ct203_http port=18080 path=/system/status code=000

curl: (7) Failed to connect to 127.0.0.1 port 18080 after 0 ms: Could not connect to server
ct203_http port=18080 path=/api/system/status code=000

curl: (7) Failed to connect to 127.0.0.1 port 5000 after 0 ms: Could not connect to server
ct203_http port=5000 path=/internal/edge-worker/summary code=000

curl: (7) Failed to connect to 127.0.0.1 port 5000 after 0 ms: Could not connect to server
ct203_http port=5000 path=/system/status code=000

curl: (7) Failed to connect to 127.0.0.1 port 5000 after 0 ms: Could not connect to server
ct203_http port=5000 path=/api/system/status code=000


--- CT203 live DB read-only queue/job inspection, schema-aware ---
db_path=/var/lib/edge-queue-controller/edge_queue.sqlite3
db_exists=true
table_jobs_exists=true
table_job_results_exists=true
jobs_columns=id,job_type,prompt,requested_model,status,attempts,last_error,created_at,updated_at,forwarded_at,user_id
recent_jobs_json=[{"id": 569, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:43:16.805622+00:00", "updated_at": "2026-06-25T01:43:16.805622+00:00", "user_id": 16}, {"id": 568, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:36:29.420762+00:00", "updated_at": "2026-06-25T01:36:29.420762+00:00", "user_id": 16}, {"id": 567, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.603874+00:00", "updated_at": "2026-06-25T01:15:17.603874+00:00", "user_id": 16}, {"id": 566, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.592859+00:00", "updated_at": "2026-06-25T01:15:17.592859+00:00", "user_id": 16}, {"id": 565, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.580188+00:00", "updated_at": "2026-06-25T01:15:17.580188+00:00", "user_id": 16}, {"id": 564, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.568611+00:00", "updated_at": "2026-06-25T01:15:17.568611+00:00", "user_id": 16}, {"id": 563, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.557061+00:00", "updated_at": "2026-06-25T01:15:17.557061+00:00", "user_id": 16}, {"id": 562, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.544947+00:00", "updated_at": "2026-06-25T01:15:17.544947+00:00", "user_id": 16}, {"id": 561, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.532838+00:00", "updated_at": "2026-06-25T01:15:17.532838+00:00", "user_id": 16}, {"id": 560, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.509021+00:00", "updated_at": "2026-06-25T01:15:17.509021+00:00", "user_id": 16}, {"id": 559, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.497621+00:00", "updated_at": "2026-06-25T01:15:17.497621+00:00", "user_id": 16}, {"id": 558, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.486326+00:00", "updated_at": "2026-06-25T01:15:17.486326+00:00", "user_id": 16}, {"id": 557, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.474957+00:00", "updated_at": "2026-06-25T01:15:17.474957+00:00", "user_id": 16}, {"id": 556, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.463683+00:00", "updated_at": "2026-06-25T01:15:17.463683+00:00", "user_id": 16}, {"id": 555, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.452363+00:00", "updated_at": "2026-06-25T01:15:17.452363+00:00", "user_id": 16}, {"id": 554, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.440963+00:00", "updated_at": "2026-06-25T01:15:17.440963+00:00", "user_id": 16}, {"id": 553, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.429634+00:00", "updated_at": "2026-06-25T01:15:17.429634+00:00", "user_id": 16}, {"id": 552, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.418344+00:00", "updated_at": "2026-06-25T01:15:17.418344+00:00", "user_id": 16}, {"id": 551, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.406900+00:00", "updated_at": "2026-06-25T01:15:17.406900+00:00", "user_id": 16}, {"id": 550, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.395563+00:00", "updated_at": "2026-06-25T01:15:17.395563+00:00", "user_id": 16}, {"id": 549, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.384179+00:00", "updated_at": "2026-06-25T01:15:17.384179+00:00", "user_id": 16}, {"id": 548, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.372789+00:00", "updated_at": "2026-06-25T01:15:17.372789+00:00", "user_id": 16}, {"id": 547, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.361434+00:00", "updated_at": "2026-06-25T01:15:17.361434+00:00", "user_id": 16}, {"id": 546, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.349913+00:00", "updated_at": "2026-06-25T01:15:17.349913+00:00", "user_id": 16}]
job568_json={"id": 568, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:36:29.420762+00:00", "updated_at": "2026-06-25T01:36:29.420762+00:00", "user_id": 16}
job569_json={"id": 569, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:43:16.805622+00:00", "updated_at": "2026-06-25T01:43:16.805622+00:00", "user_id": 16}
jobs_by_status_json=[{"status": "completed", "n": 69}, {"status": "failed", "n": 3}, {"status": "forwarded", "n": 18}, {"status": "queued", "n": 464}, {"status": "running", "n": 10}]
companion_jobs_by_requested_model_status_json=[{"requested_model": "mock/no-model", "status": "completed", "n": 3}, {"requested_model": "mock/no-model", "status": "failed", "n": 1}, {"requested_model": "mock/no-model", "status": "queued", "n": 439}, {"requested_model": "qwen2.5:0.5b", "status": "completed", "n": 5}]
job_results_columns=job_id,model,response_text,response_json,error,created_at,updated_at
job568_results_json=[]
job569_results_json=[]

--- PVEW to PVESO/CT101 read-only posture ---
pveso
2026-06-25T01:50:05Z
status: running
active
inactive
pveso_ssh_rc=0

ct101_hostname=llms
ollama_worker_active=inactive
general_queue_template=edge-ct101-general-queue-worker@.service disabled enabled
docker_active=active
docker_socket_active=active
ollama Up 33 hours (healthy)
ct101_readonly_rc=0

=== readiness conclusion ===
BN_R2_READ_ONLY_READY_FOR_NEXT_APPROVAL=bounded_worker_model_activation_required
EXPECTED_REASON_FOR_MOCK_NO_MODEL=companion_jobs_are_created_with_requested_model_mock_no_model_and_no_active_model_worker_claims_them
```
