# Stage 16 FC-O45-E-BQ-R3 — Recover Job 571 via Docker Ollama Model Proof

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `39eb929`
- Prior verification tag: `controller-stage-16-fc-o45-e-bp3-verify-fresh-companion-job-real-model-read-only-2026-06-24`

## Approval

This exact job 571 recovery used the explicit approval:

```
APPROVE_FC_O45_E_BQ_RUN_EXACT_JOB_571_COMPANION_QWEN25_ONE_SHOT_WORKER_MODEL_PROOF
```

## Recovery reason

BQ claimed job `571`, but the first model call captured no response text. BQ-R2 safely marked the exact job failed after discovering that CT101 host loopback did not expose Ollama HTTP:

```
Connection refused on 127.0.0.1:11434
```

BQ-R3 recovered exact job `571` from:

```
status=failed
attempts=1
result_rows=0
```

and retried through the CT101 Docker/Ollama container path.

## Scope

Allowed and performed:

- Recovered exact job `571` from failed attempts=1.
- Moved exact job `571` to running attempts=2.
- Called `qwen2.5:0.5b` through CT101 Docker/Ollama.
- Inserted one `job_results` row for job `571`.
- Completed exact job `571`.
- Recorded repo docs/smoke/commit/tag/push.

Explicitly not allowed and not performed:

- NO live deploy.
- NO source patch.
- NO public `/var/www` mutation.
- NO unrelated DB write.
- NO mutation of any job other than `571`.
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
job_id=571
status=completed
attempts=2
result_rows=1
model=qwen2.5:0.5b
```

## Output

```
=== Stage 16 FC-O45-E-BQ-R3 recover job571 via Docker Ollama model proof ===
APPROVAL=APPROVE_FC_O45_E_BQ_RUN_EXACT_JOB_571_COMPANION_QWEN25_ONE_SHOT_WORKER_MODEL_PROOF
MUTATION_SCOPE=exact_job_571_failed_attempt1_recovery_model_call_result_insert_complete_plus_repo_doc_smoke_commit_tag_push
RECOVERY_FROM=BQ_R2_marked_job571_failed_after_CT101_host_loopback_ollama_connection_refused
ALLOWED: mutate exact job_id=571 only
ALLOWED: recover job_id=571 from failed attempts=1 to running attempts=2
ALLOWED: call qwen2.5:0.5b through CT101 Docker/Ollama path
ALLOWED: insert one job_results row for job_id=571
ALLOWED: complete exact job_id=571
ALLOWED: if recovery model call fails, mark exact job_id=571 failed to avoid stale running
NO live deploy
NO source patch
NO public /var/www mutation
NO unrelated DB write
NO mutation of any job other than 571
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
expected_head=39eb929
head_now=39eb929
origin_main_now=39eb929
git_preflight=PASS

=== BQ-R3 exact recovery on PVEW/CT203/PVESO/CT101 ===
--- BQ-R3 runtime preflight ---
pvew
2026-06-25T02:43:08Z
status: running
pveso
2026-06-25T02:43:09Z
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

--- exact job571 failed-state recovery claim ---
pre_recovery_claim_json={"job": {"id": 571, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence after BP2.", "requested_model": "qwen2.5:0.5b", "status": "failed", "attempts": 1, "last_error": "bq-r2 model_call_rc=1 empty_response=yes", "created_at": "2026-06-25T02:29:36.806186+00:00", "updated_at": "2026-06-25T02:39:26.701633+00:00"}, "result_rows": 0}
recovery_claim_json={"id": 571, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence after BP2.", "requested_model": "qwen2.5:0.5b", "status": "running", "attempts": 2, "last_error": null, "created_at": "2026-06-25T02:29:36.806186+00:00", "updated_at": "2026-06-25T02:43:11.745761+00:00"}
recovery_claimed_job_id=571
recovery_claimed_status=running
recovery_claimed_attempts=2
recovery_claimed_requested_model=qwen2.5:0.5b
prompt_len=34

--- create CT101 Docker/Ollama model caller ---
--- recovery model call via CT101 Docker/Ollama container path ---
model_call_rc=0
model_response_preview_start
Hello! I'm a text-based AI and don't have an immediate physical form like a
a human can. However, I'm always here to answer your questions or offer ass
assistance as needed. Please feel free to ask me anything you'd like to kno
know.
model_response_preview_end

--- complete exact job571 with one result row ---
pre_complete_job_json={"id": 571, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence after BP2.", "requested_model": "qwen2.5:0.5b", "status": "running", "attempts": 2, "last_error": null, "created_at": "2026-06-25T02:29:36.806186+00:00", "updated_at": "2026-06-25T02:43:11.745761+00:00"}
complete_json={"job": {"id": 571, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence after BP2.", "requested_model": "qwen2.5:0.5b", "status": "completed", "attempts": 2, "last_error": null, "created_at": "2026-06-25T02:29:36.806186+00:00", "updated_at": "2026-06-25T02:43:17.792838+00:00"}, "results": [{"job_id": 571, "model": "qwen2.5:0.5b", "response_text": "Hello! I'm a text-based AI and don't have an immediate physical form like a\na human can. However, I'm always here to answer your questions or offer ass\nassistance as needed. Please feel free to ask me anything you'd like to kno\nknow.", "error": null, "created_at": "2026-06-25T02:43:17.792838+00:00", "updated_at": "2026-06-25T02:43:17.792838+00:00"}]}

--- final read-only verification exact job571 ---
final_job_json={"id": 571, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence after BP2.", "requested_model": "qwen2.5:0.5b", "status": "completed", "attempts": 2, "last_error": null, "created_at": "2026-06-25T02:29:36.806186+00:00", "updated_at": "2026-06-25T02:43:17.792838+00:00"}
final_results_json=[{"job_id": 571, "model": "qwen2.5:0.5b", "response_text": "Hello! I'm a text-based AI and don't have an immediate physical form like a\na human can. However, I'm always here to answer your questions or offer ass\nassistance as needed. Please feel free to ask me anything you'd like to kno\nknow.", "error": null, "created_at": "2026-06-25T02:43:17.792838+00:00", "updated_at": "2026-06-25T02:43:17.792838+00:00"}]
BQ_R3_EXACT_JOB_571_COMPLETED_WITH_QWEN25_RESULT=PASS

BQ_R3_RECOVERY_WORKER_MODEL_PROOF_RECORDED=PASS

=== BQ-R3 conclusion ===
BQ_R3_EXACT_JOB_571_WORKER_MODEL_PROOF_RECORDED=PASS
JOB_571_EXPECTED_FINAL=completed_attempts_2_result_rows_1_model_qwen2.5:0.5b
NEXT_REQUIRED=browser_poll_or_refresh_to_confirm_assistant_reply_visible
```
