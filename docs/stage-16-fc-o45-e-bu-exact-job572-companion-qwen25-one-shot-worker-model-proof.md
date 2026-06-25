# Stage 16 FC-O45-E-BU — Exact Job 572 Companion Qwen2.5 One-Shot Worker/Model Proof

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `82b91aa`
- Prior public static deploy tag: `controller-stage-16-fc-o45-e-bt-r2-deploy-companion-result-reader-refresh-restore-over-restricted-static-path-2026-06-24`

## Approval

This exact one-job worker/model proof was explicitly approved with:

```
APPROVE_FC_O45_E_BU_RUN_EXACT_JOB_572_COMPANION_QWEN25_ONE_SHOT_WORKER_MODEL_PROOF
```

## Purpose

BU proves the newly deployed Companion UI can submit a fresh job and the bounded one-shot model path can complete it.

Exact job:

```
job_id=572
job_type=companion.chat
requested_model=qwen2.5:0.5b
user_id=16
```

## Scope

Allowed and performed:

- Claimed exact queued job `572`.
- Called `qwen2.5:0.5b` through CT101 Docker/Ollama.
- Inserted one `job_results` row for job `572`.
- Completed exact job `572`.
- Recorded repo docs/smoke/commit/tag/push.

Explicitly not allowed and not performed:

- NO live deploy.
- NO source patch.
- NO public `/var/www` mutation.
- NO unrelated DB write.
- NO mutation of any job other than `572`.
- NO scheduler activation.
- NO timer activation.
- NO persistent worker activation.
- NO backend deploy.
- NO service restart/reload/start/stop/enable/disable.
- NO CT/VM restart.
- NO nginx/cloudflared/sshd config mutation.
- NO storage mutation.
- NO file deletion.

## Expected final state

```
job_id=572
status=completed
attempts=1
result_rows=1
model=qwen2.5:0.5b
```

## Output

```
=== Stage 16 FC-O45-E-BU exact job572 Companion qwen2.5 one-shot worker/model proof ===
APPROVAL=APPROVE_FC_O45_E_BU_RUN_EXACT_JOB_572_COMPANION_QWEN25_ONE_SHOT_WORKER_MODEL_PROOF
MUTATION_SCOPE=exact_job_572_claim_model_call_result_insert_complete_plus_repo_doc_smoke_commit_tag_push
ALLOWED: mutate exact job_id=572 only
ALLOWED: claim exact queued job_id=572
ALLOWED: call qwen2.5:0.5b through CT101 Docker/Ollama path
ALLOWED: insert one job_results row for job_id=572
ALLOWED: complete exact job_id=572
ALLOWED: if model call fails, mark exact job_id=572 failed to avoid stale running
NO live deploy
NO source patch
NO public /var/www mutation
NO unrelated DB write
NO mutation of any job other than 572
NO scheduler activation
NO timer activation
NO persistent worker activation
NO backend deploy
NO service restart/reload/start/stop/enable/disable
NO CT/VM restart
NO nginx/cloudflared/sshd config mutation
NO storage mutation
NO file deletion

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=82b91aa
head_now=82b91aa
origin_main_now=82b91aa
git_preflight=PASS

=== BU exact one-shot worker/model proof on PVEW/CT203/PVESO/CT101 ===
--- BU runtime preflight ---
pvew
2026-06-25T03:03:54Z
status: running
pveso
2026-06-25T03:03:55Z
status: running
ct101_hostname=llms
docker_active=active
ollama Up 34 hours (healthy)
NAME            ID              SIZE      MODIFIED    
qwen2.5:0.5b    a8b0c5157701    397 MB    2 days ago     
gemma3:4b       a2af6cc3eb7f    3.3 GB    12 days ago    
llama3.2:3b     a80c4f17acd5    2.0 GB    12 days ago    
qwen3:1.7b      8f68893c685c    1.4 GB    12 days ago    
qwen3:0.6b      7df6b6e09427    522 MB    12 days ago    
gemma4:e4b      c6eb396dbd59    9.6 GB    3 weeks ago    

--- exact claim queued job572 ---
pre_claim_json={"job": {"id": 572, "user_id": 16, "job_type": "companion.chat", "prompt": "ask how my day was in 1 sentence", "requested_model": "qwen2.5:0.5b", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T02:59:22.911717+00:00", "updated_at": "2026-06-25T02:59:22.911717+00:00"}, "result_rows": 0}
claim_json={"id": 572, "user_id": 16, "job_type": "companion.chat", "prompt": "ask how my day was in 1 sentence", "requested_model": "qwen2.5:0.5b", "status": "running", "attempts": 1, "last_error": null, "created_at": "2026-06-25T02:59:22.911717+00:00", "updated_at": "2026-06-25T03:03:57.464415+00:00"}
claimed_job_id=572
claimed_status=running
claimed_attempts=1
claimed_requested_model=qwen2.5:0.5b
prompt_len=32

--- create CT101 Docker/Ollama model caller ---
--- model call via CT101 Docker/Ollama container path ---
model_call_rc=0
model_response_preview_start
As an AI language model, I don't have personal experiences or memories like
like humans do. However, I'm here to assist you with any questions or infor
information you might need! If you'd like, feel free to ask about your day 
or anything else you want to know.
model_response_preview_end

--- complete exact job572 with one result row ---
pre_complete_job_json={"id": 572, "user_id": 16, "job_type": "companion.chat", "prompt": "ask how my day was in 1 sentence", "requested_model": "qwen2.5:0.5b", "status": "running", "attempts": 1, "last_error": null, "created_at": "2026-06-25T02:59:22.911717+00:00", "updated_at": "2026-06-25T03:03:57.464415+00:00"}
complete_json={"job": {"id": 572, "user_id": 16, "job_type": "companion.chat", "prompt": "ask how my day was in 1 sentence", "requested_model": "qwen2.5:0.5b", "status": "completed", "attempts": 1, "last_error": null, "created_at": "2026-06-25T02:59:22.911717+00:00", "updated_at": "2026-06-25T03:04:03.558939+00:00"}, "results": [{"job_id": 572, "model": "qwen2.5:0.5b", "response_text": "As an AI language model, I don't have personal experiences or memories like\nlike humans do. However, I'm here to assist you with any questions or infor\ninformation you might need! If you'd like, feel free to ask about your day \nor anything else you want to know.", "error": null, "created_at": "2026-06-25T03:04:03.558939+00:00", "updated_at": "2026-06-25T03:04:03.558939+00:00"}]}

--- final read-only verification exact job572 ---
final_job_json={"id": 572, "user_id": 16, "job_type": "companion.chat", "prompt": "ask how my day was in 1 sentence", "requested_model": "qwen2.5:0.5b", "status": "completed", "attempts": 1, "last_error": null, "created_at": "2026-06-25T02:59:22.911717+00:00", "updated_at": "2026-06-25T03:04:03.558939+00:00"}
final_results_json=[{"job_id": 572, "model": "qwen2.5:0.5b", "response_text": "As an AI language model, I don't have personal experiences or memories like\nlike humans do. However, I'm here to assist you with any questions or infor\ninformation you might need! If you'd like, feel free to ask about your day \nor anything else you want to know.", "error": null, "created_at": "2026-06-25T03:04:03.558939+00:00", "updated_at": "2026-06-25T03:04:03.558939+00:00"}]
BU_EXACT_JOB_572_COMPLETED_WITH_QWEN25_RESULT=PASS

BU_ONE_SHOT_WORKER_MODEL_PROOF_RECORDED=PASS

=== BU conclusion ===
BU_EXACT_JOB_572_WORKER_MODEL_PROOF_RECORDED=PASS
JOB_572_EXPECTED_FINAL=completed_attempts_1_result_rows_1_model_qwen2.5:0.5b
NEXT_REQUIRED=browser_poll_or_refresh_to_confirm_job572_reply_visible
```
