# Stage 16 FC-O45-E-AG-R3 — Exact-One Companion Model Job

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `25d6f3f`
- Prior tag: `controller-stage-16-fc-o45-e-af-exact-one-job-model-proof-contract-2026-06-24`

## Approval

This runtime phase was explicitly approved with:

```
APPROVE_FC_O45_E_AG_EXACT_ONE_COMPANION_MODEL_JOB
```

## R3 note

AG-R1 failed before target job creation because a nested simple PVESO SSH probe consumed the PVEW here-doc stdin.

AG-R2 corrected simple SSH stdin handling and verified no prior AG target existed, but refused because the PVESO active-unit gate matched normal Proxmox host infrastructure service `pvescheduler.service`.

AG-R3 narrows the PVESO active-unit gate to project worker surfaces only:

```
edge-ct101
edge.*worker
exact-job
general-queue
worker@
```

## Scope

Allowed and performed:

- Created exactly one new CT203 `companion.chat` job owned by `user_id=16`.
- Targeted only that exact job id: `127`.
- Used approved small model `qwen2.5:0.5b`.
- Ran one bounded foreground real model generation path.
- Inserted exactly one `job_results` row for only the target job.
- Verified CT203 SQLite integrity after completion.
- Verified target job final state and result-row count.

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

## Result

The first bounded Companion real-model completion proof for a `companion.chat` job completed at the DB/result level.

Target job:

```
127
```

The signed-in Companion result-reader panel should now be able to read the same job id, because the previously proven result-reader path reads owner-scoped completed `companion.chat` rows from `job_results`.

## Live runtime output

```
=== Stage 16 FC-O45-E-AG-R3 exact-one Companion model job ===
APPROVAL=APPROVE_FC_O45_E_AG_EXACT_ONE_COMPANION_MODEL_JOB
R3_FIX=pveso_active_unit_gate_excludes_normal_proxmox_pvescheduler
MUTATION_SCOPE=exact_one_new_companion_chat_job_plus_one_bounded_model_generation_plus_one_result_row_plus_repo_doc_smoke_commit_tag_push
ALLOWED: create exactly one new CT203 companion.chat job owned by user_id=16
ALLOWED: mark only that exact job running/completed/failed
ALLOWED: call an already-installed qwen2.5:0.5b model through bounded PVESO/CT101/Ollama path
ALLOWED: insert exactly one job_results row for only that exact job
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
expected_head=25d6f3f
head_now=25d6f3f
origin_main_now=25d6f3f
git_preflight=PASS

=== approved bounded runtime via PVEW ===
--- pvew posture ---
pvew
2026-06-24T23:05:24Z
status: running
status: stopped
status: running

--- CT203 DB integrity and prior AG no-target verification ---
integrity_check=ok
jobs_by_status
('completed', 64)
('failed', 3)
('forwarded', 18)
('queued', 26)
('running', 10)
prior_ag_candidate_jobs

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
target_job_id=127
marker=FC-O45-E-AG-R3-20260624T230524Z-8728

--- mark exact target running, attempts=1 ---
target_job_running=127

--- bounded model generation, already-installed model only ---
model_runtime=pveso_host_ollama_api
model_output_begin
I am Qwen, a powerful AI platform control companion created by Alibaba Cloud.
model_output_end

--- complete exact target with one result row ---
final_verify=id=127,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
result_text=I am Qwen, a powerful AI platform control companion created by Alibaba Cloud.

--- final CT203 read-only verification ---
integrity_check=ok
target_final=id=127,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
target_result_row_present=1

--- final posture: no project worker/scheduler/timer active ---

FC_O45_E_AG_R3_RUNTIME_PASS target_job_id=127 requested_model=qwen2.5:0.5b marker=FC-O45-E-AG-R3-20260624T230524Z-8728

=== AG-R3 local conclusion ===
The approved AG-R3 phase completed the exact-one Companion model job if the runtime pass marker is present above.
Browser Companion result-reader verification can now target the printed target_job_id.
```
