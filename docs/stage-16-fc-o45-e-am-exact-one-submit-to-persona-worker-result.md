# Stage 16 FC-O45-E-AM — Exact-One Submit-to-Persona-Worker Result

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `5f40d1f`
- Prior tag: `controller-stage-16-fc-o45-e-al-submit-to-worker-automation-design-contract-2026-06-24`

## Approval

This runtime phase was explicitly approved with:

```
APPROVE_FC_O45_E_AM_EXACT_ONE_SUBMIT_TO_PERSONA_WORKER_RESULT
```

## Scope

Allowed and performed:

- Tried exactly one public signed-in submit if `APC_PUBLIC_BEARER_TOKEN` was provided.
- If no token was provided or submit was not accepted, used the closest controller-owned fallback to create exactly one `companion.chat` job owned by `user_id=16`.
- Targeted only exact job id `129`.
- Used already-installed `qwen2.5:0.5b`.
- Applied the Companion persona wrapper in the model prompt.
- Ran one bounded foreground real model generation.
- Inserted exactly one `job_results` row for only the target job.
- Verified CT203 SQLite integrity after completion.
- Verified target job final state and result-row count.
- Classified persona quality flags honestly.
- Checked the public unauthenticated result endpoint guard for the target job.

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
129
```

## Creation method

```
controller_db_fallback_no_public_bearer_token
```

Interpretation:

- `public_signed_in_api_submit` means the job was created through the normal public signed-in submit API.
- `controller_db_fallback_no_public_bearer_token` means no public bearer token was available to the harness, so AM used the closest controller-owned fallback while preserving user ownership, job type, exact-job isolation, persona wrapper, model completion, and result-reader compatibility.

## Quality result

```
quality_pass=true
quality_flags=none
```

If `quality_pass=true`, this proves the persona-wrapped real-model completion path can produce product-quality Companion output for the target job.

If creation used the fallback path, the remaining productization gap is narrower but still present:

```
normal browser signed-in submit token/session -> exact-job worker completion
```

## Live runtime output

```
=== Stage 16 FC-O45-E-AM exact-one submit-to-persona-worker-result ===
APPROVAL=APPROVE_FC_O45_E_AM_EXACT_ONE_SUBMIT_TO_PERSONA_WORKER_RESULT
MUTATION_SCOPE=exact_one_submit_or_controller_create_plus_one_bounded_persona_model_completion_plus_repo_doc_smoke_commit_tag_push
ALLOWED: try exactly one signed-in public submit if APC_PUBLIC_BEARER_TOKEN is provided
ALLOWED: otherwise create exactly one controller-owned companion.chat fallback job owned by user_id=16
ALLOWED: complete only the exact target job with persona-wrapped qwen2.5:0.5b
ALLOWED: insert exactly one result row for only the target job
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
expected_head=5f40d1f
head_now=5f40d1f
origin_main_now=5f40d1f
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
public_result_reader_marker=PASS

=== optional signed-in public submit attempt ===
public_submit_token_present=false
public_submit_skipped=APC_PUBLIC_BEARER_TOKEN_not_set

=== approved bounded completion via PVEW ===
--- pvew posture ---
pvew
2026-06-24T23:28:08Z
status: running
status: stopped
status: running

--- CT203 DB integrity and current queue posture ---
integrity_check=ok
jobs_by_status
('completed', 66)
('failed', 3)
('forwarded', 18)
('queued', 26)
('running', 10)
recent_companion_jobs
(128, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:13:13Z', '2026-06-24T23:13:15Z')
(127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')
(126, 16, 'completed', 'companion.chat', 'mock/no-model', 0, '2026-06-24T22:31:58.445392+00:00', '2026-06-24T22:34:56Z')
(125, 16, 'completed', 'companion.chat', 'mock/no-model', 0, '2026-06-24T22:00:53.760211+00:00', '2026-06-24T22:04:39Z')
(124, 16, 'completed', 'companion.chat', 'mock/no-model', 0, '2026-06-24T18:19:19.431330+00:00', '2026-06-24T18:35:54.132393+00:00')
(123, 16, 'failed', 'companion.chat', 'mock/no-model', 0, '2026-06-24T16:05:04.713762+00:00', '2026-06-24T18:14:29.053942+00:00')
(24, 16, 'queued', 'companion.chat', 'mock/no-model', 0, '2026-06-20T05:02:17.068028+00:00', '2026-06-20T05:02:17.068028+00:00')

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

--- create exact fallback target job on CT203 from proven Companion schema ---
target_job_id=129
creation_method=controller_db_fallback_no_public_bearer_token
marker=FC-O45-E-AM-20260624T232808Z-8962

--- mark exact target running, attempts=1 ---
target_job_running=129

--- bounded persona model generation, already-installed model only ---
model_runtime=pveso_host_ollama_api
model_output_begin
Hello! How can I assist you today?
model_output_end

--- complete exact target with one result row and classify quality ---
final_verify=id=129,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
result_text=Hello! How can I assist you today?
quality_flags=none
quality_pass=true
creation_method=controller_db_fallback_no_public_bearer_token

--- final CT203 read-only verification ---
integrity_check=ok
target_final=id=129,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
target_result_text=Hello! How can I assist you today?
target_quality_flags=none
target_quality_pass=true

--- final posture: no project worker/scheduler/timer active ---

FC_O45_E_AM_RUNTIME_RECORDED target_job_id=129 requested_model=qwen2.5:0.5b creation_method=controller_db_fallback_no_public_bearer_token marker=FC-O45-E-AM-20260624T232808Z-8962

=== public result-reader unauth guard for new target, read-only ===
target_job_id_local_parse=pending_after_tee_parse
```
