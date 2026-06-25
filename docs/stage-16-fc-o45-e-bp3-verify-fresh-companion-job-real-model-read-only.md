# Stage 16 FC-O45-E-BP3 — Verify Fresh Companion Job Real Model Read-Only

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `b6d1a4d`
- Prior deploy tag: `controller-stage-16-fc-o45-e-bp2-r2-deploy-ct203-companion-real-model-routing-and-restart-controller-2026-06-24`

## Purpose

BP3 verifies that after BP2-R2, a fresh browser-submitted Companion job is created with:

```
requested_model=qwen2.5:0.5b
```

## Scope

Read-only runtime verification plus repo docs/smoke commit/tag only.

Explicitly not allowed and not performed:

- NO live deploy.
- NO source patch.
- NO public `/var/www` mutation.
- NO DB write.
- NO job mutation.
- NO result insert.
- NO model/helper/Ollama generation call.
- NO scheduler activation.
- NO timer activation.
- NO persistent worker activation.
- NO backend deploy.
- NO service restart/reload/start/stop/enable/disable.
- NO CT/VM restart.
- NO storage mutation.
- NO file deletion.

## Output

```
=== Stage 16 FC-O45-E-BP3 verify fresh Companion job real model read-only ===
MUTATION_SCOPE=read_only_runtime_verification_plus_repo_doc_smoke_commit_tag_push
GOAL=verify_new_companion_chat_job_after_BP2_uses_qwen25
NO live deploy
NO source patch
NO public /var/www mutation
NO DB write
NO job mutation
NO result insert
NO model/helper/Ollama generation call
NO scheduler activation
NO timer activation
NO persistent worker activation
NO backend deploy
NO service restart/reload/start/stop/enable/disable
NO CT/VM restart
NO storage mutation
NO file deletion

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=b6d1a4d
head_now=b6d1a4d
origin_main_now=b6d1a4d
git_preflight=PASS

=== CT203 read-only fresh Companion job verification ===
recent_companion_jobs_json=[{"id": 571, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence after BP2.", "requested_model": "qwen2.5:0.5b", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T02:29:36.806186+00:00", "updated_at": "2026-06-25T02:29:36.806186+00:00"}, {"id": 570, "user_id": 16, "job_type": "companion.chat", "prompt": "ask me how my day is in 1 sentence.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T02:16:12.718709+00:00", "updated_at": "2026-06-25T02:16:12.718709+00:00"}, {"id": 569, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:43:16.805622+00:00", "updated_at": "2026-06-25T01:43:16.805622+00:00"}, {"id": 568, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello i 1 sentence", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:36:29.420762+00:00", "updated_at": "2026-06-25T01:36:29.420762+00:00"}, {"id": 567, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence to me.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.603874+00:00", "updated_at": "2026-06-25T01:15:17.603874+00:00"}, {"id": 566, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence to me.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.592859+00:00", "updated_at": "2026-06-25T01:15:17.592859+00:00"}, {"id": 565, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence to me.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.580188+00:00", "updated_at": "2026-06-25T01:15:17.580188+00:00"}, {"id": 564, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence to me.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.568611+00:00", "updated_at": "2026-06-25T01:15:17.568611+00:00"}, {"id": 563, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence to me.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.557061+00:00", "updated_at": "2026-06-25T01:15:17.557061+00:00"}, {"id": 562, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence to me.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.544947+00:00", "updated_at": "2026-06-25T01:15:17.544947+00:00"}, {"id": 561, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence to me.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.532838+00:00", "updated_at": "2026-06-25T01:15:17.532838+00:00"}, {"id": 560, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence to me.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.509021+00:00", "updated_at": "2026-06-25T01:15:17.509021+00:00"}]
fresh_bp2_test_job_json={"id": 571, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence after BP2.", "requested_model": "qwen2.5:0.5b", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T02:29:36.806186+00:00", "updated_at": "2026-06-25T02:29:36.806186+00:00"}
BP3_FRESH_COMPANION_JOB_QWEN25_VERIFIED=PASS

BP3_READ_ONLY_VERIFICATION_RECORDED=PASS
NEXT_REQUIRED=BQ_bounded_one_job_worker_model_proof_with_explicit_approval
```
