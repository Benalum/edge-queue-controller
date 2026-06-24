# Stage 16 FC-O45-E-AL — Submit-to-Worker Automation Design Contract

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `58123db`
- Prior tag: `controller-stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract-2026-06-24`

## Scope

This phase is repo/docs/smoke only.

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

## State carried forward

The current proven Companion chain is:

```
signed-in Companion submit creates/returns a queued job id
Companion result reader can read completed owned jobs
exact-one real-model proof can complete a companion.chat job
persona wrapper can produce product-quality output
```

Latest product-quality proof:

- job: `128`
- `user_id=16`
- `job_type=companion.chat`
- `requested_model=qwen2.5:0.5b`
- `attempts=1`
- `result_rows=1`
- result: `Hello! How can I assist you today?`
- `quality_flags=none`
- `quality_pass=true`

Remaining gap:

```
normal signed-in submit -> bounded worker completion -> result-reader display
```

## Automation design goal

The next productization step should connect the normal signed-in Companion submit path to a bounded completion path without enabling broad background processing.

The safest initial automation shape is:

```
1. signed-in UI/API submits exactly one companion.chat job
2. API returns job_id to the UI
3. operator-approved bounded foreground worker targets only that job_id
4. worker applies Companion persona wrapper
5. worker calls already-installed qwen2.5:0.5b
6. worker writes exactly one result row for that job
7. result-reader displays that job result
8. post-check verifies no scheduler/timer/persistent worker activation
```

This is not full production background processing yet. It is the bridge between manual DB/model orchestration and safe product automation.

## Required implementation contract

Before runtime, the implementation must provide a targetable exact-job path that accepts one job id and refuses all others.

Required behavior:

1. Refuse unless the target job exists.
2. Refuse unless target job is owned by `user_id=16` for the proof.
3. Refuse unless target job has `job_type=companion.chat`.
4. Refuse unless target job status is `queued`.
5. Refuse unless target job has zero result rows.
6. Refuse unless requested model is already installed.
7. Apply the Companion persona wrapper before model generation.
8. Run with a strict timeout.
9. Mark only the target job running/completed/failed.
10. Insert exactly one result row only for the target job.
11. Record quality flags:
    - `model_identity_leakage_qwen`
    - `vendor_identity_leakage_alibaba`
    - `runtime_identity_leakage_ollama`
    - `internal_marker_leakage`
    - `too_long_for_one_sentence_proof`
    - `not_clean_sentence`
    - `weak_companion_greeting`
12. Refuse broad queue draining.
13. Leave scheduler/timer/persistent workers inactive.

## Preferred implementation path

The implementation should avoid a frontend deploy at first.

Preferred next phase:

```
FC-O45-E-AM
```

AM should be runtime-approved and should:

1. Create a job through the normal signed-in submit path if an auth token/session is available in the smoke harness; otherwise use the closest existing controller API path that preserves user ownership and job type.
2. Capture the returned job id.
3. Run exact-one bounded completion for only that job id.
4. Use the Companion persona wrapper.
5. Verify DB state and result quality.
6. Verify the result-reader path can read that job.

Suggested approval phrase:

```
APPROVE_FC_O45_E_AM_EXACT_ONE_SUBMIT_TO_PERSONA_WORKER_RESULT
```

## Hard no-go conditions for AM

AM must refuse if:

- repo HEAD/origin does not match the expected checkpoint,
- repo is dirty,
- CT203 SQLite integrity is not `ok`,
- public result-reader marker is missing,
- target job id cannot be isolated,
- target job already has a result row,
- scheduler/timer/persistent worker units are active,
- PVESO route is unavailable,
- qwen2.5:0.5b is not already installed,
- the command would claim or mutate any job besides the target job,
- the command would require model pull/download,
- the command would require service restart or deploy.

## Later production lane, not yet

After AM passes, later phases can consider:

- installing a disabled exact-job worker command,
- adding a backend-only exact-job completion endpoint behind an internal/admin gate,
- adding a one-shot service wrapper,
- only much later enabling a timer or persistent worker after repeatability and rollback are proven.

Do **not** jump directly to scheduler/timer/persistent worker activation.

## Live source inventory

```
=== Stage 16 FC-O45-E-AL submit-to-worker automation design contract ===
MUTATION_SCOPE=repo_docs_smoke_only
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
expected_head=58123db
head_now=58123db
origin_main_now=58123db
git_preflight=PASS

=== source inventory: submit, result reader, worker, persona wrapper paths ===
frontend/study-ui/app.js:89:    $("workerStatusText").textContent = `Jobs forwarded: ${data.queue?.forwarded ?? 0}`;
frontend/study-ui/app.js:93:    $("workerStatusText").textContent = err.message;
frontend/study-ui/app.js:403:    el.innerHTML = "Review queue complete. Load another queue or change mode.";
frontend/study-ui/app.js:501:    $("passwordInput").autocomplete = mode === "register" ? "new-password" : "current-password";
frontend/study-ui/app.js:703:    companionAddMessage("assistant", "Review complete. Load another queue when you are ready.");
frontend/study-ui/app.js:1044:          if (["forwarded", "done", "complete", "completed", "succeeded", "success"].includes(String(status).toLowerCase()) && text) {
frontend/study-ui/app.js:1107:        body: { message: prompt, requested_model: "gemma4:e4b" },
frontend/study-ui/app.js:1115:        body: { job_type: "ollama_chat", prompt, requested_model: "gemma4:e4b" },
frontend/study-ui/app.js:1145:            addCompanionMessage("system", `Queued with Gemma E4B as job ${jobId}. Waiting for the worker...`);
frontend/study-ui/study-content.partial.html:15:          <span id="workerStatusText">Worker proxy</span>
frontend/study-ui/study-content.partial.html:25:            <h2>Your personal AI learning platform</h2>
frontend/study-ui/study-content.partial.html:51:            <p>Study cards are active. Companion now uses the worker proxy and Gemma E4B queue path when available.</p>
frontend/study-ui/index.html:45:          <span id="workerStatusText">Worker proxy</span>
frontend/study-ui/index.html:55:            <h2>Your personal AI learning platform</h2>
frontend/study-ui/index.html:81:            <p>Study cards are active. Companion now uses the worker proxy and Gemma E4B queue path when available.</p>
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:99:          <input id="authEmail" type="email" autocomplete="email" required />
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:104:          <input id="authPassword" type="password" autocomplete="current-password" required />
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:159:      ["Profile", "Manage preferences, permissions, account settings, and future companion personalization.", "/profile"],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:197:      ["Companion", "General local-first AI conversation through the existing queued worker path."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:208:      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:236:      "Profile will manage account settings, preferences, permissions, and personalization for the platform.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:316: * - /ads/reward/* = controller-owned rewarded ad claims
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:686:  "workers",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:687:  "ct101-laptop-queue-worker",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:703:  workers: "Worker capacity and processing services.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:704:  "ct101-laptop-queue-worker": "Managed CT101 worker processing queued chat jobs with guarded one-at-a-time execution.",
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
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2713:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2762:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2873:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2940:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3120:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3309:            <p>Uses the existing queued worker path and polls the returned job id.</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3313:            <strong>Companion queue worker</strong>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3350:    queuedChatSetStatus(`Waiting for worker... poll ${i + 1}`);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3366:    if (status === "complete" || status === "completed") {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3371:        detail: `job ${jobId} · ${result.model || job.requested_model || "model unknown"}`
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3416:        requested_model: "gemma4:e4b",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3535:    body: "Build decks, add cards, review by difficulty, and track progress over time. Once signed in, this page becomes your personal study dashboard.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3545:    body: "Send messages through the local queued AI path so the website stays responsive while your worker processes the response.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3547:      ["Queued responses", "Messages are submitted as jobs and polled until complete."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3549:      ["Local-first", "Designed around your local server and worker queue."]
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
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:197:      ["Companion", "General local-first AI conversation through the existing queued worker path."],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:208:      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:236:      "Profile will manage account settings, preferences, permissions, and personalization for the platform.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:316: * - /ads/reward/* = controller-owned rewarded ad claims
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:686:  "workers",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:687:  "ct101-laptop-queue-worker",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:703:  workers: "Worker capacity and processing services.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:704:  "ct101-laptop-queue-worker": "Managed CT101 worker processing queued chat jobs with guarded one-at-a-time execution.",
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
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2713:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2762:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2873:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2940:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3120:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3309:            <p>Uses the existing queued worker path and polls the returned job id.</p>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3313:            <strong>Companion queue worker</strong>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3350:    queuedChatSetStatus(`Waiting for worker... poll ${i + 1}`);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3366:    if (status === "complete" || status === "completed") {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3371:        detail: `job ${jobId} · ${result.model || job.requested_model || "model unknown"}`
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3416:        requested_model: "gemma4:e4b",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3535:    body: "Build decks, add cards, review by difficulty, and track progress over time. Once signed in, this page becomes your personal study dashboard.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3545:    body: "Send messages through the local queued AI path so the website stays responsive while your worker processes the response.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3547:      ["Queued responses", "Messages are submitted as jobs and polled until complete."],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3549:      ["Local-first", "Designed around your local server and worker queue."]
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
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:192:      ["Companion", "General local-first AI conversation through the existing queued worker path."],
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:203:      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:231:      "Profile will manage account settings, preferences, permissions, and personalization for the platform.",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:311: * - /ads/reward/* = controller-owned rewarded ad claims
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:681:  "workers",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:682:  "ct101-laptop-queue-worker",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:698:  workers: "Worker capacity and processing services.",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:699:  "ct101-laptop-queue-worker": "Managed CT101 worker processing queued chat jobs with guarded one-at-a-time execution.",
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
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2708:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2757:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2868:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:2935:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3115:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3249:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3305:            <p>Uses the existing queued worker path and polls the returned job id.</p>
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3309:            <strong>Companion queue worker</strong>
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3346:    queuedChatSetStatus(`Waiting for worker... poll ${i + 1}`);
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
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:197:      ["Companion", "General local-first AI conversation through the existing queued worker path."],
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:208:      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:236:      "Profile will manage account settings, preferences, permissions, and personalization for the platform.",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:316: * - /ads/reward/* = controller-owned rewarded ad claims
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:686:  "workers",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:687:  "ct101-laptop-queue-worker",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:703:  workers: "Worker capacity and processing services.",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:704:  "ct101-laptop-queue-worker": "Managed CT101 worker processing queued chat jobs with guarded one-at-a-time execution.",
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
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2713:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2762:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2873:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:2940:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3120:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3254:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3310:            <p>Uses the existing queued worker path and polls the returned job id.</p>
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3314:            <strong>Companion queue worker</strong>
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3351:    queuedChatSetStatus(`Waiting for worker... poll ${i + 1}`);
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
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:197:      ["Companion", "General local-first AI conversation through the existing queued worker path."],
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:208:      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:236:      "Profile will manage account settings, preferences, permissions, and personalization for the platform.",
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:316: * - /ads/reward/* = controller-owned rewarded ad claims
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:686:  "workers",
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:687:  "ct101-laptop-queue-worker",
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:703:  workers: "Worker capacity and processing services.",
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:704:  "ct101-laptop-queue-worker": "Managed CT101 worker processing queued chat jobs with guarded one-at-a-time execution.",
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
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2713:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2762:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2873:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:2940:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3120:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3259:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3315:            <p>Uses the existing queued worker path and polls the returned job id.</p>
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3319:            <strong>Companion queue worker</strong>
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3356:    queuedChatSetStatus(`Waiting for worker... poll ${i + 1}`);
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
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:197:      ["Companion", "General local-first AI conversation through the existing queued worker path."],
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:208:      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:236:      "Profile will manage account settings, preferences, permissions, and personalization for the platform.",
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:316: * - /ads/reward/* = controller-owned rewarded ad claims
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:686:  "workers",
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:687:  "ct101-laptop-queue-worker",
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:703:  workers: "Worker capacity and processing services.",
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:704:  "ct101-laptop-queue-worker": "Managed CT101 worker processing queued chat jobs with guarded one-at-a-time execution.",
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
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2713:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2762:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2873:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o32-profile-after-login-gate-2026-06-11-123351:2940:  const statusText = document.getElementById("workerStatusText");

=== prior proof inventory ===
docs/stage-16-e3m-b1-insert-helper-test-queued-job-only.md:47:- No scheduler activation.
docs/chat-only-migration-map.md:219:- start persistent workers
docs/stage-16-fc-o17-bounded-ollama-concurrency-design-no-apply.md:15:It does not mutate CT101, CT203, jobs, services, timers, systemd units, Docker, Ollama, scheduler state, persistent worker state, CTs, or VMs.
docs/stage-16-fc-o17-bounded-ollama-concurrency-design-no-apply.md:50:    qwen2.5:0.5b max_concurrent_model_calls=2
docs/stage-16-fc-o17-bounded-ollama-concurrency-design-no-apply.md:117:- Do not start persistent workers.
docs/stage-16-fc-o17-bounded-ollama-concurrency-design-no-apply.md:155:Recommended next stage: explicit approval for a bounded Ollama-only apply stage that sets `OLLAMA_NUM_PARALLEL=2` without changing CT203 durable queue authority and without enabling persistent workers or bulk queue draining.
docs/stage-16-fc-i1-jobs88-91-runtime-revised-semantic-validators.md:48:- activate scheduler or persistent workers,
docs/stage-16-e3z-ek-guarded-service-timer-persistent-worker-strategy-no-apply.md:41:job48=completed,attempts=4,results=1,model=qwen2.5:0.5b
docs/stage-16-e3z-ek-guarded-service-timer-persistent-worker-strategy-no-apply.md:82:- Scheduler/timer activation remains off for the production queue path.
docs/stage-16-e3z-ek-guarded-service-timer-persistent-worker-strategy-no-apply.md:143:- the user explicitly approves timer activation.
docs/stage-16-e3z-ek-guarded-service-timer-persistent-worker-strategy-no-apply.md:149:A persistent worker path should not be enabled until there is evidence for:
docs/stage-16-e3z-at-ct101-ollama-service-unmask-start-plan-no-apply.md:20:- CT203 scheduler/timer activation remains off.
docs/stage-16-e3z-at-ct101-ollama-service-unmask-start-plan-no-apply.md:63:That later phase must still avoid job claims, DB result writes, scheduler/timer activation, persistent worker activation, and model endpoint calls until a separate smoke boundary is approved.
docs/stage-16-e3z-f-insert-one-fresh-timer-proof-job-only.md:28:- activate persistent workers
docs/stage-16-e3z-f-insert-one-fresh-timer-proof-job-only.md:45:- model: `qwen2.5:0.5b`
docs/stage-16-e3z-f-insert-one-fresh-timer-proof-job-only.md:49:This job is reserved for a future bounded scheduler-only timer activation phase.
docs/stage-16-e3z-f-insert-one-fresh-timer-proof-job-only.md:51:It must not be run except by the future approved E3Z-H scheduler-only timer activation phase or a separately approved replacement plan.
docs/stage-16-e3z-f-insert-one-fresh-timer-proof-job-only.md:73:Do not run the E3Z-F inserted job except through an approved E3Z-H bounded scheduler-only timer activation phase.
docs/stage-16-e3z-f-insert-one-fresh-timer-proof-job-only.md:87:E3Z-G must not start or enable the timer, run the scheduler, call a model, or activate persistent workers.
docs/stage-16-e3z-ew-installed-unit-job55-compatible-marker-retry-contract-no-apply.md:119:- requested model: `qwen2.5:0.5b`,
docs/stage-16-e3z-ew-installed-unit-job55-compatible-marker-retry-contract-no-apply.md:169:5. Fresh job uses requested model `qwen2.5:0.5b`.
docs/stage-16-e3z-el-bounded-service-proof-acceptance-contract-no-apply.md:49:- Job 48 requested model was `qwen2.5:0.5b`.
docs/stage-16-e3z-el-bounded-service-proof-acceptance-contract-no-apply.md:110:The first service-path proof should continue using the smallest known-good model class, currently `qwen2.5:0.5b`, unless a separate no-apply model change checkpoint is created first.
docs/stage-16-e3z-el-bounded-service-proof-acceptance-contract-no-apply.md:226:E3Z-EM must not enable persistent workers or scheduler/timer dispatch.
docs/stage-16-fc-o30-run-only-job107-gemma4-companion-chat-after-model-name-repair.md:41:- enable persistent workers,
docs/stage-16-e3p-c-r2-smoke-quote-recovery-no-runtime.md:33:- No scheduler activation.
docs/stage-16-e3p-c-r2-smoke-quote-recovery-no-runtime.md:34:- No persistent worker activation.
docs/stage-16-fc-n2c1-r3-job101-recovery-decision-gate-no-apply.md:25:- enable persistent workers,
docs/stage-16-fc-n2c1-r3-job101-recovery-decision-gate-no-apply.md:43:| 95 | router_label | qwen2.5:0.5b | completed | 1 | 1 | true | keep evidence |
docs/stage-16-fc-n2c1-r3-job101-recovery-decision-gate-no-apply.md:44:| 96 | summary | qwen2.5:0.5b | completed | 1 | 1 | false | keep evidence |
docs/stage-16-fc-n2c1-r3-job101-recovery-decision-gate-no-apply.md:46:| 98 | json_response | qwen2.5:0.5b | completed | 1 | 1 | true | keep evidence |
docs/stage-16-fc-n2c1-r3-job101-recovery-decision-gate-no-apply.md:120:- enable no persistent workers,
docs/stage-16-fc-o43-c-r2-record-product-visible-thinking-refusal-read-only-docs-only.md:50:- scheduler activation,
docs/stage-16-fc-o43-c-r2-record-product-visible-thinking-refusal-read-only-docs-only.md:51:- persistent worker activation,
docs/stage-16-fc-n1-r4-job97-recovery-decision-gate-no-apply.md:26:- enable persistent workers,
docs/stage-16-fc-n1-r4-job97-recovery-decision-gate-no-apply.md:44:| 95 | router_label | qwen2.5:0.5b | completed | 1 | 1 | true | keep evidence |
docs/stage-16-fc-n1-r4-job97-recovery-decision-gate-no-apply.md:45:| 96 | summary | qwen2.5:0.5b | completed | 1 | 1 | false | keep evidence |
docs/stage-16-fc-n1-r4-job97-recovery-decision-gate-no-apply.md:47:| 98 | json_response | qwen2.5:0.5b | queued | 0 | 0 | no | eligible for later continuation |
docs/stage-16-fc-n1-r4-job97-recovery-decision-gate-no-apply.md:119:- enable no persistent workers,
docs/stage-5g17-ct101-one-shot-laptop-queue-completion.md:34:This stage does not enable persistent worker runtime.
docs/stage-16-fc-n2b1-r4-job100-recovery-decision-gate-no-apply.md:25:- enable persistent workers,
docs/stage-16-fc-n2b1-r4-job100-recovery-decision-gate-no-apply.md:43:| 95 | router_label | qwen2.5:0.5b | completed | 1 | 1 | true | keep evidence |
docs/stage-16-fc-n2b1-r4-job100-recovery-decision-gate-no-apply.md:44:| 96 | summary | qwen2.5:0.5b | completed | 1 | 1 | false | keep evidence |
docs/stage-16-fc-n2b1-r4-job100-recovery-decision-gate-no-apply.md:46:| 98 | json_response | qwen2.5:0.5b | completed | 1 | 1 | true | keep evidence |
docs/stage-16-fc-n2b1-r4-job100-recovery-decision-gate-no-apply.md:123:- enable no persistent workers,
docs/stage-16-fc-o20-run-only-job114-qwen3-json-post-concurrency-one-shot.md:39:- enable persistent workers,
docs/stage-16-fc-o20-run-only-job114-qwen3-json-post-concurrency-one-shot.md:104:Do not enable persistent workers or bulk queue draining yet.
docs/stage-16-fc-o45-e-p-companion-auth-no-enqueue-validation-plan.md:93:- scheduler/timer activation
docs/stage-16-fc-k-model-tier-output-control-remediation-plan-no-apply.md:28:- enable persistent workers,
docs/stage-16-fc-k-model-tier-output-control-remediation-plan-no-apply.md:83:Do not enable persistent workers.
docs/stage-16-fc-k-model-tier-output-control-remediation-plan-no-apply.md:89:`qwen2.5:0.5b` remains approved only for mechanical smoke and very small routing probes.
docs/stage-16-fc-k-model-tier-output-control-remediation-plan-no-apply.md:186:| router_label | qwen2.5:0.5b | qwen2.5:0.5b or small router | Already repeatably passed |
docs/stage-16-fc-k-model-tier-output-control-remediation-plan-no-apply.md:187:| summary | qwen2.5:0.5b | small/medium instruction model | Needs repeatability |
docs/stage-16-fc-k-model-tier-output-control-remediation-plan-no-apply.md:188:| json_response | qwen2.5:0.5b | backend-enforced JSON first | Do not trust raw model-only JSON |
docs/stage-16-fc-k-model-tier-output-control-remediation-plan-no-apply.md:189:| companion_chat | qwen2.5:0.5b | companion model tier | Current tiny model failed repeatability |
docs/stage-16-fc-k-model-tier-output-control-remediation-plan-no-apply.md:190:| study_tutor | qwen2.5:0.5b | study/tutor model tier | Needs stronger model/rubric |
docs/stage-16-fc-k-model-tier-output-control-remediation-plan-no-apply.md:191:| flashcards | qwen2.5:0.5b | study/flashcard model plus schema | Needs structured backend card output |
docs/stage-16-fc-k-model-tier-output-control-remediation-plan-no-apply.md:192:| safe_refusal | qwen2.5:0.5b | policy-aware model plus template | Safety-sensitive lane remains blocked |
docs/stage-16-e2o-ct203-temporary-secondary-lan-ip-candidate-plan-no-apply.md:118:no worker/model/scheduler activation occurs
docs/stage-16-e3z-cw-r3-ct101-worker-bounded-one-shot-activation-plan-no-apply-recovery.md:35:The first activation should be a bounded one-shot proof, not a persistent worker rollout.
docs/stage-16-e3z-cw-r3-ct101-worker-bounded-one-shot-activation-plan-no-apply-recovery.md:52:Use qwen2.5:0.5b first.
docs/stage-16-e3z-cw-r3-ct101-worker-bounded-one-shot-activation-plan-no-apply-recovery.md:65:requested_model: qwen2.5:0.5b
docs/stage-16-e3z-cw-r3-ct101-worker-bounded-one-shot-activation-plan-no-apply-recovery.md:78:- requested_model qwen2.5:0.5b
docs/stage-16-e3z-cw-r3-ct101-worker-bounded-one-shot-activation-plan-no-apply-recovery.md:82:- no scheduler/timer activation
docs/stage-16-e3z-cw-r3-ct101-worker-bounded-one-shot-activation-plan-no-apply-recovery.md:103:- verify no scheduler/timer activation
docs/stage-16-e3z-cw-r3-ct101-worker-bounded-one-shot-activation-plan-no-apply-recovery.md:165:- requested_model is qwen2.5:0.5b
docs/stage-16-e3z-cw-r3-ct101-worker-bounded-one-shot-activation-plan-no-apply-recovery.md:174:- qwen2.5:0.5b is present
docs/stage-16-e3z-cw-r3-ct101-worker-bounded-one-shot-activation-plan-no-apply-recovery.md:187:- no scheduler/timer activation
docs/stage-16-e3z-cw-r3-ct101-worker-bounded-one-shot-activation-plan-no-apply-recovery.md:220:- systemd timer activation
docs/stage-16-fc-o45-e-aa-r7-result-read-mirror-auth-header.md:24:No DB write, no job mutation, no worker/model/helper/runtime call, no scheduler/timer activation, no schema change, no CT/VM restart, no nginx/cloudflared mutation, and no storage mutation.
docs/stage-16-e3i-run-one-shot-model-adapter-no-write.md:64:- No scheduler activation.
docs/stage-5g18-default-model-alias-and-bounded-real-user-completion.md:39:- Does not enable persistent worker runtime.
docs/stage-16-e2z-model-serving-path-decision-no-model-call.md:17:- No scheduler activation.
```
