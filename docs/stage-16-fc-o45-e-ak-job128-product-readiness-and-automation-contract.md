# Stage 16 FC-O45-E-AK — Job128 Product Readiness + Automation Contract

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `272cba1`
- Prior tag: `controller-stage-16-fc-o45-e-aj-exact-one-companion-persona-model-job-2026-06-24`
- Target job: `128`

## Purpose

AJ proved that the real-model Companion path can produce product-quality output when the Companion persona wrapper is applied.

AK is a read-only product-readiness checkpoint that records:

1. public result-reader surface is still present,
2. unauthenticated job-result access remains protected,
3. job `128` remains completed with exactly one result row,
4. result quality is still `quality_pass=true`,
5. the remaining productization gap is automation, not basic runtime or prompt quality.

## Scope

Allowed:

- Read-only repo/source inspection.
- Read-only public static/result-reader marker fetch.
- Read-only unauthenticated endpoint guard check.
- Read-only CT203 DB verification for job `128`.
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

## Product readiness result

Job `128`:

- `user_id=16`
- `status=completed`
- `job_type=companion.chat`
- `requested_model=qwen2.5:0.5b`
- `attempts=1`
- `result_rows=1`
- result: `Hello! How can I assist you today?`
- quality flags: `none`
- quality pass: `true`

This is the first product-quality exact-one Companion real-model result.

## Current product status

Proven:

```
signed-in submit path can create a companion/chat queue job
result-reader can display completed owned jobs
exact-one real-model path can complete one companion.chat job
persona wrapper can produce product-quality output
```

Not yet productized:

```
normal signed-in submit -> automatic bounded worker completion -> result-reader display
```

Completion still required manual bounded orchestration during the proof. Do not treat persistent or automatic worker completion as complete yet.

## Next recommended phase

Run `FC-O45-E-AL` as a no-runtime automation design contract.

It should define the safest path for:

- exact one-job foreground completion behind normal Companion submit,
- use of the Companion persona wrapper in the actual worker/runtime path,
- owner-scoped result-reader compatibility,
- no scheduler/timer/persistent worker activation yet,
- no broad queue draining,
- no model pull/download,
- explicit approval before any runtime or deploy.

Suggested approval boundary for later runtime:

```
APPROVE_FC_O45_E_AM_EXACT_ONE_SUBMIT_TO_PERSONA_WORKER_RESULT
```

## Live read-only output

```
=== Stage 16 FC-O45-E-AK job128 product-readiness + automation contract ===
MUTATION_SCOPE=read_only_product_readiness_verification_plus_repo_doc_smoke_commit_tag_push
TARGET_JOB_ID=128
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
expected_head=272cba1
head_now=272cba1
origin_main_now=272cba1
git_preflight=PASS

=== public Companion/result-reader markers, read-only ===
public_root_http=200
public_app_js_http=200
public_unauth_job128_http=401
public_unauth_job128_body_head
{"detail":"Missing bearer token."}
public_app_js_markers
// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
              Messages continue through /api/chat/queued. The page polls the existing job status endpoint and displays the final assistant reply without changing backend behavior.
  // - queued job: "position / total"
    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
    queuedChatSetStatus("Creating queued job...");
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

PASS: unauthenticated job128 result endpoint is auth-protected.

=== source inventory for normal submit and automation gap, read-only ===
frontend/study-ui/app.js:403:    el.innerHTML = "Review queue complete. Load another queue or change mode.";
frontend/study-ui/app.js:501:    $("passwordInput").autocomplete = mode === "register" ? "new-password" : "current-password";
frontend/study-ui/app.js:703:    companionAddMessage("assistant", "Review complete. Load another queue when you are ready.");
frontend/study-ui/app.js:1044:          if (["forwarded", "done", "complete", "completed", "succeeded", "success"].includes(String(status).toLowerCase()) && text) {
frontend/study-ui/app.js:1107:        body: { message: prompt, requested_model: "gemma4:e4b" },
frontend/study-ui/app.js:1115:        body: { job_type: "ollama_chat", prompt, requested_model: "gemma4:e4b" },
frontend/study-ui/study-content.partial.html:25:            <h2>Your personal AI learning platform</h2>
frontend/study-ui/index.html:55:            <h2>Your personal AI learning platform</h2>
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:99:          <input id="authEmail" type="email" autocomplete="email" required />
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:104:          <input id="authPassword" type="password" autocomplete="current-password" required />
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:159:      ["Profile", "Manage preferences, permissions, account settings, and future companion personalization.", "/profile"],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:208:      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:236:      "Profile will manage account settings, preferences, permissions, and personalization for the platform.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:316: * - /ads/reward/* = controller-owned rewarded ad claims
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2001:async function claimGoogleRewardedCredit(rewardPayload = {}) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2007:  if (!adRewardProvider()?.client_claim_enabled) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2008:    setGoogleRewardedMessage("Reward earned, but client credit claiming is disabled.");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2018:  const result = await api("/ads/reward/claim", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2043:      ? "Reward was already claimed. Your balance is up to date."
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2044:      : `Reward claimed. ${granted} free credits added.`
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2060:  if (!adRewardStatus?.can_claim) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2117:          if (adRewardProvider()?.client_claim_enabled) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2119:              await claimGoogleRewardedCredit(event?.payload || {});
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2121:              setGoogleRewardedMessage(err.message || "Reward earned, but credit claim failed.");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2124:            setGoogleRewardedMessage("Reward earned in browser test. Credit claiming is still disabled until final verification is enabled.");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2181:  if (status.can_claim) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2184:      detail: status.blocked_reason || "Rewarded ad claim is available.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2219:    detail: status.blocked_reason || "Rewarded ad claim is not available yet.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2353:            <strong>${rewardProvider?.client_claim_enabled ? "Client claim enabled" : "Claim disabled"}</strong>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2361:              id="claimAdRewardBtn"
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2387:            ${safeText(googleRewardedMessage || "Credit claiming remains disabled until final verification is enabled.")}
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3366:    if (status === "complete" || status === "completed") {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3371:        detail: `job ${jobId} · ${result.model || job.requested_model || "model unknown"}`
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3416:        requested_model: "gemma4:e4b",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3535:    body: "Build decks, add cards, review by difficulty, and track progress over time. Once signed in, this page becomes your personal study dashboard.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3547:      ["Queued responses", "Messages are submitted as jobs and polled until complete."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3555:    body: "Profile centralizes account details, preferences, permissions, and future personalization settings.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3732:  $("claimAdRewardBtn")?.addEventListener("click", claimMockAdReward);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3848:async function claimMockAdReward() {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3854:  const button = $("claimAdRewardBtn");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3861:    const result = await api("/ads/reward/claim", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6323:    if (payload && payload.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6324:      cleanPayload.requested_model = String(payload.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6327:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6404:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6572:        hasModel: Boolean(context && context.requested_model),
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6621:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6622:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6663: * - builds only message, chat_id, and requested_model
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6694:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6695:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/index.html.bak-stage5o24-study-format-cleanup-2026-06-11-121612:99:          <input id="authEmail" type="email" autocomplete="email" required />
frontend/wrapper-ui/index.html.bak-stage5o24-study-format-cleanup-2026-06-11-121612:104:          <input id="authPassword" type="password" autocomplete="current-password" required />
frontend/wrapper-ui/index.html.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:99:          <input id="authEmail" type="email" autocomplete="email" required />
frontend/wrapper-ui/index.html.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:104:          <input id="authPassword" type="password" autocomplete="current-password" required />
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:159:      ["Profile", "Manage preferences, permissions, account settings, and future companion personalization.", "/profile"],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:208:      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:236:      "Profile will manage account settings, preferences, permissions, and personalization for the platform.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:316: * - /ads/reward/* = controller-owned rewarded ad claims
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2001:async function claimGoogleRewardedCredit(rewardPayload = {}) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2007:  if (!adRewardProvider()?.client_claim_enabled) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2008:    setGoogleRewardedMessage("Reward earned, but client credit claiming is disabled.");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2018:  const result = await api("/ads/reward/claim", {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2043:      ? "Reward was already claimed. Your balance is up to date."
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2044:      : `Reward claimed. ${granted} free credits added.`
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2060:  if (!adRewardStatus?.can_claim) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2117:          if (adRewardProvider()?.client_claim_enabled) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2119:              await claimGoogleRewardedCredit(event?.payload || {});
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2121:              setGoogleRewardedMessage(err.message || "Reward earned, but credit claim failed.");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2124:            setGoogleRewardedMessage("Reward earned in browser test. Credit claiming is still disabled until final verification is enabled.");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2181:  if (status.can_claim) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2184:      detail: status.blocked_reason || "Rewarded ad claim is available.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2219:    detail: status.blocked_reason || "Rewarded ad claim is not available yet.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2353:            <strong>${rewardProvider?.client_claim_enabled ? "Client claim enabled" : "Claim disabled"}</strong>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2361:              id="claimAdRewardBtn"
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2387:            ${safeText(googleRewardedMessage || "Credit claiming remains disabled until final verification is enabled.")}
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3366:    if (status === "complete" || status === "completed") {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3371:        detail: `job ${jobId} · ${result.model || job.requested_model || "model unknown"}`
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3416:        requested_model: "gemma4:e4b",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3535:    body: "Build decks, add cards, review by difficulty, and track progress over time. Once signed in, this page becomes your personal study dashboard.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3547:      ["Queued responses", "Messages are submitted as jobs and polled until complete."],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3555:    body: "Profile explains how account settings, privacy controls, permissions, and personalization will work after you sign in.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3670:        <strong>Account and personalization</strong>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3673:          personalization settings for the platform.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3841:  $("claimAdRewardBtn")?.addEventListener("click", claimMockAdReward);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3957:async function claimMockAdReward() {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3963:  const button = $("claimAdRewardBtn");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3970:    const result = await api("/ads/reward/claim", {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6432:    if (payload && payload.requested_model) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6433:      cleanPayload.requested_model = String(payload.requested_model);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6436:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6513:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6681:        hasModel: Boolean(context && context.requested_model),
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6730:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6731:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6772: * - builds only message, chat_id, and requested_model
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6803:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6804:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/dev_server.py:83:    if path == "/api/chat/queued" or path.startswith("/api/chat/queued/"):
frontend/wrapper-ui/dev_server.py:103:        "/api/ads/reward/claim": "/system/ads/reward/claim",
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
frontend/wrapper-ui/dev_server.py:663:        #   pollData.status === "complete" && pollData.assistant_message
frontend/wrapper-ui/dev_server.py:665:        # The laptop controller status route returns the completed job and
frontend/wrapper-ui/dev_server.py:667:        # for complete jobs with a non-empty reply. This does not write an
frontend/wrapper-ui/dev_server.py:671:        if assistant_message is None and out.get("status") == "complete":
frontend/wrapper-ui/dev_server.py:741:                laptop_payload["requested_model"] = str(ct101_payload.get("model"))
frontend/wrapper-ui/dev_server.py:755:                "/api/chat/queued",
frontend/wrapper-ui/dev_server.py:776:                f"/api/chat/queued/{job_id}",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:154:      ["Profile", "Manage preferences, permissions, account settings, and future companion personalization.", "/profile"],
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:203:      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:231:      "Profile will manage account settings, preferences, permissions, and personalization for the platform.",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:311: * - /ads/reward/* = controller-owned rewarded ad claims
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:1996:async function claimGoogleRewardedCredit(rewardPayload = {}) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2002:  if (!adRewardProvider()?.client_claim_enabled) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2003:    setGoogleRewardedMessage("Reward earned, but client credit claiming is disabled.");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2013:  const result = await api("/ads/reward/claim", {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2038:      ? "Reward was already claimed. Your balance is up to date."
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2039:      : `Reward claimed. ${granted} free credits added.`
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2055:  if (!adRewardStatus?.can_claim) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2112:          if (adRewardProvider()?.client_claim_enabled) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2114:              await claimGoogleRewardedCredit(event?.payload || {});
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2116:              setGoogleRewardedMessage(err.message || "Reward earned, but credit claim failed.");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2119:            setGoogleRewardedMessage("Reward earned in browser test. Credit claiming is still disabled until final verification is enabled.");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2176:  if (status.can_claim) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2179:      detail: status.blocked_reason || "Rewarded ad claim is available.",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2214:    detail: status.blocked_reason || "Rewarded ad claim is not available yet.",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2348:            <strong>${rewardProvider?.client_claim_enabled ? "Client claim enabled" : "Claim disabled"}</strong>
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2356:              id="claimAdRewardBtn"
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2382:            ${safeText(googleRewardedMessage || "Credit claiming remains disabled until final verification is enabled.")}
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3249:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3348:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3362:    if (status === "complete" || status === "completed") {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3367:        detail: `job ${jobId} · ${result.model || job.requested_model || "model unknown"}`
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3406:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3412:        requested_model: "gemma4:e4b",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3536:  $("claimAdRewardBtn")?.addEventListener("click", claimMockAdReward);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3652:async function claimMockAdReward() {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3658:  const button = $("claimAdRewardBtn");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3665:    const result = await api("/ads/reward/claim", {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6052:    if (payload && payload.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6053:      cleanPayload.requested_model = String(payload.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6056:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6133:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6301:        hasModel: Boolean(context && context.requested_model),
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6350:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6351:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6392: * - builds only message, chat_id, and requested_model
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6423:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6424:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/index.html.bak-stage5o29-support-public-summary-2026-06-11-122711:99:          <input id="authEmail" type="email" autocomplete="email" required />
frontend/wrapper-ui/index.html.bak-stage5o29-support-public-summary-2026-06-11-122711:104:          <input id="authPassword" type="password" autocomplete="current-password" required />
frontend/wrapper-ui/index.html.bak-stage5o30-support-public-override-2026-06-11-122836:99:          <input id="authEmail" type="email" autocomplete="email" required />
frontend/wrapper-ui/index.html.bak-stage5o30-support-public-override-2026-06-11-122836:104:          <input id="authPassword" type="password" autocomplete="current-password" required />
frontend/wrapper-ui/index.html.bak-stage7q-2026-06-12-135105:99:          <input id="authEmail" type="email" autocomplete="email" required />
frontend/wrapper-ui/index.html.bak-stage7q-2026-06-12-135105:104:          <input id="authPassword" type="password" autocomplete="current-password" required />
frontend/wrapper-ui/index.html.bak-stage5o31-force-support-public-summary-2026-06-11-122923:99:          <input id="authEmail" type="email" autocomplete="email" required />
frontend/wrapper-ui/index.html.bak-stage5o31-force-support-public-summary-2026-06-11-122923:104:          <input id="authPassword" type="password" autocomplete="current-password" required />
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:159:      ["Profile", "Manage preferences, permissions, account settings, and future companion personalization.", "/profile"],
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:208:      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:236:      "Profile will manage account settings, preferences, permissions, and personalization for the platform.",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:316: * - /ads/reward/* = controller-owned rewarded ad claims
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2001:async function claimGoogleRewardedCredit(rewardPayload = {}) {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2007:  if (!adRewardProvider()?.client_claim_enabled) {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2008:    setGoogleRewardedMessage("Reward earned, but client credit claiming is disabled.");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2018:  const result = await api("/ads/reward/claim", {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2043:      ? "Reward was already claimed. Your balance is up to date."
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2044:      : `Reward claimed. ${granted} free credits added.`
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2060:  if (!adRewardStatus?.can_claim) {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2117:          if (adRewardProvider()?.client_claim_enabled) {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2119:              await claimGoogleRewardedCredit(event?.payload || {});
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2121:              setGoogleRewardedMessage(err.message || "Reward earned, but credit claim failed.");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2124:            setGoogleRewardedMessage("Reward earned in browser test. Credit claiming is still disabled until final verification is enabled.");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2181:  if (status.can_claim) {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2184:      detail: status.blocked_reason || "Rewarded ad claim is available.",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2219:    detail: status.blocked_reason || "Rewarded ad claim is not available yet.",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2353:            <strong>${rewardProvider?.client_claim_enabled ? "Client claim enabled" : "Claim disabled"}</strong>
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2361:              id="claimAdRewardBtn"
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2387:            ${safeText(googleRewardedMessage || "Credit claiming remains disabled until final verification is enabled.")}
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3254:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3353:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3367:    if (status === "complete" || status === "completed") {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3372:        detail: `job ${jobId} · ${result.model || job.requested_model || "model unknown"}`
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3411:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3417:        requested_model: "gemma4:e4b",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3546:  $("claimAdRewardBtn")?.addEventListener("click", claimMockAdReward);
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3662:async function claimMockAdReward() {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3668:  const button = $("claimAdRewardBtn");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3675:    const result = await api("/ads/reward/claim", {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6083:    if (payload && payload.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6084:      cleanPayload.requested_model = String(payload.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6087:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6164:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6332:        hasModel: Boolean(context && context.requested_model),
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6381:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6382:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6423: * - builds only message, chat_id, and requested_model
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6454:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6455:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:159:      ["Profile", "Manage preferences, permissions, account settings, and future companion personalization.", "/profile"],
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:208:      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:236:      "Profile will manage account settings, preferences, permissions, and personalization for the platform.",
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:316: * - /ads/reward/* = controller-owned rewarded ad claims
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2001:async function claimGoogleRewardedCredit(rewardPayload = {}) {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2007:  if (!adRewardProvider()?.client_claim_enabled) {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2008:    setGoogleRewardedMessage("Reward earned, but client credit claiming is disabled.");
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2018:  const result = await api("/ads/reward/claim", {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2043:      ? "Reward was already claimed. Your balance is up to date."
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2044:      : `Reward claimed. ${granted} free credits added.`
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2060:  if (!adRewardStatus?.can_claim) {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2117:          if (adRewardProvider()?.client_claim_enabled) {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2119:              await claimGoogleRewardedCredit(event?.payload || {});
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2121:              setGoogleRewardedMessage(err.message || "Reward earned, but credit claim failed.");
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2124:            setGoogleRewardedMessage("Reward earned in browser test. Credit claiming is still disabled until final verification is enabled.");
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2181:  if (status.can_claim) {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2184:      detail: status.blocked_reason || "Rewarded ad claim is available.",
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2219:    detail: status.blocked_reason || "Rewarded ad claim is not available yet.",
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2353:            <strong>${rewardProvider?.client_claim_enabled ? "Client claim enabled" : "Claim disabled"}</strong>
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2361:              id="claimAdRewardBtn"
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2387:            ${safeText(googleRewardedMessage || "Credit claiming remains disabled until final verification is enabled.")}
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3259:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3358:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3372:    if (status === "complete" || status === "completed") {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3377:        detail: `job ${jobId} · ${result.model || job.requested_model || "model unknown"}`
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3416:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3422:        requested_model: "gemma4:e4b",
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3551:  $("claimAdRewardBtn")?.addEventListener("click", claimMockAdReward);
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3667:async function claimMockAdReward() {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3673:  const button = $("claimAdRewardBtn");
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3680:    const result = await api("/ads/reward/claim", {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6092:    if (payload && payload.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6093:      cleanPayload.requested_model = String(payload.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6096:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6173:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6341:        hasModel: Boolean(context && context.requested_model),
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6390:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6391:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6432: * - builds only message, chat_id, and requested_model
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6463:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:6464:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:159:      ["Profile", "Manage preferences, permissions, account settings, and future companion personalization.", "/profile"],
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:208:      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:236:      "Profile will manage account settings, preferences, permissions, and personalization for the platform.",
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:316: * - /ads/reward/* = controller-owned rewarded ad claims
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2001:async function claimGoogleRewardedCredit(rewardPayload = {}) {
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2007:  if (!adRewardProvider()?.client_claim_enabled) {
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2008:    setGoogleRewardedMessage("Reward earned, but client credit claiming is disabled.");
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2018:  const result = await api("/ads/reward/claim", {
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2043:      ? "Reward was already claimed. Your balance is up to date."
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2044:      : `Reward claimed. ${granted} free credits added.`
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2060:  if (!adRewardStatus?.can_claim) {
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2117:          if (adRewardProvider()?.client_claim_enabled) {
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2119:              await claimGoogleRewardedCredit(event?.payload || {});
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2121:              setGoogleRewardedMessage(err.message || "Reward earned, but credit claim failed.");
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2124:            setGoogleRewardedMessage("Reward earned in browser test. Credit claiming is still disabled until final verification is enabled.");
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2181:  if (status.can_claim) {
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2184:      detail: status.blocked_reason || "Rewarded ad claim is available.",
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2219:    detail: status.blocked_reason || "Rewarded ad claim is not available yet.",
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2353:            <strong>${rewardProvider?.client_claim_enabled ? "Client claim enabled" : "Claim disabled"}</strong>
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2361:              id="claimAdRewardBtn"
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2387:            ${safeText(googleRewardedMessage || "Credit claiming remains disabled until final verification is enabled.")}
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:3366:    if (status === "complete" || status === "completed") {
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:3371:        detail: `job ${jobId} · ${result.model || job.requested_model || "model unknown"}`
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:3410:    const res = await fetch("/api/chat/queued", {

=== CT203 job128 product-readiness verification, read-only ===
--- pvew/ct posture ---
pvew
2026-06-24T23:23:25Z
status: running
status: stopped
status: running

--- CT203 read-only job/result verification ---
integrity_check=ok
job128_final=id=128,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
job128_result_text=Hello! How can I assist you today?
job128_quality_flags=none
job128_quality_pass=true
job128_product_readiness=pass
recent_companion_jobs
(128, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:13:13Z', '2026-06-24T23:13:15Z')
(127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')
(126, 16, 'completed', 'companion.chat', 'mock/no-model', 0, '2026-06-24T22:31:58.445392+00:00', '2026-06-24T22:34:56Z')
(125, 16, 'completed', 'companion.chat', 'mock/no-model', 0, '2026-06-24T22:00:53.760211+00:00', '2026-06-24T22:04:39Z')
(124, 16, 'completed', 'companion.chat', 'mock/no-model', 0, '2026-06-24T18:19:19.431330+00:00', '2026-06-24T18:35:54.132393+00:00')
(123, 16, 'failed', 'companion.chat', 'mock/no-model', 0, '2026-06-24T16:05:04.713762+00:00', '2026-06-24T18:14:29.053942+00:00')
(24, 16, 'queued', 'companion.chat', 'mock/no-model', 0, '2026-06-20T05:02:17.068028+00:00', '2026-06-20T05:02:17.068028+00:00')
recent_companion_result_counts
(128, 'completed', 'qwen2.5:0.5b', 1)
(127, 'completed', 'qwen2.5:0.5b', 1)
(126, 'completed', 'mock/no-model', 1)
(125, 'completed', 'mock/no-model', 1)
(124, 'completed', 'mock/no-model', 1)
(123, 'failed', 'mock/no-model', 0)
(24, 'queued', 'mock/no-model', 0)

--- final project worker/timer posture, read-only ---

=== AK conclusion ===
Job128 is the first exact-one real-model Companion persona proof with quality_pass=true.
Remaining productization gap: automate normal signed-in submit -> bounded worker completion -> result-reader display without manual DB/model orchestration.
```
