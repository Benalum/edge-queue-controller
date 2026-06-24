# Stage 16 FC-O45-E-AH — Job127 Result Reader + Quality Contract

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `08e01b2`
- Prior tag: `controller-stage-16-fc-o45-e-ag-r3-exact-one-companion-model-job-2026-06-24`
- Target job: `127`

## Purpose

AG-R3 proved exact-one real-model completion for a `companion.chat` job at the CT203 DB/result level.

AH records the read-only product follow-up:

1. Verify job `127` remains complete and owner-scoped in CT203.
2. Verify the public static Companion result-reader surface is present.
3. Record the response-quality issue from the real model output.
4. Define the next safe productization contract.

## Scope

Allowed:

- Read-only repo/source inspection.
- Read-only public static/result-reader marker fetch.
- Read-only unauthenticated endpoint guard check.
- Read-only CT203 DB verification for job `127`.
- Read-only worker/timer posture checks.
- Repo documentation, focused smoke, commit, tag, and push.

Explicitly not allowed and not performed:

- NO DB write.
- NO job mutation.
- NO result insert.
- NO model/helper/Ollama call.
- NO model generation.
- NO scheduler activation.
- NO timer activation.
- NO persistent worker activation.
- NO backend/frontend deploy.
- NO service restart/reload/start/stop/enable/disable.
- NO CT/VM restart.
- NO nginx/cloudflared/storage mutation.
- NO file deletion.

## AG-R3 runtime proof carried forward

Job `127`:

- `user_id=16`
- `status=completed`
- `job_type=companion.chat`
- `requested_model=qwen2.5:0.5b`
- `attempts=1`
- `result_rows=1`

Observed result:

```
I am Qwen, a powerful AI platform control companion created by Alibaba Cloud.
```

## Product-quality finding

The runtime chain worked, but the response is not yet product-quality Companion behavior.

Quality issue:

- The model identified itself as Qwen.
- The model referenced Alibaba Cloud.
- The model did not reliably follow the intended AI Platform Control Companion persona.

This means AG-R3 is valid as a real-model execution proof, but it should **not** be treated as final Companion UX quality.

## Next recommended phase

Run `FC-O45-E-AI` as a no-runtime prompt/persona wrapper contract.

The contract should design the safest next productization repair:

- normalize Companion system/developer prompt,
- suppress model/vendor self-identification,
- preserve safe refusal behavior,
- keep output short and user-facing,
- keep exact-one-job proof boundaries,
- use `qwen2.5:0.5b` only if already installed,
- avoid scheduler/timer/persistent worker activation,
- avoid frontend/backend deploy until the contract is reviewed.

## Live read-only output

```
=== Stage 16 FC-O45-E-AH job127 result-reader + quality contract ===
MUTATION_SCOPE=read_only_product_verification_plus_repo_doc_smoke_commit_tag_push
TARGET_JOB_ID=127
NO DB write
NO job mutation
NO result insert
NO model/helper/Ollama call
NO model generation
NO scheduler activation
NO timer activation
NO persistent worker activation
NO backend/frontend deploy
NO service restart/reload/start/stop/enable/disable
NO CT/VM restart
NO nginx/cloudflared/storage mutation
NO file deletion

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=08e01b2
head_now=08e01b2
origin_main_now=08e01b2
git_preflight=PASS

=== source/UI result-reader markers, read-only ===
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3428:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3431:      throw new Error("Queued job response did not include a job_id.");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6327:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6395:    const cleanJobId = String(jobId || "").trim();
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6397:    if (!cleanJobId) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6400:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6404:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6817:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6834:          id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6835:          job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6846:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6860:      job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3428:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3431:      throw new Error("Queued job response did not include a job_id.");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6436:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6504:    const cleanJobId = String(jobId || "").trim();
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6506:    if (!cleanJobId) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6509:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6513:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6926:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6943:          id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6944:          job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6955:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6969:      job_id: sendResult.job_id,
frontend/wrapper-ui/dev_server.py:83:    if path == "/api/chat/queued" or path.startswith("/api/chat/queued/"):
frontend/wrapper-ui/dev_server.py:290:        # session endpoint so direct /api/chat/queued can receive trusted
frontend/wrapper-ui/dev_server.py:425:            auth_source_path == "/api/chat/queued"
frontend/wrapper-ui/dev_server.py:426:            or auth_source_path.startswith("/api/chat/queued/")
frontend/wrapper-ui/dev_server.py:433:        # Direct browser queued-chat calls use /api/chat/queued, not the older
frontend/wrapper-ui/dev_server.py:438:            auth_source_path == "/api/chat/queued"
frontend/wrapper-ui/dev_server.py:439:            or auth_source_path.startswith("/api/chat/queued/")
frontend/wrapper-ui/dev_server.py:529:    #   GET  /api/backend/chats/{chat_id}/messages/jobs/{job_id}
frontend/wrapper-ui/dev_server.py:532:    #   POST /api/chat/queued
frontend/wrapper-ui/dev_server.py:533:    #   GET  /api/chat/queued/{job_id}
frontend/wrapper-ui/dev_server.py:578:            "/api/chat/queued",
frontend/wrapper-ui/dev_server.py:611:            if str(upstream_path or "").startswith("/api/chat/queued") and EDGE_TRUSTED_PROXY_SECRET:
frontend/wrapper-ui/dev_server.py:649:    def _stage5g9_transform_status_response(self, chat_id, job_id, data):
frontend/wrapper-ui/dev_server.py:658:        out.setdefault("job_id", job_id)
frontend/wrapper-ui/dev_server.py:699:                    assistant_id = f"{job_id}-assistant"
frontend/wrapper-ui/dev_server.py:755:                "/api/chat/queued",
frontend/wrapper-ui/dev_server.py:773:            job_id = status_match.group(2)
frontend/wrapper-ui/dev_server.py:776:                f"/api/chat/queued/{job_id}",
frontend/wrapper-ui/dev_server.py:783:                self._stage5g9_transform_status_response(chat_id, job_id, data),
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3249:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3348:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3406:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3424:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3427:      throw new Error("Queued job response did not include a job_id.");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6056:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6124:    const cleanJobId = String(jobId || "").trim();
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6126:    if (!cleanJobId) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6129:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6133:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6546:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6563:          id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6564:          job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6575:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6589:      job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3254:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3353:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3411:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3429:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3432:      throw new Error("Queued job response did not include a job_id.");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6087:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6155:    const cleanJobId = String(jobId || "").trim();
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6157:    if (!cleanJobId) {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6160:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6164:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6577:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6594:          id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6595:          job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6606:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6620:      job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3259:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3358:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3416:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3434:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3437:      throw new Error("Queued job response did not include a job_id.");
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6096:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6164:    const cleanJobId = String(jobId || "").trim();
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6166:    if (!cleanJobId) {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6169:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6173:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6586:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6603:          id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6604:          job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6615:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6629:      job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:3428:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:3431:      throw new Error("Queued job response did not include a job_id.");
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:6292:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:6360:    const cleanJobId = String(jobId || "").trim();
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:6362:    if (!cleanJobId) {
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:6365:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:6369:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:6782:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:6799:          id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:6800:          job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:6811:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:6825:      job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:3428:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:3431:      throw new Error("Queued job response did not include a job_id.");
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:6256:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:6324:    const cleanJobId = String(jobId || "").trim();
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:6326:    if (!cleanJobId) {
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:6329:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:6333:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:6746:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:6763:          id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:6764:          job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:6775:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:6789:      job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:3249:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:3348:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:3406:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:3424:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:3427:      throw new Error("Queued job response did not include a job_id.");
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:6056:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:6124:    const cleanJobId = String(jobId || "").trim();
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:6126:    if (!cleanJobId) {
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:6129:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:6133:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:6546:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:6563:          id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:6564:          job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:6575:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:6589:      job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:3254:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:3353:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:3411:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:3429:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:3432:      throw new Error("Queued job response did not include a job_id.");
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:6082:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:6150:    const cleanJobId = String(jobId || "").trim();
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:6152:    if (!cleanJobId) {
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:6155:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:6159:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:6572:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:6589:          id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:6590:          job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:6601:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:6615:      job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:3428:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:3431:      throw new Error("Queued job response did not include a job_id.");
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:6229:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:6297:    const cleanJobId = String(jobId || "").trim();
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:6299:    if (!cleanJobId) {
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:6302:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:6306:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:6719:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:6736:          id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:6737:          job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:6748:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:6762:      job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:3249:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:3348:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:3406:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:3424:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:3427:      throw new Error("Queued job response did not include a job_id.");
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:6056:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:6124:    const cleanJobId = String(jobId || "").trim();
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:6126:    if (!cleanJobId) {
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:6129:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:6133:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:6546:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:6563:          id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:6564:          job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:6575:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:6589:      job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:3428:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:3431:      throw new Error("Queued job response did not include a job_id.");
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:6265:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:6333:    const cleanJobId = String(jobId || "").trim();
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:6335:    if (!cleanJobId) {
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:6338:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:6342:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:6755:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:6772:          id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:6773:          job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:6784:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:6798:      job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:3254:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:3353:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:3411:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:3429:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:3432:      throw new Error("Queued job response did not include a job_id.");
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:6082:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:6150:    const cleanJobId = String(jobId || "").trim();
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:6152:    if (!cleanJobId) {
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:6155:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:6159:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:6572:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:6589:          id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:6590:          job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:6601:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:6615:      job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o30-support-public-override-2026-06-11-122836:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o30-support-public-override-2026-06-11-122836:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o30-support-public-override-2026-06-11-122836:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o30-support-public-override-2026-06-11-122836:3428:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage5o30-support-public-override-2026-06-11-122836:3431:      throw new Error("Queued job response did not include a job_id.");
frontend/wrapper-ui/app.js.bak-stage5o30-support-public-override-2026-06-11-122836:6261:    const response = await fetch("/api/chat/queued", {

=== public static result-reader marker check ===
public_root_http=200
public_app_js_http=200
public_root_markers
      <span class="brand-mark helper-logo" title="Study Companion Helper">
        <svg viewBox="0 0 64 64" role="img" aria-label="Study Companion Helper logo">
      <a href="/study" data-route="/study">Study</a>
      <a href="/companion" data-route="/companion">Companion</a>
        Login / Register
  <section id="authModal" class="auth-modal hidden" aria-label="Login and register dialog">
          <h2 id="authTitle">Login</h2>
        <button id="loginTabBtn" class="ghost-btn active" type="button">Login</button>
          Login
  <script src="/app.js?v=20260624fc045eader2"></script>
public_app_js_markers
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

=== public unauth result endpoint guard, read-only ===
public_unauth_job127_http=401
public_unauth_job127_body_head
{"detail":"Missing bearer token."}
PASS: unauthenticated public job endpoint is auth-protected.

=== CT203 job127 DB/result verification, read-only ===
--- pvew/ct posture ---
pvew
2026-06-24T23:07:22Z
status: running
status: stopped
status: running

--- CT203 read-only job/result verification ---
integrity_check=ok
job127_final=id=127,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
job127_result_text=I am Qwen, a powerful AI platform control companion created by Alibaba Cloud.
job127_quality_flags=model_identity_leakage_qwen,vendor_identity_leakage_alibaba,did_not_follow_companion_product_prompt
job127_runtime_proof_valid=true

--- final project worker/timer posture, read-only ---

=== AH conclusion ===
Job127 remains a valid exact-one real-model runtime proof.
The observed Qwen/Alibaba identity response is a product-quality issue, not a runtime-chain failure.
Next safe step: AI persona/prompt wrapper contract before more Companion productization runtime.
```
