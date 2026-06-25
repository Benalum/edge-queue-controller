# Stage 16 FC-O45-E-BP-R3-R2 — Complete Companion Real-Model Routing Source No-Runtime

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `ed34ef1`
- Prior source tag: `controller-stage-16-fc-o45-e-bp-r2-companion-real-model-routing-source-no-runtime-2026-06-24`

## Purpose

BP-R3-R2 completes the BP-R2 source patch.

BP-R2 changed the queued Companion decision response to use:

```
_CHAT_QUEUED_REAL_MODEL
```

but one non-constant insert-path reference to:

```
_CHAT_QUEUED_MOCK_MODEL
```

remained. BP-R3-R2 replaces exactly one non-constant occurrence with:

```
_CHAT_QUEUED_REAL_MODEL
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

## Source behavior after BP-R3-R2

The mock constant remains for compatibility:

```
_CHAT_QUEUED_MOCK_MODEL = "mock/no-model"
```

Both active queued Companion source paths now use:

```
_CHAT_QUEUED_REAL_MODEL
```

The real model default remains:

```
EDGE_COMPANION_CHAT_REQUESTED_MODEL or qwen2.5:0.5b
```

## Important limitation

This is repo source only.

The live CT203 backend will not change until BP2 deploys the corrected source and restarts the controller.

## Next phase

```
FC-O45-E-BP2 — deploy corrected CT203 controller source and restart controller
```

Then:

```
FC-O45-E-BQ — bounded one-job Companion model-worker activation proof
```

BQ requires explicit approval because it will claim a job and call the model/helper path.

## Output

```
=== Stage 16 FC-O45-E-BP-R3-R2 complete Companion real-model routing source no-runtime ===
MUTATION_SCOPE=repo_source_docs_smoke_commit_tag_push_only
FIX=line_based_replace_exactly_one_non_constant_mock_model_occurrence
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
expected_head=ed34ef1
head_now=ed34ef1
origin_main_now=ed34ef1
git_preflight=PASS

=== source context before patch ===
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

=== apply line-based BP-R3-R2 patch ===
non_constant_mock_model_occurrences=1
candidate_line=5747:                _CHAT_QUEUED_MOCK_MODEL,
patched_line=5747
patched_non_constant_mock_model_to_real_model=PASS

=== source context after patch ===
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

=== syntax/source checks ===
PASS: BP-R3-R2 complete source routes decision and insert path to qwen2.5:0.5b

=== git diff ===
diff --git a/edge_controller.py b/edge_controller.py
index a4d1622..e02e3dd 100644
--- a/edge_controller.py
+++ b/edge_controller.py
@@ -5744,7 +5744,7 @@ def _chat_queued_create_mock_job(user_id, prompt, decision):
             (
                 _CHAT_QUEUED_JOB_TYPE,
                 prompt,
-                _CHAT_QUEUED_MOCK_MODEL,
+                _CHAT_QUEUED_REAL_MODEL,
                 "queued",
                 0,
                 now,

BP_R3_R2_SOURCE_PATCH_RECORDED=PASS
PATCHED_SOURCE=edge_controller.py
NEW_DEFAULT_COMPANION_MODEL=qwen2.5:0.5b
NEXT_REQUIRED=BP2_deploy_CT203_controller_source_and_restart
```
