# Stage 16 FC-O45-E-AJ — Exact-One Companion Persona Model Job

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `b58da45`
- Prior tag: `controller-stage-16-fc-o45-e-ai-companion-persona-wrapper-contract-2026-06-24`

## Approval

This runtime phase was explicitly approved with:

```
APPROVE_FC_O45_E_AJ_EXACT_ONE_COMPANION_PERSONA_MODEL_JOB
```

## Scope

Allowed and performed:

- Created exactly one new CT203 `companion.chat` job owned by `user_id=16`.
- Targeted only that exact job id: `128`.
- Used already-installed `qwen2.5:0.5b`.
- Applied the Companion persona wrapper in the model prompt.
- Ran one bounded foreground real model generation.
- Inserted exactly one `job_results` row for only the target job.
- Verified CT203 SQLite integrity after completion.
- Verified target job final state and result-row count.
- Classified persona quality flags honestly.

Explicitly not allowed and not performed:

- NO scheduler activation.
- NO timer activation.
- NO persistent worker activation.
- NO broad queue draining.
- NO old job mutation.
- NO backend/frontend deploy.
- NO service restart/reload/enable/disable.
- NO CT/VM restart.
- NO model pull/download.
- NO nginx/cloudflared/storage mutation.
- NO file deletion.

## Target job

```
128
```

## Quality result

```
quality_pass=true
quality_flags=none
```

The result is recorded as product-quality only if `quality_pass=true`.

If `quality_pass=false`, AJ is still valid runtime evidence but should not be treated as final Companion UX quality.

## Live runtime output

```
=== Stage 16 FC-O45-E-AJ exact-one Companion persona model job ===
APPROVAL=APPROVE_FC_O45_E_AJ_EXACT_ONE_COMPANION_PERSONA_MODEL_JOB
MUTATION_SCOPE=exact_one_new_companion_chat_job_plus_one_bounded_persona_model_generation_plus_one_result_row_plus_repo_doc_smoke_commit_tag_push
ALLOWED: create exactly one new CT203 companion.chat job owned by user_id=16
ALLOWED: mark only that exact job running/completed/failed
ALLOWED: call already-installed qwen2.5:0.5b through bounded PVESO/CT101/Ollama path
ALLOWED: apply Companion persona wrapper in prompt
ALLOWED: insert exactly one job_results row for only that exact job
ALLOWED: classify quality flags honestly
NO scheduler activation
NO timer activation
NO persistent worker activation
NO broad queue draining
NO old job mutation
NO backend/frontend deploy
NO service restart/reload/enable/disable
NO CT/VM restart
NO model pull/download
NO nginx/cloudflared/storage mutation
NO file deletion

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=b58da45
head_now=b58da45
origin_main_now=b58da45
git_preflight=PASS

=== public result-reader marker check, read-only ===
public_root_http=200
public_app_js_http=200
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

=== approved bounded runtime via PVEW ===
--- pvew posture ---
pvew
2026-06-24T23:13:08Z
status: running
status: stopped
status: running

--- CT203 DB integrity and current queue posture ---
integrity_check=ok
jobs_by_status
('completed', 65)
('failed', 3)
('forwarded', 18)
('queued', 26)
('running', 10)
recent_companion_qwen_jobs
(127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')

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

--- create exact target job on CT203, copied from proven Companion schema ---
target_job_id=128
marker=FC-O45-E-AJ-20260624T231308Z-11260

--- mark exact target running, attempts=1 ---
target_job_running=128

--- bounded persona model generation, already-installed model only ---
model_runtime=pveso_host_ollama_api
model_output_begin
Hello! How can I assist you today?
model_output_end

--- complete exact target with one result row and classify quality ---
final_verify=id=128,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
result_text=Hello! How can I assist you today?
quality_flags=none
quality_pass=true

--- final CT203 read-only verification ---
integrity_check=ok
target_final=id=128,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
target_result_text=Hello! How can I assist you today?
target_quality_flags=none
target_quality_pass=true

--- final posture: no project worker/scheduler/timer active ---

FC_O45_E_AJ_RUNTIME_RECORDED target_job_id=128 requested_model=qwen2.5:0.5b marker=FC-O45-E-AJ-20260624T231308Z-11260

=== AJ local conclusion ===
The approved AJ phase completed exactly one Companion persona model job if the runtime recorded marker is present above.
Quality pass/fail is recorded in the output and documentation.
```
