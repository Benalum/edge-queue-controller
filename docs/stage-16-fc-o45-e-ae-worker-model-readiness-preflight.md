# Stage 16 FC-O45-E-AE — Worker/Model Readiness Preflight

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `b274ce9`
- Prior tag: `controller-stage-16-fc-o45-e-ad-g-r2-end-to-end-submit-result-reader-proof-job-126-2026-06-24`

## Scope

This was a bounded read-only readiness preflight after FC-O45-E-AD-G-R2.

Allowed:

- Read-only repo/source inspection.
- Read-only CT203 queue/result inventory.
- Read-only PVEW/CT203 service and timer posture inspection.
- Read-only PVESO/CT101 service, Docker, and filesystem model-manifest posture inspection.
- Repo documentation, focused smoke, commit, tag, and push.

Explicitly not allowed and not performed:

- NO DB write.
- NO job mutation.
- NO result insert.
- NO backend/frontend deploy.
- NO service restart/reload/start/stop/enable/disable.
- NO scheduler/timer activation.
- NO persistent worker activation.
- NO worker/helper/model/Ollama API call.
- NO model generation.
- NO CT/VM restart.
- NO nginx/cloudflared/storage mutation.

## Product status carried forward

FC-O45-E-AD-G-R2 proved the signed-in Companion product path:

```
submit -> queued job id -> result reader -> completed result display
```

That proof still ended with bounded manual mock/no-model completion. This preflight does not reclassify that as a real worker/model path.

## Recommended next approval-gated phase

Run `FC-O45-E-AF` only after reviewing this inventory.

Safest exact one-job proof path:

1. Insert or create exactly one `companion.chat` queued job owned by the signed-in test user, with a unique marker and a small approved model such as `qwen2.5:0.5b`.
2. Record the exact job id before any worker/model execution.
3. With explicit approval, run one bounded foreground worker/model path only for that exact job id.
4. Keep scheduler/timers/persistent workers disabled and inactive.
5. Allow at most one claim and one completion.
6. Use a strict timeout.
7. Verify CT203 DB read-only afterward:
   - target job status,
   - job owner,
   - requested model,
   - attempts,
   - exactly one result row.
8. Use the signed-in Companion result reader panel to read that same job id.
9. Commit/tag only the proof documentation and smoke artifacts after verification.

Decision gates before AF:

- If PVESO or CT101 is unreachable/offline, do not run model proof; first do a route/power/readiness-only checkpoint.
- If any scheduler/timer/persistent worker is unexpectedly active, do not run model proof; first diagnose and restore idle posture.
- If CT203 queue/result integrity is not `ok`, do not run model proof.
- If no existing bounded foreground worker can target one exact job id, write a contract phase first instead of improvising runtime behavior.

## Live read-only output

```
=== Stage 16 FC-O45-E-AE worker/model readiness preflight ===
MUTATION_SCOPE=read_only_runtime_inventory_plus_repo_doc_smoke_commit_tag_push
NO DB write
NO job mutation
NO result insert
NO backend/frontend deploy
NO service restart/reload/start/stop/enable/disable
NO scheduler/timer activation
NO persistent worker activation
NO worker/helper/model/Ollama API call
NO model generation
NO CT/VM restart
NO nginx/cloudflared/storage mutation

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=b274ce9
head_now=b274ce9
origin_main_now=b274ce9
git_preflight=PASS

=== local source route hints, read-only ===
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6327:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6404:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6436:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6513:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/dev_server.py:83:    if path == "/api/chat/queued" or path.startswith("/api/chat/queued/"):
frontend/wrapper-ui/dev_server.py:290:        # session endpoint so direct /api/chat/queued can receive trusted
frontend/wrapper-ui/dev_server.py:425:            auth_source_path == "/api/chat/queued"
frontend/wrapper-ui/dev_server.py:426:            or auth_source_path.startswith("/api/chat/queued/")
frontend/wrapper-ui/dev_server.py:433:        # Direct browser queued-chat calls use /api/chat/queued, not the older
frontend/wrapper-ui/dev_server.py:438:            auth_source_path == "/api/chat/queued"
frontend/wrapper-ui/dev_server.py:439:            or auth_source_path.startswith("/api/chat/queued/")
frontend/wrapper-ui/dev_server.py:532:    #   POST /api/chat/queued
frontend/wrapper-ui/dev_server.py:533:    #   GET  /api/chat/queued/{job_id}
frontend/wrapper-ui/dev_server.py:578:            "/api/chat/queued",
frontend/wrapper-ui/dev_server.py:611:            if str(upstream_path or "").startswith("/api/chat/queued") and EDGE_TRUSTED_PROXY_SECRET:
frontend/wrapper-ui/dev_server.py:755:                "/api/chat/queued",
frontend/wrapper-ui/dev_server.py:776:                f"/api/chat/queued/{job_id}",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3249:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3348:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3406:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6056:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6133:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3254:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3353:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3411:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6087:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6164:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3259:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3358:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3416:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6096:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6173:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:6292:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:6369:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:6256:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o29-support-public-summary-2026-06-11-122711:6333:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:3249:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:3348:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:3406:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:6056:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o10-remove-fresh-source-2026-06-11-110531:6133:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:3254:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:3353:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:3411:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:6082:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o17-study-shared-style-2026-06-11-120210:6159:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:6229:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:6306:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:3249:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:3348:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:3406:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:6056:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5n7-calendar-provider-only-2026-06-11-102043:6133:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:6265:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o31-force-support-public-summary-2026-06-11-122923:6342:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:3254:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:3353:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:3411:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:6082:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o16-credits-pill-nav-2026-06-11-120018:6159:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o30-support-public-override-2026-06-11-122836:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o30-support-public-override-2026-06-11-122836:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o30-support-public-override-2026-06-11-122836:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o30-support-public-override-2026-06-11-122836:6261:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o30-support-public-override-2026-06-11-122836:6338:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o14b-single-nav-router-2026-06-11-115530:3254:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o14b-single-nav-router-2026-06-11-115530:3353:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o14b-single-nav-router-2026-06-11-115530:3411:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o14b-single-nav-router-2026-06-11-115530:6082:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o14b-single-nav-router-2026-06-11-115530:6159:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o13-header-nav-state-2026-06-11-112822:3254:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o13-header-nav-state-2026-06-11-112822:3353:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o13-header-nav-state-2026-06-11-112822:3411:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o13-header-nav-state-2026-06-11-112822:6082:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o13-header-nav-state-2026-06-11-112822:6159:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o9-credits-fresh-2026-06-11-110356:3249:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o9-credits-fresh-2026-06-11-110356:3348:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o9-credits-fresh-2026-06-11-110356:3406:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o9-credits-fresh-2026-06-11-110356:6056:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o9-credits-fresh-2026-06-11-110356:6133:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage7q-2026-06-12-135105:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage7q-2026-06-12-135105:3374:              Messages continue through /api/chat/queued. The page polls the existing job status endpoint and displays the final assistant reply without changing backend behavior.
frontend/wrapper-ui/app.js.bak-stage7q-2026-06-12-135105:3550:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage7q-2026-06-12-135105:4398:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage7q-2026-06-12-135105:7529:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage7q-2026-06-12-135105:7606:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage7q-2026-06-12-135105:8801:    if (!url || !String(url).includes("/api/chat/queued") || !response || !response.clone) return;
frontend/wrapper-ui/app.js.bak-stage7q-2026-06-12-135105:9021:      '<p>Messages continue through <code>/api/chat/queued</code>. The page watches the same polling flow and displays queue state without changing backend behavior.</p>',
frontend/wrapper-ui/app.js.bak-stage5o12-clean-fresh-marker-2026-06-11-112327:3254:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o12-clean-fresh-marker-2026-06-11-112327:3353:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o12-clean-fresh-marker-2026-06-11-112327:3411:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o12-clean-fresh-marker-2026-06-11-112327:6082:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o12-clean-fresh-marker-2026-06-11-112327:6159:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o34-profile-polish-2026-06-11-124315:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o34-profile-polish-2026-06-11-124315:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o34-profile-polish-2026-06-11-124315:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o34-profile-polish-2026-06-11-124315:6436:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o34-profile-polish-2026-06-11-124315:6513:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o24-study-format-cleanup-2026-06-11-121612:3256:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o24-study-format-cleanup-2026-06-11-121612:3355:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o24-study-format-cleanup-2026-06-11-121612:3413:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o24-study-format-cleanup-2026-06-11-121612:6094:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o24-study-format-cleanup-2026-06-11-121612:6171:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o25-public-feature-gate-2026-06-11-121619:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o25-public-feature-gate-2026-06-11-121619:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o25-public-feature-gate-2026-06-11-121619:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o25-public-feature-gate-2026-06-11-121619:6092:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o25-public-feature-gate-2026-06-11-121619:6169:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o11-deep-route-reload-fix-2026-06-11-110737:3254:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o11-deep-route-reload-fix-2026-06-11-110737:3353:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o11-deep-route-reload-fix-2026-06-11-110737:3411:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o11-deep-route-reload-fix-2026-06-11-110737:6059:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o11-deep-route-reload-fix-2026-06-11-110737:6136:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o27-generic-public-gates-2026-06-11-121802:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o27-generic-public-gates-2026-06-11-121802:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o27-generic-public-gates-2026-06-11-121802:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o27-generic-public-gates-2026-06-11-121802:6214:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o27-generic-public-gates-2026-06-11-121802:6291:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-broken-stage5o14b-2026-06-11-115711:3260:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-broken-stage5o14b-2026-06-11-115711:3359:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-broken-stage5o14b-2026-06-11-115711:3417:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-broken-stage5o14b-2026-06-11-115711:6088:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-broken-stage5o14b-2026-06-11-115711:6165:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o23-study-layout-logo-unify-2026-06-11-121251:3251:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o23-study-layout-logo-unify-2026-06-11-121251:3350:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o23-study-layout-logo-unify-2026-06-11-121251:3408:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o23-study-layout-logo-unify-2026-06-11-121251:6080:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o23-study-layout-logo-unify-2026-06-11-121251:6157:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o26-complete-public-gates-2026-06-11-121702:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o26-complete-public-gates-2026-06-11-121702:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o26-complete-public-gates-2026-06-11-121702:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o26-complete-public-gates-2026-06-11-121702:6204:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o26-complete-public-gates-2026-06-11-121702:6281:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o20-admin-status-caller-2026-06-11-120835:3259:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o20-admin-status-caller-2026-06-11-120835:3358:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o20-admin-status-caller-2026-06-11-120835:3416:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o20-admin-status-caller-2026-06-11-120835:6092:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o20-admin-status-caller-2026-06-11-120835:6169:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js:3699:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js:3820:              Messages continue through /api/chat/queued. The page polls the existing job status endpoint and displays the final assistant reply without changing backend behavior.
frontend/wrapper-ui/app.js:4005:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js:5043:    const res = await fetch("/api/chat/queued", {

=== PVEW / CT203 queue-result-controller posture, read-only ===
--- pvew container/vm posture ---
pvew
status: running
status: stopped
status: running

--- ct203 controller/db posture ---
hostname=edge-controller-pvew
date_utc=2026-06-24T22:47:48Z

db_path=/var/lib/edge-queue-controller/edge_queue.sqlite3
-rw------- 1 root root 42M Jun 24 22:47 /var/lib/edge-queue-controller/edge_queue.sqlite3

sqlite_read_only_inventory
integrity_check
---------------
ok             
Runtime error near line 4: database is locked (5)
Runtime error near line 5: database is locked (5)
Runtime error near line 6: database is locked (5)
Runtime error near line 7: database is locked (5)
Runtime error near line 8: database is locked (5)
Runtime error near line 9: database is locked (5)
WARN: pvew_ct203_read_only_inventory_unavailable_or_nonzero

=== PVESO / CT101 model-worker posture, read-only and no Ollama API ===
ssh: Could not resolve hostname pveso: Temporary failure in name resolution
WARN: pveso_ct101_read_only_inventory_unavailable_or_nonzero

=== preflight conclusion ===
FC-O45-E-AE completed as read-only inventory only.
Next safest path should be an explicit-approval, exact-one-job, bounded foreground worker/model proof.
```
