# Stage 16 FC-O45-E-BP2-R2 — Deploy CT203 Companion Real-Model Routing and Restart Controller

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `e5016d6`
- Prior source tag: `controller-stage-16-fc-o45-e-bp-r3-r2-complete-companion-real-model-routing-source-no-runtime-2026-06-24`

## Approval

This live CT203 controller source deployment and controller restart was explicitly approved with:

```
APPROVE_FC_O45_E_BP2_DEPLOY_CT203_COMPANION_REAL_MODEL_ROUTING_AND_RESTART_CONTROLLER
```

## Scope

Allowed and performed:

- Copied repo `edge_controller.py` to PVEW staging.
- Verified staged source SHA-256.
- Located CT203 live `edge_controller.py` from the 7070 Python process working directory or fallback paths.
- Backed up the CT203 live source.
- Replaced only CT203 live `edge_controller.py`.
- Ran Python compile checks.
- Restarted `edge-queue-controller.service`.
- Verified controller service returned active.
- Ran read-only post-restart API/source/DB checks.

Explicitly not allowed and not performed:

- NO public `/var/www` mutation.
- NO DB write.
- NO job mutation.
- NO result insert.
- NO model/helper/Ollama generation call.
- NO scheduler activation.
- NO timer activation.
- NO persistent worker activation.
- NO nginx/cloudflared config mutation.
- NO sshd config mutation.
- NO CT/VM restart.
- NO storage mutation.
- NO file deletion except replacing one approved CT203 source file via `install`.

## Expected runtime behavior

New queued Companion jobs should now use:

```
requested_model=qwen2.5:0.5b
```

instead of:

```
requested_model=mock/no-model
```

Existing queued mock/no-model jobs are not changed by BP2-R2.

## Next steps

1. Submit one fresh Companion message in the browser.
2. Verify the new job has `requested_model=qwen2.5:0.5b`.
3. Run BQ as a bounded one-job Companion worker/model proof.

BQ requires explicit approval because it will claim a job and call the model/helper path.

## Output

```
=== Stage 16 FC-O45-E-BP2-R2 deploy CT203 Companion real-model routing and restart controller ===
APPROVAL=APPROVE_FC_O45_E_BP2_DEPLOY_CT203_COMPANION_REAL_MODEL_ROUTING_AND_RESTART_CONTROLLER
MUTATION_SCOPE=ct203_backend_source_file_replace_backup_compile_restart_controller_plus_repo_doc_smoke_commit_tag_push
FIX=robust_live_source_locator_from_7070_python_process_cwd
ALLOWED: copy repo edge_controller.py to PVEW staging
ALLOWED: backup CT203 live edge_controller.py
ALLOWED: replace CT203 live edge_controller.py only
ALLOWED: python compile check on CT203
ALLOWED: restart edge-queue-controller.service on CT203
ALLOWED: read-only post-restart status/API/source/DB checks
NO public /var/www mutation
NO DB write
NO job mutation
NO result insert
NO model/helper/Ollama generation call
NO scheduler activation
NO timer activation
NO persistent worker activation
NO nginx/cloudflared config mutation
NO sshd config mutation
NO CT/VM restart
NO storage mutation
NO file deletion except replacing one approved CT203 source file via install

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=e5016d6
head_now=e5016d6
origin_main_now=e5016d6
git_preflight=PASS

=== local source safety checks ===
local_source_real_model_routing_check=PASS
local_edge_controller_sha256=008b11765b7e677e13b1053afcf48046b0d411c03080128d7920b32542887088

=== copy source to PVEW staging ===
pvew_stage_copy=PASS

=== deploy to CT203 and restart controller ===
--- PVEW staging verification ---
pvew
2026-06-25T02:26:53Z
pvew_staged_sha256=008b11765b7e677e13b1053afcf48046b0d411c03080128d7920b32542887088
pvew_stage_verify=PASS

--- CT203 locate live source, robust ---
status: running
candidate_pid=13158 cwd=/opt/edge-queue-controller/releases/head-a39021f
ct203_live_source=/opt/edge-queue-controller/releases/head-a39021f/edge_controller.py

--- CT203 pre-deploy source and service state ---
controller_service_before=active
controller_enabled_before=enabled
live_sha256_before=1a6b5aa3227ed4561717c7043ab23c224635f33985aea2145063330f59d31c62
5656:_CHAT_QUEUED_MOCK_MODEL = "mock/no-model"
5657:_CHAT_QUEUED_JOB_TYPE = "companion.chat"
5705:        "intent": _CHAT_QUEUED_JOB_TYPE,
5708:        "job_type": _CHAT_QUEUED_JOB_TYPE,
5710:        "requested_model": _CHAT_QUEUED_MOCK_MODEL,
5741:                _CHAT_QUEUED_JOB_TYPE,
5743:                _CHAT_QUEUED_MOCK_MODEL,
5777:                _CHAT_QUEUED_JOB_TYPE,
5828:@app.post("/api/chat/queued")
19325:@app.post("/api/chat/queued")

--- CT203 install source with backup ---
ct203_staged_sha256=008b11765b7e677e13b1053afcf48046b0d411c03080128d7920b32542887088
ct203_staged_source_routing_check=PASS
backup_dir=/opt/edge-queue-controller/backups/stage-16-fc-o45-e-bp2-r2-20260625T022656Z
backup_sha256 1a6b5aa3227ed4561717c7043ab23c224635f33985aea2145063330f59d31c62  /opt/edge-queue-controller/backups/stage-16-fc-o45-e-bp2-r2-20260625T022656Z/edge_controller.py.pre-bp2-r2
live_sha256_after_install 008b11765b7e677e13b1053afcf48046b0d411c03080128d7920b32542887088  /opt/edge-queue-controller/releases/head-a39021f/edge_controller.py
ct203_source_install=PASS

--- CT203 restart controller service ---
controller_service_after=active
controller_enabled_after=enabled
ct203_controller_restart=PASS

--- CT203 post-restart verify source, API, DB read-only ---
post_live_sha256=008b11765b7e677e13b1053afcf48046b0d411c03080128d7920b32542887088
5656:_CHAT_QUEUED_MOCK_MODEL = "mock/no-model"
5657:_CHAT_QUEUED_REAL_MODEL = (
5658:    os.environ.get("EDGE_COMPANION_CHAT_REQUESTED_MODEL", "qwen2.5:0.5b").strip()
5661:_CHAT_QUEUED_JOB_TYPE = "companion.chat"
5709:        "intent": _CHAT_QUEUED_JOB_TYPE,
5712:        "job_type": _CHAT_QUEUED_JOB_TYPE,
5714:        "requested_model": _CHAT_QUEUED_REAL_MODEL,
5745:                _CHAT_QUEUED_JOB_TYPE,
5747:                _CHAT_QUEUED_REAL_MODEL,
5781:                _CHAT_QUEUED_JOB_TYPE,
5832:@app.post("/api/chat/queued")
19329:@app.post("/api/chat/queued")
listening_ports:
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                                              
LISTEN 0      2048         0.0.0.0:7070      0.0.0.0:*    users:(("python",pid=13726,fd=14))                  
LISTEN 0      100        127.0.0.1:25        0.0.0.0:*    users:(("master",pid=235,fd=12))                    
LISTEN 0      100            [::1]:25           [::]:*    users:(("master",pid=235,fd=13))                    
LISTEN 0      4096               *:22              *:*    users:(("sshd",pid=87,fd=3),("systemd",pid=1,fd=56))
ct203_http port=7070 path=/system/status code=200
{"ok":true,"checked_at":"2026-06-25T02:27:00.702294+00:00","overall_state":"online","services":[{"id":"study-api","name":"Study API","state":"online","checked_at":"2026-06-25T02:27:00.702294+00:00","detail":"Study tools are available."},{"id":"companion-api","name":"Companion API","state":"online","checked_at":"2026-06-25T02:27:00.702294+00:00","detail":"Companion chat and context support are available."},{"id":"profile-api","name":"Profile API","state":"online","checked_at":"2026-06-25T02:27:00.702294+00:00","detail":"Account profile, preferences, and user settings are available."},{"id":"calendar-integrations","name":"Calendar Integrations","state":"planned","checked_at":"2026-06-25T02:27:00.702294+00:00","detail":"Calendar connections are planned for a future release."},{"id":"images-api","name":"Images API","state":"planned","checked_at":"2026-06-25T02:27:00.702294+00:00","detail":"Image generation features are planned for a future release."}],"normalized":{"schema_version":2,"platform":[{"id":"study-api","name":"Study API","state":"online"},{"id":"companion-api","name":"Companion API","state":"online"},{"id":"profile-api","name":"Profile API","state":"online"},{"id":"calendar-
ct203_http port=7070 path=/api/system/status code=404
{"detail":"Not Found"}
ct203_http port=7070 path=/internal/edge-worker/summary code=401
{"detail":"Missing internal worker token."}
post_companion_model_status_counts_json=[{"requested_model": "mock/no-model", "status": "completed", "n": 3}, {"requested_model": "mock/no-model", "status": "failed", "n": 1}, {"requested_model": "mock/no-model", "status": "queued", "n": 440}, {"requested_model": "qwen2.5:0.5b", "status": "completed", "n": 5}]
post_recent_companion_jobs_json=[{"id": 570, "job_type": "companion.chat", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "created_at": "2026-06-25T02:16:12.718709+00:00", "updated_at": "2026-06-25T02:16:12.718709+00:00", "user_id": 16}, {"id": 569, "job_type": "companion.chat", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "created_at": "2026-06-25T01:43:16.805622+00:00", "updated_at": "2026-06-25T01:43:16.805622+00:00", "user_id": 16}, {"id": 568, "job_type": "companion.chat", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "created_at": "2026-06-25T01:36:29.420762+00:00", "updated_at": "2026-06-25T01:36:29.420762+00:00", "user_id": 16}, {"id": 567, "job_type": "companion.chat", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "created_at": "2026-06-25T01:15:17.603874+00:00", "updated_at": "2026-06-25T01:15:17.603874+00:00", "user_id": 16}, {"id": 566, "job_type": "companion.chat", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "created_at": "2026-06-25T01:15:17.592859+00:00", "updated_at": "2026-06-25T01:15:17.592859+00:00", "user_id": 16}, {"id": 565, "job_type": "companion.chat", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "created_at": "2026-06-25T01:15:17.580188+00:00", "updated_at": "2026-06-25T01:15:17.580188+00:00", "user_id": 16}, {"id": 564, "job_type": "companion.chat", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "created_at": "2026-06-25T01:15:17.568611+00:00", "updated_at": "2026-06-25T01:15:17.568611+00:00", "user_id": 16}, {"id": 563, "job_type": "companion.chat", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "created_at": "2026-06-25T01:15:17.557061+00:00", "updated_at": "2026-06-25T01:15:17.557061+00:00", "user_id": 16}]

BP2_R2_CT203_DEPLOY_RESTART_RECORDED=PASS

=== BP2-R2 conclusion ===
BP2_R2_DEPLOY_RESTART_RECORDED=PASS
LIVE_CT203_SOURCE_NOW_DEFAULTS_COMPANION_TO=qwen2.5:0.5b
NEXT_MANUAL_BROWSER_STEP=submit_one_new_companion_message_to_create_fresh_job
NEXT_AUTOMATED_STEP=verify_fresh_job_requested_model_qwen25_then_BQ_bounded_worker_proof
```
