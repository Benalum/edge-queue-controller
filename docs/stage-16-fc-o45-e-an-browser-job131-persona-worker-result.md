# Stage 16 FC-O45-E-AN — Browser Job131 Persona Worker Result

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `11d780a`
- Prior tag: `controller-stage-16-fc-o45-e-am-exact-one-submit-to-persona-worker-result-2026-06-24`

## Approval

This runtime phase was explicitly approved with:

```
APPROVE_FC_O45_E_AN_EXACT_ONE_BROWSER_JOB131_PERSONA_WORKER_RESULT
```

## Scope

Allowed and performed:

- Targeted exactly one existing browser-created Companion job: `131`.
- Verified job `131` was owner-scoped to `user_id=16`.
- Verified job `131` had `job_type=companion.chat`.
- Verified job `131` was queued and had zero result rows before completion.
- Completed only job `131`.
- Used already-installed `qwen2.5:0.5b`.
- Applied the Companion persona wrapper in the model prompt.
- Ran one bounded foreground real model generation.
- Inserted exactly one `job_results` row for job `131` only.
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
- NO old job mutation except exact target job `131`.
- NO backend/frontend deploy.
- NO service restart/reload/enable/disable.
- NO CT/VM restart.
- NO model pull/download.
- NO nginx/cloudflared/storage mutation.
- NO file deletion.

## Target job

```
131
```

## Creation method

```
browser_signed_in_ui_submit_existing_job_id
```

This closes the missing normal browser-submit bridge more strongly than AM because job `131` was created by the signed-in browser UI before this command ran.

## Quality result

```
quality_pass=true
quality_flags=none
```

If `quality_pass=true`, this proves:

```
normal browser signed-in submit
-> exact-job persona worker completion
-> one product-quality result row
-> result-reader-compatible completed Companion job
```

## Manual browser verification

After this phase, the signed-in Companion result reader should be able to read job id:

```
131
```

Expected visible result:

```
Hello! How can I assist you today?
```

## Live runtime output

```
=== Stage 16 FC-O45-E-AN browser job131 persona worker result ===
APPROVAL=APPROVE_FC_O45_E_AN_EXACT_ONE_BROWSER_JOB131_PERSONA_WORKER_RESULT
MUTATION_SCOPE=complete_exact_one_existing_browser_created_companion_job_131_plus_repo_doc_smoke_commit_tag_push
ALLOWED: target only existing browser-created job id 131
ALLOWED: verify job 131 is owned by user_id=16, companion.chat, queued, and has zero result rows
ALLOWED: complete only job 131 with persona-wrapped qwen2.5:0.5b
ALLOWED: insert exactly one result row for job 131 only
ALLOWED: classify quality flags honestly
NO new job creation
NO scheduler activation
NO timer activation
NO persistent worker activation
NO broad queue draining
NO old job mutation except exact target job 131
NO backend/frontend deploy
NO service restart/reload/enable/disable
NO CT/VM restart
NO model pull/download
NO nginx/cloudflared/storage mutation
NO file deletion

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=11d780a
head_now=11d780a
origin_main_now=11d780a
git_preflight=PASS

=== public result-reader marker check, read-only ===
public_root_http=200
public_app_js_http=200
public_unauth_job131_http=401
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
public_unauth_job131_guard=PASS

=== approved exact browser job completion via PVEW ===
--- pvew posture ---
pvew
2026-06-24T23:36:07Z
status: running
status: stopped
status: running

--- CT203 DB integrity and target job131 preflight, read-only ---
integrity_check=ok
jobs_by_status
('completed', 67)
('failed', 3)
('forwarded', 18)
('queued', 28)
('running', 10)
browser_target_before=id=131,user_id=16,status=queued,job_type=companion.chat,requested_model=mock/no-model,attempts=0,created_at=2026-06-24T23:32:44.758954+00:00,updated_at=2026-06-24T23:32:44.758954+00:00
browser_target_result_rows_before=0
browser_target_preflight=PASS

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

--- mark exact browser target running, attempts=1 ---
target_job_running=131

--- bounded persona model generation, already-installed model only ---
model_output_begin
Hello! How can I assist you today?
model_output_end

model_runtime=pveso_host_ollama_api
--- complete exact browser target with one result row and classify quality ---
final_verify=id=131,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
result_text=Hello! How can I assist you today?
quality_flags=none
quality_pass=true
creation_method=browser_signed_in_ui_submit_existing_job_id

--- final CT203 read-only verification ---
integrity_check=ok
target_final=id=131,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
target_result_text=Hello! How can I assist you today?
target_quality_flags=none
target_quality_pass=true

--- final posture: no project worker/scheduler/timer active ---

FC_O45_E_AN_RUNTIME_RECORDED target_job_id=131 requested_model=qwen2.5:0.5b creation_method=browser_signed_in_ui_submit_existing_job_id marker=FC-O45-E-AN-20260624T233607Z-22454
```
