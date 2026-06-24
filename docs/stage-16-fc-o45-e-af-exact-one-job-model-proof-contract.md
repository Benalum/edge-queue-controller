# Stage 16 FC-O45-E-AF — Exact-One-Job Model Proof Contract

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `64bfabb`
- Prior tag: `controller-stage-16-fc-o45-e-ae-r2-db-lock-pveso-route-readiness-unblocker-2026-06-24`

## Purpose

This phase defines the contract for the first Companion real worker/model proof after the signed-in submit/result-reader product path was proven with mock/manual completion.

It is intentionally read-only and does not run any model, worker, helper, scheduler, timer, or persistent runtime.

## Current readiness carried forward

From AE-R2:

- CT203 SQLite integrity check returned `ok`.
- CT203 read-only inventory succeeded with a SQLite busy timeout.
- The DB file holder was the normal CT203 uvicorn controller process.
- PVESO was reachable through PVEW SSH.
- CT101 posture was readable and remains `onboot=0`.
- The platform still has existing queued/running jobs, so exact target isolation is mandatory.

## Runtime proof contract for the next phase

The next phase must be named `FC-O45-E-AG` or similar and must require explicit approval before execution.

Required approval phrase:

```
APPROVE_FC_O45_E_AG_EXACT_ONE_COMPANION_MODEL_JOB
```

Allowed only after approval:

- Create or select exactly one new signed-in `companion.chat` job.
- Assign an approved small model, preferably `qwen2.5:0.5b`.
- Run exactly one bounded foreground worker/model path for that one job id.
- Insert exactly one result row for that one job only if the bounded model path succeeds.
- Perform read-only post-verification.
- Use the signed-in result reader to display the completed result.

Still forbidden unless separately approved:

- Scheduler activation.
- Timer activation.
- Persistent worker activation.
- Broad queue draining.
- Multiple job claims.
- Any CT/VM restart.
- Any backend/frontend deploy.
- Any nginx/cloudflared/storage mutation.
- Any model pull/download.
- Any deletion.

## Required runtime safeguards

The runtime command must:

1. Refuse unless repo HEAD and origin/main match the expected checkpoint.
2. Refuse if the repo is dirty.
3. Refuse if CT203 DB integrity is not `ok`.
4. Refuse if the exact target job id is missing, not owned by the signed-in test user, not `companion.chat`, or already has result rows.
5. Refuse if any project scheduler/timer/persistent worker unit is active.
6. Use a strict wall-clock timeout.
7. Never claim or mutate jobs other than the exact target job id.
8. Verify after completion:
   - job id,
   - user id,
   - status,
   - job type,
   - requested model,
   - attempts,
   - exactly one result row,
   - result text.
9. Leave scheduler/timers/persistent workers disabled/inactive.

## Preferred proof shape

```
signed-in Companion submit or exact DB insert
  -> target one new companion.chat job id
  -> bounded foreground worker/model run for that exact id only
  -> CT203 read-only result verification
  -> browser result reader verification
  -> docs/smoke/commit/tag
```

## Live read-only inventory

```
=== Stage 16 FC-O45-E-AF exact-one-job model proof contract ===
MUTATION_SCOPE=read_only_source_runtime_contract_plus_repo_doc_smoke_commit_tag_push
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
NO file deletion

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=64bfabb
head_now=64bfabb
origin_main_now=64bfabb
git_preflight=PASS

=== source inventory: exact job / foreground / worker / model paths ===
frontend/study-ui/app.js:403:    el.innerHTML = "Review queue complete. Load another queue or change mode.";
frontend/study-ui/app.js:501:    $("passwordInput").autocomplete = mode === "register" ? "new-password" : "current-password";
frontend/study-ui/app.js:703:    companionAddMessage("assistant", "Review complete. Load another queue when you are ready.");
frontend/study-ui/app.js:935:  // Treat 502/503/504 and HTML error pages as transient gateway failures.
frontend/study-ui/app.js:937:    return data?.job_id || data?.id || data?.job?.id || data?.result?.job_id || data?.result?.id || null;
frontend/study-ui/app.js:1040:          if (["failed", "error"].includes(String(status).toLowerCase())) {
frontend/study-ui/app.js:1041:            throw new Error(data?.last_error || data?.error || `Job ${jobId} failed`);
frontend/study-ui/app.js:1044:          if (["forwarded", "done", "complete", "completed", "succeeded", "success"].includes(String(status).toLowerCase()) && text) {
frontend/study-ui/app.js:1107:        body: { message: prompt, requested_model: "gemma4:e4b" },
frontend/study-ui/app.js:1115:        body: { job_type: "ollama_chat", prompt, requested_model: "gemma4:e4b" },
frontend/study-ui/app.js:1224:      if (status) status.textContent = err.transient ? "Companion is still pending after a gateway timeout." : "Companion API route failed.";
frontend/study-ui/app.js:1642:      // If cross-domain status fails, keep Login/Register visible.
frontend/study-ui/app.js:1880:        throw new Error(data.error || data.blocked_reason || "Boot request failed");
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:99:          <input id="authEmail" type="email" autocomplete="email" required />
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:104:          <input id="authPassword" type="password" autocomplete="current-password" required />
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:145:    console.warn("Private route clean refresh failed:", err);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:316: * - /ads/reward/* = controller-owned rewarded ad claims
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:602:                // ignore render failures
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1968:      existing.addEventListener("error", () => reject(new Error("Google Publisher Tag failed to load.")), { once: true });
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1977:    script.onerror = () => reject(new Error("Google Publisher Tag failed to load."));
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
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2147:        setGoogleRewardedMessage(err.message || "Rewarded ad failed to load.");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2152:    setGoogleRewardedMessage(err.message || "Rewarded ad failed to load.");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2181:  if (status.can_claim) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2184:      detail: status.blocked_reason || "Rewarded ad claim is available.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2219:    detail: status.blocked_reason || "Rewarded ad claim is not available yet.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2353:            <strong>${rewardProvider?.client_claim_enabled ? "Client claim enabled" : "Claim disabled"}</strong>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2361:              id="claimAdRewardBtn"
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2387:            ${safeText(googleRewardedMessage || "Credit claiming remains disabled until final verification is enabled.")}
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2746:    console.error("[study-wrapper-preview] create deck failed", error);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2795:    console.error("[study-wrapper-preview] review submit failed", error);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2911:    console.error("[study-wrapper-preview] review queue failed", error);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2985:    console.error("[study-wrapper-preview] add card failed", error);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3111:    console.error("[study-wrapper-preview] card stats hydrate failed", error);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3190:    console.error("[study-wrapper-preview] hydrate failed", error);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3366:    if (status === "complete" || status === "completed") {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3371:        detail: `job ${jobId} · ${result.model || job.requested_model || "model unknown"}`
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3375:    if (status === "failed" || status === "error") {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3376:      throw new Error(job?.error_text || `Queued job failed with status ${status}`);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3416:        requested_model: "gemma4:e4b",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3428:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3431:      throw new Error("Queued job response did not include a job_id.");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3547:      ["Queued responses", "Messages are submitted as jobs and polled until complete."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3732:  $("claimAdRewardBtn")?.addEventListener("click", claimMockAdReward);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3848:async function claimMockAdReward() {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3854:  const button = $("claimAdRewardBtn");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3861:    const result = await api("/ads/reward/claim", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:4188:    const message = err.message || "Email verification failed.";
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:4284:      // Keep login successful even if account refresh fails.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:4308:    // Local logout should still happen even if remote logout fails.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:4968:      JSON.stringify(n.services || []).toLowerCase().includes("ollama")
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:5465:  console.warn("Clean admin/support render wrapper failed:", err);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:5537:      console.warn("[cache] force refresh failed", err);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:5566:      console.warn("[credits] header refresh failed", reason, err);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:5594:// requests such as presence, public-status, credits, or study previews fail.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:5599:      result.catch((err) => console.warn(`[auth-background] ${label} failed`, err));
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:5603:    console.warn(`[auth-background] ${label} failed`, err);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:5748:    fastSetAuthMessage(err.message || "Login failed.", true);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:5797:      console.warn("[auth] background logout revoke failed", err);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:5875:      console.warn("[presence] web presence failed", err);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:5958:      console.warn("[presence] apply power policy failed", err);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:5983:  console.warn("[presence] apply policy wrapper failed", err);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6008:      console.warn("Startup credits refresh failed:", creditErr);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6017:    console.warn("Startup auth refresh failed:", err);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6096:    console.warn("Email verification route handling failed", err);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6225:    const message = err.message || "Password reset failed.";
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6255:    console.warn("Password reset route handling failed", err);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6323:    if (payload && payload.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6324:      cleanPayload.requested_model = String(payload.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6400:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6572:        hasModel: Boolean(context && context.requested_model),
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6621:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6622:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6663: * - builds only message, chat_id, and requested_model
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6694:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6695:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6771:        error: "queued_orchestration_payload_failed_stage_5f51",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6817:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6821:        error: "queued_orchestration_send_failed_stage_5f51",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6834:          id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6835:          job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6846:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6860:      job_id: sendResult.job_id,
frontend/wrapper-ui/index.html.bak-stage5o24-study-format-cleanup-2026-06-11-121612:99:          <input id="authEmail" type="email" autocomplete="email" required />
frontend/wrapper-ui/index.html.bak-stage5o24-study-format-cleanup-2026-06-11-121612:104:          <input id="authPassword" type="password" autocomplete="current-password" required />
frontend/wrapper-ui/index.html.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:99:          <input id="authEmail" type="email" autocomplete="email" required />
frontend/wrapper-ui/index.html.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:104:          <input id="authPassword" type="password" autocomplete="current-password" required />
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:145:    console.warn("Private route clean refresh failed:", err);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:316: * - /ads/reward/* = controller-owned rewarded ad claims
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:602:                // ignore render failures
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:1968:      existing.addEventListener("error", () => reject(new Error("Google Publisher Tag failed to load.")), { once: true });
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:1977:    script.onerror = () => reject(new Error("Google Publisher Tag failed to load."));
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
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2147:        setGoogleRewardedMessage(err.message || "Rewarded ad failed to load.");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2152:    setGoogleRewardedMessage(err.message || "Rewarded ad failed to load.");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2181:  if (status.can_claim) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2184:      detail: status.blocked_reason || "Rewarded ad claim is available.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2219:    detail: status.blocked_reason || "Rewarded ad claim is not available yet.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2353:            <strong>${rewardProvider?.client_claim_enabled ? "Client claim enabled" : "Claim disabled"}</strong>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2361:              id="claimAdRewardBtn"
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2387:            ${safeText(googleRewardedMessage || "Credit claiming remains disabled until final verification is enabled.")}
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2746:    console.error("[study-wrapper-preview] create deck failed", error);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2795:    console.error("[study-wrapper-preview] review submit failed", error);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2911:    console.error("[study-wrapper-preview] review queue failed", error);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2985:    console.error("[study-wrapper-preview] add card failed", error);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3111:    console.error("[study-wrapper-preview] card stats hydrate failed", error);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3190:    console.error("[study-wrapper-preview] hydrate failed", error);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3366:    if (status === "complete" || status === "completed") {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3371:        detail: `job ${jobId} · ${result.model || job.requested_model || "model unknown"}`
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3375:    if (status === "failed" || status === "error") {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3376:      throw new Error(job?.error_text || `Queued job failed with status ${status}`);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3416:        requested_model: "gemma4:e4b",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3428:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3431:      throw new Error("Queued job response did not include a job_id.");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3547:      ["Queued responses", "Messages are submitted as jobs and polled until complete."],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3841:  $("claimAdRewardBtn")?.addEventListener("click", claimMockAdReward);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3957:async function claimMockAdReward() {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3963:  const button = $("claimAdRewardBtn");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3970:    const result = await api("/ads/reward/claim", {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:4297:    const message = err.message || "Email verification failed.";
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:4393:      // Keep login successful even if account refresh fails.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:4417:    // Local logout should still happen even if remote logout fails.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:5077:      JSON.stringify(n.services || []).toLowerCase().includes("ollama")
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:5574:  console.warn("Clean admin/support render wrapper failed:", err);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:5646:      console.warn("[cache] force refresh failed", err);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:5675:      console.warn("[credits] header refresh failed", reason, err);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:5703:// requests such as presence, public-status, credits, or study previews fail.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:5708:      result.catch((err) => console.warn(`[auth-background] ${label} failed`, err));
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:5712:    console.warn(`[auth-background] ${label} failed`, err);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:5857:    fastSetAuthMessage(err.message || "Login failed.", true);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:5906:      console.warn("[auth] background logout revoke failed", err);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:5984:      console.warn("[presence] web presence failed", err);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6067:      console.warn("[presence] apply power policy failed", err);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6092:  console.warn("[presence] apply policy wrapper failed", err);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6117:      console.warn("Startup credits refresh failed:", creditErr);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6126:    console.warn("Startup auth refresh failed:", err);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6205:    console.warn("Email verification route handling failed", err);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6334:    const message = err.message || "Password reset failed.";
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6364:    console.warn("Password reset route handling failed", err);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6432:    if (payload && payload.requested_model) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6433:      cleanPayload.requested_model = String(payload.requested_model);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6509:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6681:        hasModel: Boolean(context && context.requested_model),
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6730:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6731:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6772: * - builds only message, chat_id, and requested_model
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6803:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6804:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6880:        error: "queued_orchestration_payload_failed_stage_5f51",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6926:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6930:        error: "queued_orchestration_send_failed_stage_5f51",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6943:          id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6944:          job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6955:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6969:      job_id: sendResult.job_id,
frontend/wrapper-ui/dev_server.py:103:        "/api/ads/reward/claim": "/system/ads/reward/claim",
frontend/wrapper-ui/dev_server.py:513:                '{"ok":false,"detail":"Proxy failed: %s"}'
frontend/wrapper-ui/dev_server.py:529:    #   GET  /api/backend/chats/{chat_id}/messages/jobs/{job_id}
frontend/wrapper-ui/dev_server.py:533:    #   GET  /api/chat/queued/{job_id}
frontend/wrapper-ui/dev_server.py:649:    def _stage5g9_transform_status_response(self, chat_id, job_id, data):
frontend/wrapper-ui/dev_server.py:658:        out.setdefault("job_id", job_id)
frontend/wrapper-ui/dev_server.py:663:        #   pollData.status === "complete" && pollData.assistant_message
frontend/wrapper-ui/dev_server.py:665:        # The laptop controller status route returns the completed job and
frontend/wrapper-ui/dev_server.py:667:        # for complete jobs with a non-empty reply. This does not write an
frontend/wrapper-ui/dev_server.py:671:        if assistant_message is None and out.get("status") == "complete":
frontend/wrapper-ui/dev_server.py:699:                    assistant_id = f"{job_id}-assistant"
frontend/wrapper-ui/dev_server.py:741:                laptop_payload["requested_model"] = str(ct101_payload.get("model"))
frontend/wrapper-ui/dev_server.py:773:            job_id = status_match.group(2)
frontend/wrapper-ui/dev_server.py:776:                f"/api/chat/queued/{job_id}",
frontend/wrapper-ui/dev_server.py:783:                self._stage5g9_transform_status_response(chat_id, job_id, data),
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:311: * - /ads/reward/* = controller-owned rewarded ad claims
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:597:                // ignore render failures
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:1963:      existing.addEventListener("error", () => reject(new Error("Google Publisher Tag failed to load.")), { once: true });
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:1972:    script.onerror = () => reject(new Error("Google Publisher Tag failed to load."));
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
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2142:        setGoogleRewardedMessage(err.message || "Rewarded ad failed to load.");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2147:    setGoogleRewardedMessage(err.message || "Rewarded ad failed to load.");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2176:  if (status.can_claim) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2179:      detail: status.blocked_reason || "Rewarded ad claim is available.",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2214:    detail: status.blocked_reason || "Rewarded ad claim is not available yet.",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2348:            <strong>${rewardProvider?.client_claim_enabled ? "Client claim enabled" : "Claim disabled"}</strong>
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2356:              id="claimAdRewardBtn"
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2382:            ${safeText(googleRewardedMessage || "Credit claiming remains disabled until final verification is enabled.")}
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2741:    console.error("[study-wrapper-preview] create deck failed", error);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2790:    console.error("[study-wrapper-preview] review submit failed", error);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2906:    console.error("[study-wrapper-preview] review queue failed", error);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2980:    console.error("[study-wrapper-preview] add card failed", error);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3106:    console.error("[study-wrapper-preview] card stats hydrate failed", error);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3185:    console.error("[study-wrapper-preview] hydrate failed", error);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3362:    if (status === "complete" || status === "completed") {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3367:        detail: `job ${jobId} · ${result.model || job.requested_model || "model unknown"}`
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3371:    if (status === "failed" || status === "error") {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3372:      throw new Error(job?.error_text || `Queued job failed with status ${status}`);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3412:        requested_model: "gemma4:e4b",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3424:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3427:      throw new Error("Queued job response did not include a job_id.");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3536:  $("claimAdRewardBtn")?.addEventListener("click", claimMockAdReward);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3652:async function claimMockAdReward() {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3658:  const button = $("claimAdRewardBtn");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3665:    const result = await api("/ads/reward/claim", {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3992:    const message = err.message || "Email verification failed.";
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:4085:      // Keep login successful even if account refresh fails.
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:4109:    // Local logout should still happen even if remote logout fails.
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:4743:      JSON.stringify(n.services || []).toLowerCase().includes("ollama")
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5235:  console.warn("Clean admin/support render wrapper failed:", err);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5303:      console.warn("[cache] force refresh failed", err);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5332:      console.warn("[credits] header refresh failed", reason, err);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5360:// requests such as presence, public-status, credits, or study previews fail.
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5365:      result.catch((err) => console.warn(`[auth-background] ${label} failed`, err));
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5369:    console.warn(`[auth-background] ${label} failed`, err);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5499:    fastSetAuthMessage(err.message || "Login failed.", true);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5548:      console.warn("[auth] background logout revoke failed", err);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5626:      console.warn("[presence] web presence failed", err);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5709:      console.warn("[presence] apply power policy failed", err);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5734:  console.warn("[presence] apply policy wrapper failed", err);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5758:      console.warn("Startup credits refresh failed:", creditErr);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5767:    console.warn("Startup auth refresh failed:", err);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5825:    console.warn("Email verification route handling failed", err);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5954:    const message = err.message || "Password reset failed.";
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5984:    console.warn("Password reset route handling failed", err);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6052:    if (payload && payload.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6053:      cleanPayload.requested_model = String(payload.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6129:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6301:        hasModel: Boolean(context && context.requested_model),
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6350:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6351:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6392: * - builds only message, chat_id, and requested_model
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6423:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6424:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6500:        error: "queued_orchestration_payload_failed_stage_5f51",

=== candidate executable inventory, read-only ===
644 ./ops/systemd/edge-queue-controller-host-shutdown-override.conf
644 ./ops/systemd/edge-queue-controller-host-wake-override.conf
644 ./ops/systemd/edge-queue-controller-power-auto-override.conf
644 ./ops/systemd/edge-queue-controller-power-auto-pause-override.conf
644 ./ops/systemd/edge-queue-controller-power-auto-start-override.conf
644 ./ops/systemd/edge-queue-controller-power-execute-override.conf
644 ./ops/systemd/edge-queue-controller-power-idle-override.conf
644 ./ops/systemd/edge-queue-controller-power-stop-plan-override.conf
644 ./ops/systemd/edge-queue-controller-proxmox-inventory-override.conf
644 ./ops/systemd/edge-queue-controller.service
644 ./ops/systemd/edge-queue-controller-tick-direct-mode-override.conf
644 ./ops/systemd/edge-queue-controller-wake-and-start-override.conf
644 ./ops/systemd/edge-queue-controller-worker-start-override.conf
644 ./ops/systemd/edge-queue-power-auto-tick.service
644 ./ops/systemd/edge-queue-power-auto-tick.timer
644 ./ops/systemd/edge-queue-power-idle-tick.service
644 ./ops/systemd/edge-queue-power-idle-tick.timer
644 ./ops/systemd/edge-queue-public-gateway.service
644 ./ops/systemd/edge-queue-remediation-tick.service
644 ./ops/systemd/edge-queue-remediation-tick.timer
644 ./ops/systemd/edge-queue-scheduler-tick.service
644 ./ops/systemd/edge-queue-scheduler-tick.timer
664 ./ops/compare/output/companion-chat.manual.local-auth-shadow.json
664 ./ops/compare/output/stage7n-companion-readiness.local-auth-shadow.json
664 ./ops/db/default-off-worker-registry-lane-metadata.sql
664 ./ops/db/laptop-app-schema-v2-chat-source-job-id.sql
664 ./ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml
664 ./ops/smoke/check-frontend-queued-chat-ui-wiring-map.sh
664 ./ops/systemd/ct101/edge-ct101-ollama-worker.service.example
664 ./ops/systemd/edge-queue-controller-direct-ollama-forward-override.conf
664 ./ops/systemd/edge-queue-controller-public-api-override.conf
664 ./ops/systemd/edge-queue-controller.service.d/95-current-proxmox-power-inventory.conf
664 ./ops/systemd/edge-queue-scheduler-one-shot.service
664 ./ops/systemd/edge-queue-scheduler-one-shot.timer
664 ./ops/workers/__pycache__/ct101_minimal_ollama_worker.cpython-312.pyc
664 ./ops/workers/README-ct101-minimal-ollama-worker.md
755 ./ops/db/apply-laptop-app-schema-v2-chat-source-job-id.sh
755 ./ops/smoke/check-laptop-app-schema-v2-chat-source-job-id.sh
755 ./ops/smoke/check-laptop-job-lifecycle-synthetic.sh
755 ./ops/smoke/check-laptop-job-queue-facade-plan.sh
755 ./ops/smoke/check-opt-in-queued-chat-route-plan.sh
755 ./ops/smoke/check-phase-11r-model-lane-routing-contract.sh
755 ./ops/smoke/check-phase-11s-live-model-lane-metadata-activation.sh
755 ./ops/smoke/check-phase-11t-lane-aware-queue-status-visibility.sh
755 ./ops/smoke/check-phase-14i-k-disabled-legacy-local-edge-jobs-flag-helpers.sh
755 ./ops/smoke/check-phase-14i-l-gate-legacy-local-queue-status.sh
755 ./ops/smoke/check-phase-14i-m-gate-legacy-companion-local-job-creation.sh
755 ./ops/smoke/check-phase-14i-n-gate-legacy-public-local-jobs-creation.sh
755 ./ops/smoke/check-phase-14i-o-remaining-legacy-local-jobs-read-list-route-inspection.sh
755 ./ops/smoke/check-phase-14i-p-gate-public-legacy-local-jobs-read-list-routes.sh
755 ./ops/smoke/check-phase-14i-q-direct-local-jobs-route-inspection.sh
755 ./ops/smoke/check-phase-14i-r-direct-local-jobs-usage-inspection.sh
755 ./ops/smoke/check-phase-14i-s-study-ui-companion-queue-migration-inspection.sh
755 ./ops/smoke/check-phase-14i-t-study-ui-queued-chat-adapter-plan.sh
755 ./ops/smoke/check-phase-14i-u-study-ui-queued-chat-adapter.sh
755 ./ops/smoke/check-phase-14i-v-post-adapter-direct-jobs-fallback-inspection.sh
755 ./ops/smoke/check-phase-14i-w-study-ui-direct-jobs-fallback-flag-plan.sh
755 ./ops/smoke/check-phase-14i-x-study-ui-legacy-jobs-fallback-flag.sh
755 ./ops/smoke/check-phase-14i-y-disabled-frontend-legacy-jobs-fallback-validation.sh
755 ./ops/smoke/check-phase-14j-ck-gate-b0-synthetic-worker-availability-smoke-artifact.sh
755 ./ops/smoke/check-phase-14j-cl-accepts-lane-jobs-and-no-lane-filter-contract-patch-plan.sh
755 ./ops/smoke/check-phase-14j-cm-source-patch-accepts-lane-jobs-and-no-lane-filter-contract.sh
755 ./ops/smoke/check-phase-14j-cr-gate-b1-worker-availability-metadata-plan.sh
755 ./ops/smoke/check-phase-14j-cs-gate-b1-temp-db-worker-availability-metadata-smoke.sh
755 ./ops/smoke/check-phase-14j-ct-gate-b1-temp-db-worker-availability-result-checkpoint.sh
755 ./ops/smoke/check-phase-14j-cu-gate-b2-production-worker-metadata-seed-plan.sh
755 ./ops/smoke/check-phase-14j-cx-seeded-worker-metadata-activation-readiness-plan.sh
755 ./ops/smoke/check-phase-14j-cz-seeded-worker-metadata-default-off-readiness-result-checkpoint.sh
755 ./ops/smoke/check-queued-chat-session-auth-resolver-map.sh
755 ./ops/smoke/check-real-user-ct101-queue-execution-guard-plan.sh
755 ./ops/smoke/check-real-user-queued-chat-guard-plan.sh
755 ./ops/smoke/check-stage-5g10-ct101-compatible-completed-queued-assistant-message.sh
755 ./ops/smoke/check-stage-5g11-ct101-bridge-real-worker-lifecycle-readiness.sh
755 ./ops/smoke/check-stage-5g12-live-runtime-ct101-queued-bridge.sh
```
