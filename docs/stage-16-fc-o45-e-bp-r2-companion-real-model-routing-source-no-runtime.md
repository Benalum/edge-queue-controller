# Stage 16 FC-O45-E-BP-R2 — Companion Real-Model Routing Source No-Runtime

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `104d77a`
- Prior pinpoint tag: `controller-stage-16-fc-o45-e-bo-r3-companion-real-model-routing-pinpoint-recovery-no-apply-2026-06-24`

## Purpose

BP-R2 patches repo source so new queued Companion jobs request a real approved model instead of the mock placeholder.

Before BP-R2, live evidence showed:

```
companion.chat requested_model=mock/no-model
```

BP-R2 changes the repo source default to:

```
qwen2.5:0.5b
```

## Scope

Modified repo source/docs/smoke only.

Explicitly not allowed and not performed:

- NO live deploy.
- NO CT203 runtime patch.
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

## Source behavior

BP-R2 targets only:

```
./edge_controller.py
```

It preserves the mock constant for compatibility but adds a real queued Companion default:

```
_CHAT_QUEUED_REAL_MODEL = EDGE_COMPANION_CHAT_REQUESTED_MODEL or qwen2.5:0.5b
```

Then the queued Companion decision uses:

```
"requested_model": _CHAT_QUEUED_REAL_MODEL
```

## Important limitation

This is repo source only.

The live CT203 backend will not change until a later approved backend deploy/runtime patch is performed.

## Next phases

Recommended:

```
FC-O45-E-BP2 — deploy/controller runtime patch for Companion real-model routing
FC-O45-E-BQ — bounded one-job Companion model-worker activation proof
```

BQ requires explicit approval because it will claim a job and call the model/helper path.

## Output

```
=== Stage 16 FC-O45-E-BP-R2 Companion real-model routing source no-runtime ===
MUTATION_SCOPE=repo_source_docs_smoke_commit_tag_push_only
FIX=target_repo_root_edge_controller_only_ignore_legacy_smoke_reference
GOAL=new_companion_chat_jobs_request_qwen25_instead_of_mock_no_model
NO live deploy
NO CT203 runtime patch
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
expected_head=104d77a
head_now=104d77a
origin_main_now=104d77a
git_preflight=PASS

=== source context before patch ===
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

=== apply BP-R2 source patch ===
patched_source=edge_controller.py
new_default_companion_model=qwen2.5:0.5b

=== source context after patch ===
5656:_CHAT_QUEUED_MOCK_MODEL = "mock/no-model"
5657:_CHAT_QUEUED_REAL_MODEL = (
5658:    os.environ.get("EDGE_COMPANION_CHAT_REQUESTED_MODEL", "qwen2.5:0.5b").strip()
5661:_CHAT_QUEUED_JOB_TYPE = "companion.chat"
5709:        "intent": _CHAT_QUEUED_JOB_TYPE,
5712:        "job_type": _CHAT_QUEUED_JOB_TYPE,
5714:        "requested_model": _CHAT_QUEUED_REAL_MODEL,
5745:                _CHAT_QUEUED_JOB_TYPE,
5747:                _CHAT_QUEUED_MOCK_MODEL,
5781:                _CHAT_QUEUED_JOB_TYPE,
5832:@app.post("/api/chat/queued")
19329:@app.post("/api/chat/queued")

=== syntax/source checks ===
PASS: BP-R2 edge_controller.py routes queued Companion decision to qwen2.5:0.5b by default

=== git diff ===
diff --git a/edge_controller.py b/edge_controller.py
index 04e3165..a4d1622 100644
--- a/edge_controller.py
+++ b/edge_controller.py
@@ -5654,6 +5654,10 @@ def _public_create_ollama_job(prompt: str, requested_model: str | None = None, u
 
 # STAGE_15_D_MOCK_QUEUED_CHAT_COMPAT_BEGIN
 _CHAT_QUEUED_MOCK_MODEL = "mock/no-model"
+_CHAT_QUEUED_REAL_MODEL = (
+    os.environ.get("EDGE_COMPANION_CHAT_REQUESTED_MODEL", "qwen2.5:0.5b").strip()
+    or "qwen2.5:0.5b"
+)
 _CHAT_QUEUED_JOB_TYPE = "companion.chat"
 
 
@@ -5707,7 +5711,7 @@ def _chat_queued_decision(user_id, prompt, metadata=None):
         "route_type": "queue_job",
         "job_type": _CHAT_QUEUED_JOB_TYPE,
         "model_tier": "medium",
-        "requested_model": _CHAT_QUEUED_MOCK_MODEL,
+        "requested_model": _CHAT_QUEUED_REAL_MODEL,
         "requires_confirmation": False,
         "reason": "mock queued companion compatibility; no model call",
         "model_call": "not_started",

BP_R2_SOURCE_PATCH_RECORDED=PASS
PATCHED_SOURCE=./edge_controller.py
NEW_DEFAULT_COMPANION_MODEL=qwen2.5:0.5b
NEXT_REQUIRED=deploy_controller_backend_or_runtime_config_then_bounded_worker_proof
```
