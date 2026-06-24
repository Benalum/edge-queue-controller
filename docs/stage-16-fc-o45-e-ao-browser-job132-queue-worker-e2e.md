# Stage 16 FC-O45-E-AO — Browser Job132 Queue Worker E2E

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `6f9b7cd`
- Prior tag: `controller-stage-16-fc-o45-e-an-browser-job131-persona-worker-result-2026-06-24`

## Approval

This runtime phase was explicitly approved with:

```
APPROVE_FC_O45_E_AO_EXACT_ONE_BROWSER_JOB132_QUEUE_WORKER_E2E
```

## Scope

Allowed and performed:

- Targeted exactly one existing browser-created Companion queue job: `132`.
- Verified job `132` was owner-scoped to `user_id=16`.
- Verified job `132` had `job_type=companion.chat`.
- Verified job `132` was queued and had zero result rows before worker completion.
- Extracted the user message from the queued job record.
- Ran a transient exact-one queue worker path for only job `132`.
- Completed only job `132`.
- Used already-installed `qwen2.5:0.5b`.
- Applied the Companion persona wrapper in the model prompt.
- Inserted exactly one `job_results` row for job `132` only.
- Verified CT203 SQLite integrity after completion.
- Verified target job final state and result-row count.
- Classified persona quality flags honestly.
- Checked the public unauthenticated result endpoint guard for the completed target job.

Explicitly not allowed and not performed:

- NO new job creation.
- NO scheduler activation.
- NO timer activation.
- NO persistent worker activation.
- NO broad queue draining.
- NO old job mutation except exact target job `132`.
- NO backend/frontend deploy.
- NO service restart/reload/enable/disable.
- NO CT/VM restart.
- NO model pull/download.
- NO nginx/cloudflared/storage mutation.
- NO file deletion.

## Target job

```
132
```

## Creation method

```
browser_signed_in_ui_submit_existing_job_id
```

## Worker mode

```
transient_exact_one_queue_worker_e2e
```

This is a closer queue-to-worker proof than AN because the transient worker extracted the browser-created queued job's message from the queue record before completing the exact target.

## Quality result

```
quality_pass=true
quality_flags=none
```

If `quality_pass=true`, this proves:

```
normal browser signed-in submit
-> queued companion.chat job
-> transient exact-one queue worker reads that job
-> persona-wrapped real model completion
-> one product-quality result row
-> result-reader-compatible completed Companion job
```

## Manual browser verification

After this phase, the signed-in Companion result reader should be able to read job id:

```
132
```

## Live runtime output

```
=== Stage 16 FC-O45-E-AO browser job132 queue-worker E2E ===
APPROVAL=APPROVE_FC_O45_E_AO_EXACT_ONE_BROWSER_JOB132_QUEUE_WORKER_E2E
MUTATION_SCOPE=transient_exact_one_queue_worker_completion_for_existing_browser_job132_plus_repo_doc_smoke_commit_tag_push
ALLOWED: target only existing browser-created job id 132
ALLOWED: verify job 132 is owned by user_id=16, companion.chat, queued, and has zero result rows
ALLOWED: extract the user message from job 132 queue payload/columns
ALLOWED: complete only job 132 with transient exact-job worker logic
ALLOWED: use persona-wrapped qwen2.5:0.5b if already installed
ALLOWED: insert exactly one result row for job 132 only
ALLOWED: classify quality flags honestly
NO new job creation
NO scheduler activation
NO timer activation
NO persistent worker activation
NO broad queue draining
NO old job mutation except exact target job 132
NO backend/frontend deploy
NO service restart/reload/enable/disable
NO CT/VM restart
NO model pull/download
NO nginx/cloudflared/storage mutation
NO file deletion

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=6f9b7cd
head_now=6f9b7cd
origin_main_now=6f9b7cd
git_preflight=PASS

=== public result-reader marker check, read-only ===
public_root_http=200
public_app_js_http=200
public_unauth_job132_http=401
{"detail":"Missing bearer token."}
// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
              Messages continue through /api/chat/queued. The page polls the existing job status endpoint and displays the final assistant reply without changing backend behavior.
    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
    const res = await fetch("/api/chat/queued", {
    const response = await fetch("/api/chat/queued", {
    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
    if (!url || !String(url).includes("/api/chat/queued") || !response || !response.clone) return;
      '<p>Messages continue through <code>/api/chat/queued</code>. The page watches the same polling flow and displays queue state without changing backend behavior.</p>',
 * This is a UI-only smoke helper: it calls /api/companion/chat with the
 * FC-O45-E-Q no-enqueue validation header and displays queue_write=false.
      const response = await fetch("/api/companion/chat", {
      const ok = response.ok && data.auth_validated === true && data.queue_write === false;
          ? "PASS: signed-in Companion auth validated; queue_write=false."
    lines.push("PASS: Companion result read path returned a result.");
    lines.push("queue_write: " + String(data.queue_write));
      const response = await fetch("/api/companion/chat", {
    title.textContent = "Companion result reader";
public_unauth_job132_guard=PASS

=== approved transient exact-job queue worker via PVEW ===
--- pvew posture ---
pvew
2026-06-24T23:42:48Z
status: running
status: stopped
status: running

--- CT203 DB integrity and target job132 queue preflight, read-only ---
integrity_check=ok
jobs_by_status
('completed', 68)
('failed', 3)
('forwarded', 18)
('queued', 28)
('running', 10)
browser_target_before=id=132,user_id=16,status=queued,job_type=companion.chat,requested_model=mock/no-model,attempts=0,created_at=2026-06-24T23:38:02.199275+00:00,updated_at=2026-06-24T23:38:02.199275+00:00
browser_target_result_rows_before=0
browser_target_message=Hello! How can I assist you today?
browser_target_preflight=PASS
browser_target_message=Hello! How can I assist you today?

--- project worker/scheduler/timer active gate, read-only ---
ct203_project_worker_scheduler_timer_active_gate=PASS

--- PVESO route and project-worker active gate ---
pvew_to_pveso_ssh=PASS
pveso_project_worker_active_gate=PASS

--- model presence probe, no generation yet ---
pveso_hostname=pveso
pveso_ollama_service=active
ct101_status=status: running
pveso_host_models=qwen2.5-coder:32b-instruct-q4_K_M,qwen2.5:0.5b,qwen2.5:32b-instruct-q4_K_M
model_presence=pveso_host_ollama_api

--- transient exact-job worker claim: mark target running, attempts=1 ---
transient_exact_worker_claimed_job=132

--- transient exact-job worker model generation, already-installed model only ---
model_runtime=pveso_host_ollama_api
model_output_begin
Hello! Feel free to ask any questions or let me know how I can help today!
model_output_end

--- transient exact-job worker complete: one result row only ---
final_verify=id=132,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
target_message=Hello! How can I assist you today?
result_text=Hello! Feel free to ask any questions or let me know how I can help today!
quality_flags=none
quality_pass=true
creation_method=browser_signed_in_ui_submit_existing_job_id
worker_mode=transient_exact_one_queue_worker_e2e

--- final CT203 read-only verification ---
integrity_check=ok
target_final=id=132,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
target_result_text=Hello! Feel free to ask any questions or let me know how I can help today!
target_quality_flags=none
target_quality_pass=true

--- final posture: no project worker/scheduler/timer active ---

FC_O45_E_AO_RUNTIME_RECORDED target_job_id=132 requested_model=qwen2.5:0.5b worker_mode=transient_exact_one_queue_worker_e2e creation_method=browser_signed_in_ui_submit_existing_job_id marker=FC-O45-E-AO-20260624T234248Z-10216
```
