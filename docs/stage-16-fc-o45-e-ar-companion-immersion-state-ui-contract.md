# Stage 16 FC-O45-E-AR — Companion Immersion State UI Contract

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `9a55d71`
- Prior tag: `controller-stage-16-fc-o45-e-aq-companion-study-tools-endpoint-routing-contract-2026-06-24`

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

## Product idea

Add a Companion **Immersion Mode**.

Instead of making the main Companion area look like a debug transcript, the UI should show:

```
last user message
current Companion state
last Companion response when available
```

This is meant to make the Companion feel like an assistant that is listening, thinking, and speaking.

## State model

| Job/UI condition | Immersion state | User-facing label |
|---|---|---|
| No active job and input is ready | `listening` | Listening |
| Message submitted and job id returned | `thinking` | Thinking |
| Job status is `queued` | `thinking` | Thinking |
| Job status is `running` or worker claimed | `thinking` | Thinking |
| Job status is `completed` and result exists | `speaking` | Speaking |
| Result has been displayed and no active job remains | `listening` | Listening |
| Job is `failed`, missing, unauthorized, or malformed | `needs_attention` | Needs attention |

## Main UI behavior

The current Conversation panel can be simplified.

Recommended visible content:

```
You: <last user message>

Companion: <state label>
<last response if available>
```

Example while queued:

```
You: Study session start

Companion: Thinking...
```

Example when completed:

```
You: Hello! How can I assist you today?

Companion: Speaking
Hello! Feel free to ask any questions or let me know how I can help today!
```

Example when idle:

```
Companion: Listening
```

## Debug details should be secondary

Debug details should not be the main user experience.

These details can remain available in a small expandable area:

- job id,
- queue status,
- worker name,
- model,
- requested_model,
- result-reader HTTP status,
- queue_write value.

The default Companion experience should prioritize:

1. last user message,
2. current state,
3. last assistant result,
4. optional details.

## Study Tools compatibility

Immersion Mode fits the Study Tools bridge.

| Study phrase | State transition | Confirmation |
|---|---|---|
| `Study session start` | listening -> thinking -> speaking | Study session started. |
| `Study session pause` | listening -> thinking -> speaking | Study session paused. |
| `Study session resume` | listening -> thinking -> speaking | Study session resumed. |
| `Study session stop` | listening -> thinking -> speaking | Study session stopped. |
| `Read the answer` | listening -> thinking -> speaking | Reveals or reads answer. |
| `Correct` | listening -> thinking -> speaking | Marked correct. |
| `Wrong` | listening -> thinking -> speaking | Marked wrong. |
| `Skip` | listening -> thinking -> speaking | Skipped. |

Study Tool actions can use the same state display even when no model generation is needed.

## Recommended implementation order

Do not combine this with Study state mutation yet.

Recommended next phase:

```
FC-O45-E-AS — repo-only Companion Immersion UI scaffold
```

AS should be source-only and should:

1. add a small state mapping helper,
2. keep the existing result-reader and queue calls,
3. change only the visible Companion panel presentation,
4. keep debug details available,
5. avoid backend changes,
6. avoid deploy/service restart unless separately approved.

After AS source-only, a later deploy/runtime phase can publish the UI.

## Acceptance criteria for source-only UI scaffold

The source-only implementation should include markers for:

- `Companion Immersion Mode`
- `listening`
- `thinking`
- `speaking`
- `needs_attention`
- `last user message`
- `debug details`
- existing `/api/chat/queued` compatibility
- existing owner-scoped result-reader compatibility

## Live source inventory

```
=== Stage 16 FC-O45-E-AR Companion Immersion state UI contract ===
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
expected_head=9a55d71
head_now=9a55d71
origin_main_now=9a55d71
git_preflight=PASS

=== Companion UI/state inventory ===
frontend/study-ui/app.js:89:    $("workerStatusText").textContent = `Jobs forwarded: ${data.queue?.forwarded ?? 0}`;
frontend/study-ui/app.js:93:    $("workerStatusText").textContent = err.message;
frontend/study-ui/app.js:403:    el.innerHTML = "Review queue complete. Load another queue or change mode.";
frontend/study-ui/app.js:501:    $("passwordInput").autocomplete = mode === "register" ? "new-password" : "current-password";
frontend/study-ui/app.js:600:state.companionQueue = [];
frontend/study-ui/app.js:601:state.companionIndex = 0;
frontend/study-ui/app.js:602:state.companionCurrentCard = null;
frontend/study-ui/app.js:603:state.companionPendingUnsure = null;
frontend/study-ui/app.js:605:function companionAddMessage(role, text) {
frontend/study-ui/app.js:606:  const chat = $("companionChat");
frontend/study-ui/app.js:616:function companionClearChat() {
frontend/study-ui/app.js:617:  const chat = $("companionChat");
frontend/study-ui/app.js:623:  const select = $("companionDeckSelect");
frontend/study-ui/app.js:649:async function companionStartQueue() {
frontend/study-ui/app.js:655:  const deckId = $("companionDeckSelect").value;
frontend/study-ui/app.js:656:  const mode = $("companionReviewMode").value;
frontend/study-ui/app.js:659:    companionClearChat();
frontend/study-ui/app.js:660:    companionAddMessage("assistant", "Please select a deck first.");
frontend/study-ui/app.js:665:    companionClearChat();
frontend/study-ui/app.js:666:    companionAddMessage("assistant", "Loading your review queue...");
frontend/study-ui/app.js:672:    state.companionQueue = data.cards || [];
frontend/study-ui/app.js:673:    state.companionIndex = 0;
frontend/study-ui/app.js:674:    state.companionPendingUnsure = null;
frontend/study-ui/app.js:676:    companionClearChat();
frontend/study-ui/app.js:678:    if (!state.companionQueue.length) {
frontend/study-ui/app.js:679:      companionAddMessage("assistant", "This deck does not have cards yet. Add cards on the Study page first.");
frontend/study-ui/app.js:683:    companionAddMessage(
frontend/study-ui/app.js:688:    companionAskCurrentCard();
frontend/study-ui/app.js:690:    companionClearChat();
frontend/study-ui/app.js:691:    companionAddMessage("assistant", `I could not load the queue: ${err.message}`);
frontend/study-ui/app.js:695:function companionAskCurrentCard() {
frontend/study-ui/app.js:696:  const card = state.companionQueue[state.companionIndex];
frontend/study-ui/app.js:697:  state.companionCurrentCard = card || null;
frontend/study-ui/app.js:698:  state.companionPendingUnsure = null;
frontend/study-ui/app.js:700:  $("companionConfirmActions")?.classList.add("hidden");
frontend/study-ui/app.js:703:    companionAddMessage("assistant", "Review complete. Load another queue when you are ready.");
frontend/study-ui/app.js:708:  const count = `${state.companionIndex + 1}/${state.companionQueue.length}`;
frontend/study-ui/app.js:710:  companionAddMessage(
frontend/study-ui/app.js:715:  $("companionAnswerInput").value = "";
frontend/study-ui/app.js:716:  $("companionAnswerInput").focus();
frontend/study-ui/app.js:719:async function companionSubmitAnswer(event) {
frontend/study-ui/app.js:722:  const card = state.companionCurrentCard;
frontend/study-ui/app.js:724:    companionAddMessage("assistant", "Load a review queue first.");
frontend/study-ui/app.js:728:  const answer = $("companionAnswerInput").value.trim();
frontend/study-ui/app.js:731:  companionAddMessage("user", answer);
frontend/study-ui/app.js:732:  $("companionAnswerInput").value = "";
frontend/study-ui/app.js:735:    const data = await api("/companion/study/grade", {
frontend/study-ui/app.js:745:      companionAddMessage("assistant", `Correct. ${data.feedback}`);
frontend/study-ui/app.js:746:      await companionAfterRecordedReview();
frontend/study-ui/app.js:751:      companionAddMessage(
frontend/study-ui/app.js:755:      await companionAfterRecordedReview();
frontend/study-ui/app.js:759:    state.companionPendingUnsure = {
frontend/study-ui/app.js:765:    companionAddMessage(
frontend/study-ui/app.js:770:    $("companionConfirmActions")?.classList.remove("hidden");
frontend/study-ui/app.js:772:    companionAddMessage("assistant", `I could not grade that answer: ${err.message}`);
frontend/study-ui/app.js:776:async function companionRecordManualReview(wasCorrect) {
frontend/study-ui/app.js:777:  const pending = state.companionPendingUnsure;
frontend/study-ui/app.js:778:  const card = pending?.card || state.companionCurrentCard;
frontend/study-ui/app.js:792:  companionAddMessage("assistant", wasCorrect ? "Marked correct." : "Marked wrong.");
frontend/study-ui/app.js:793:  $("companionConfirmActions")?.classList.add("hidden");
frontend/study-ui/app.js:795:  await companionAfterRecordedReview();
frontend/study-ui/app.js:798:async function companionAfterRecordedReview() {
frontend/study-ui/app.js:805:  state.companionIndex += 1;
frontend/study-ui/app.js:806:  state.companionPendingUnsure = null;
frontend/study-ui/app.js:808:  setTimeout(() => companionAskCurrentCard(), 350);
frontend/study-ui/app.js:811:const companionLoadQueueBtn = $("companionLoadQueueBtn");
frontend/study-ui/app.js:812:if (companionLoadQueueBtn) {
frontend/study-ui/app.js:813:  companionLoadQueueBtn.addEventListener("click", companionStartQueue);
frontend/study-ui/app.js:816:const companionAnswerForm = $("companionAnswerForm");
frontend/study-ui/app.js:817:if (companionAnswerForm) {
frontend/study-ui/app.js:818:  companionAnswerForm.addEventListener("submit", companionSubmitAnswer);
frontend/study-ui/app.js:821:const companionConfirmCorrectBtn = $("companionConfirmCorrectBtn");
frontend/study-ui/app.js:822:if (companionConfirmCorrectBtn) {
frontend/study-ui/app.js:823:  companionConfirmCorrectBtn.addEventListener("click", () => companionRecordManualReview(true));
frontend/study-ui/app.js:826:const companionConfirmWrongBtn = $("companionConfirmWrongBtn");
frontend/study-ui/app.js:827:if (companionConfirmWrongBtn) {
frontend/study-ui/app.js:828:  companionConfirmWrongBtn.addEventListener("click", () => companionRecordManualReview(false));
frontend/study-ui/app.js:845:    // PHASE_14I_X_STUDY_UI_LEGACY_JOBS_FALLBACK_FLAG: default-enabled legacy jobs fallback.
frontend/study-ui/app.js:880:  function loadJson(key, fallback) {
frontend/study-ui/app.js:882:      return JSON.parse(localStorage.getItem(key) || JSON.stringify(fallback));
frontend/study-ui/app.js:884:      return fallback;
frontend/study-ui/app.js:969:    const err = new Error(message || "Temporary gateway issue while the companion is responding.");
frontend/study-ui/app.js:981:      throw transientGatewayError("Network/proxy connection interrupted while the companion was responding.");
frontend/study-ui/app.js:996:          `Temporary gateway error ${res.status || ""}. The companion may still be working.`,
frontend/study-ui/app.js:1025:      `${base}/chat/queued/${encodeURIComponent(jobId)}`,
frontend/study-ui/app.js:1044:          if (["forwarded", "done", "complete", "completed", "succeeded", "success"].includes(String(status).toLowerCase()) && text) {
frontend/study-ui/app.js:1048:          if (text && !/queued|poll|pending|running/i.test(text)) return text;
frontend/study-ui/app.js:1055:        addCompanionMessage("system", "The companion is still thinking. I am waiting for the queued response instead of showing a gateway error.");
frontend/study-ui/app.js:1061:    return `Your message was queued as job ${jobId}, but the browser could not fetch the final answer yet. Refresh in a moment or try again.`;
frontend/study-ui/app.js:1089:      "You are the user's AI study companion.",
frontend/study-ui/app.js:1104:      // PHASE_14I_U_STUDY_UI_QUEUED_CHAT_ADAPTER: prefer app_jobs queued chat before legacy local jobs.
frontend/study-ui/app.js:1106:        url: `${base}/chat/queued`,
frontend/study-ui/app.js:1107:        body: { message: prompt, requested_model: "gemma4:e4b" },
frontend/study-ui/app.js:1112:      // COMPANION_JOB_FIRST_V1: keep legacy local jobs fallback during migration.
frontend/study-ui/app.js:1115:        body: { job_type: "ollama_chat", prompt, requested_model: "gemma4:e4b" },
frontend/study-ui/app.js:1125:        url: `${base}/companion/chat`,
frontend/study-ui/app.js:1144:          if (String(status).toLowerCase() === "queued") {
frontend/study-ui/app.js:1145:            addCompanionMessage("system", `Queued with Gemma E4B as job ${jobId}. Waiting for the worker...`);
frontend/study-ui/app.js:1150:        if (directText && !/queued|poll|pending|running/i.test(directText)) return directText;
frontend/study-ui/app.js:1168:        text: "Hi, I am your study companion. Ask me what to study, paste an answer for me to check, or ask me to help make a card.",
frontend/study-ui/app.js:1177:  function renderCompanionMessages() {
frontend/study-ui/app.js:1178:    const wrap = document.getElementById("companionMessages");
frontend/study-ui/app.js:1193:    renderCompanionMessages();
frontend/study-ui/app.js:1197:    const input = document.getElementById("companionInput");
frontend/study-ui/app.js:1198:    const sendBtn = document.getElementById("companionSendBtn");
frontend/study-ui/app.js:1199:    const status = document.getElementById("companionMessage");
frontend/study-ui/app.js:1217:        ? "The companion may still be working, but the gateway timed out before the browser received the final response. I did not save the raw Cloudflare error page. Refresh in a moment or try again."
frontend/study-ui/app.js:1222:        "I could not finish the companion response yet.\n\n" + cleanError
frontend/study-ui/app.js:1231:    renderCompanionMessages();
frontend/study-ui/app.js:1233:    const form = document.getElementById("companionForm");
frontend/study-ui/app.js:1234:    const clearBtn = document.getElementById("companionClearBtn");
frontend/study-ui/app.js:1235:    const suggestBtn = document.getElementById("companionStudySuggestBtn");
frontend/study-ui/app.js:1249:        renderCompanionMessages();
frontend/study-ui/_headers:2:  Content-Security-Policy: default-src 'self'; connect-src 'self' https://alexhartel.com https://companion.alexhartel.com https://calendar.alexhartel.com https://profile.alexhartel.com; script-src 'self'; style-src 'self'; img-src 'self' data:; font-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self' https://alexhartel.com
frontend/study-ui/styles.css:513:.companion-layout {
frontend/study-ui/styles.css:518:.companion-controls {
frontend/study-ui/styles.css:525:.companion-chat {
frontend/study-ui/styles.css:563:.companion-answer {
frontend/study-ui/styles.css:569:.companion-actions {
frontend/study-ui/styles.css:576:  .companion-controls,
frontend/study-ui/styles.css:577:  .companion-answer {
frontend/study-ui/styles.css:581:  .companion-actions {
frontend/study-ui/styles.css:589:.companion-layout {
frontend/study-ui/styles.css:594:.companion-chat {
frontend/study-ui/styles.css:633:.companion-form textarea {
frontend/study-ui/study-content.partial.html:15:          <span id="workerStatusText">Worker proxy</span>
frontend/study-ui/study-content.partial.html:35:            <h3>AI companion</h3>
frontend/study-ui/study-content.partial.html:36:            <p>Chat with your companion, ask what to study, and get help based on your study cards.</p>
frontend/study-ui/study-content.partial.html:37:            <button class="secondary" type="button" data-page-link="companion">Open Companion</button>
frontend/study-ui/study-content.partial.html:51:            <p>Study cards are active. Companion now uses the worker proxy and Gemma E4B queue path when available.</p>
frontend/study-ui/study-content.partial.html:60:      <section class="panel page-block hidden" data-page="companion" id="companionPanel">
frontend/study-ui/study-content.partial.html:68:          The full companion runs in the AI Platform app. It is designed for conversation,
frontend/study-ui/study-content.partial.html:71:        <a class="primary" href="https://alexhartel.com/companion">Open Full Companion</a>
frontend/study-ui/study-content.partial.html:82:          The full calendar/reminder system belongs in the AI Platform app so the companion
frontend/study-ui/index.html:25:        <a class="app-shell-link nav-link" href="https://alexhartel.com/companion">Companion</a>
frontend/study-ui/index.html:45:          <span id="workerStatusText">Worker proxy</span>
frontend/study-ui/index.html:65:            <h3>AI companion</h3>
frontend/study-ui/index.html:66:            <p>Chat with your companion, ask what to study, and get help based on your study cards.</p>
frontend/study-ui/index.html:67:            <button class="secondary" type="button" data-page-link="companion">Open Companion</button>
frontend/study-ui/index.html:81:            <p>Study cards are active. Companion now uses the worker proxy and Gemma E4B queue path when available.</p>
frontend/study-ui/index.html:90:      <section class="panel page-block hidden" data-page="companion" id="companionPanel">
frontend/study-ui/index.html:98:          The full companion runs in the AI Platform app. It is designed for conversation,
frontend/study-ui/index.html:101:        <a class="primary" href="https://alexhartel.com/companion">Open Full Companion</a>
frontend/study-ui/index.html:112:          The full calendar/reminder system belongs in the AI Platform app so the companion
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:26:      <a href="/companion" data-route="/companion">Companion</a>
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:99:          <input id="authEmail" type="email" autocomplete="email" required />
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:104:          <input id="authPassword" type="password" autocomplete="current-password" required />
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:117:  <script src="/queued_chat_config.js"></script>
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:118:<script src="/queued_chat_status.js"></script>
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1667:body[data-current-route="/companion"] .topbar,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:56:// can decide whether /study, /chat, /companion, /calendar, and /profile should proxy
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:129:const PRIVATE_APP_ROUTE_SET = new Set(["/study-wrapper-preview", "/study", "/chat", "/companion", "/calendar", "/profile"]);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:155:      "Practice smarter with study tools, guided review, and an AI companion designed to help you focus on what matters most.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:158:      ["Companion", "Use Companion for general conversation, study help, explanations, and supportive conversation.", "/companion"],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:159:      ["Profile", "Manage preferences, permissions, account settings, and future companion personalization.", "/profile"],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:164:      ["AI support", "The companion can eventually use study history, profile settings, and calendar context to support learning."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:186:      ["Future companion support", "The companion can help grade answers and explain difficult concepts."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:197:      ["Companion", "General local-first AI conversation through the existing queued worker path."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:199:      ["Compatibility", "/chat stays available for old links while /companion is the primary route."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:204:  "/companion": {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:239:      ["Permissions", "Control what data the companion and tools are allowed to use."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:249:      "Credits control access to higher-cost features like AI jobs, companion usage, image generation, storage, and future premium tools.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:313: * - /api/companion/* = laptop controller-owned Companion API
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:686:  "workers",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:687:  "ct101-laptop-queue-worker",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:703:  workers: "Worker capacity and processing services.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:704:  "ct101-laptop-queue-worker": "Managed CT101 worker processing queued chat jobs with guarded one-at-a-time execution.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:848:function normalizeApiState(service, fallback = "planned") {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:849:  if (!service) return fallback;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:857:  return service.state || fallback;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:860:function normalizeApiDetail(service, fallback) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:861:  if (!service) return fallback;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:869:  return service.detail || fallback;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:883:      id: "companion-api",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:904:      detail: "Future ComfyUI-backed image generation for companion images and user-requested visuals.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1002:        const isReserved = item.status === "reserved";
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1343:            ${session.status === "running" ? `
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2256:          Credits are the platform currency for companion usage, AI jobs, storage, RAG indexing,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2264:            <p>Can only be used on local platform services running on your hardware.</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2300:            <p>Used for uploaded files, future RAG data, generated assets, and companion memory.</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2484:            <li>Basic companion usage</li>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2492:          <p>For regular study and companion use.</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2496:            <li>More companion messages</li>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2713:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2762:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2873:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2940:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3120:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3224:            : "Shared-wrapper candidate route for Study. Use this to verify behavior before removing the standalone fallback."}
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3255:const queuedChatUiState = {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3261:function queuedChatEscape(value) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3270:function queuedChatSetStatus(text) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3271:  const el = document.getElementById("queuedChatStatus");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3275:function queuedChatRenderMessages() {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3276:  const el = document.getElementById("queuedChatMessages");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3279:  if (!queuedChatUiState.messages.length) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3280:    el.innerHTML = `<p class="muted">Send a message to start a queued local AI chat.</p>`;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3284:  el.innerHTML = queuedChatUiState.messages.map((msg) => `
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3286:      <span>${queuedChatEscape(msg.role)}</span>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3287:      <strong>${queuedChatEscape(msg.content)}</strong>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3288:      ${msg.detail ? `<p>${queuedChatEscape(msg.detail)}</p>` : ""}
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3301:        Send a message through the existing laptop-owned queued AI path. CT101 processes one Ollama job at a time while the UI presents one main Companion surface.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3308:            <strong id="queuedChatStatus">Ready</strong>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3309:            <p>Uses the existing queued worker path and polls the returned job id.</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3313:            <strong>Companion queue worker</strong>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3314:            <p>Current model fallback: gemma4:e4b.</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3318:        <form id="queuedChatForm" class="form-grid">
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3321:            <textarea id="queuedChatInput" rows="5" placeholder="Ask Companion something..."></textarea>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3325:            <button class="primary-btn" type="submit" id="queuedChatSendBtn">Send message</button>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3326:            <button class="ghost-btn" type="button" id="queuedChatClearBtn">Clear</button>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3331:          <h2>Conversation</h2>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3332:          <div id="queuedChatMessages" class="summary-grid"></div>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3348:async function queuedChatPollJob(jobId) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3350:    queuedChatSetStatus(`Waiting for worker... poll ${i + 1}`);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3366:    if (status === "complete" || status === "completed") {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3371:        detail: `job ${jobId} · ${result.model || job.requested_model || "model unknown"}`
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3375:    if (status === "failed" || status === "error") {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3385:async function queuedChatSubmit(event) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3388:  if (queuedChatUiState.busy) return;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3390:  const input = document.getElementById("queuedChatInput");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3391:  const button = document.getElementById("queuedChatSendBtn");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3395:    queuedChatSetStatus("Enter a message first.");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3399:  queuedChatUiState.busy = true;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3402:  queuedChatUiState.messages.push({ role: "You", content: message });
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3403:  queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3408:    queuedChatSetStatus("Creating queued job...");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3416:        requested_model: "gemma4:e4b",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3434:    queuedChatUiState.lastJobId = jobId;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3435:    queuedChatUiState.messages.push({
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3440:    queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3442:    const final = await queuedChatPollJob(jobId);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3444:    queuedChatUiState.messages.push({
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3449:    queuedChatSetStatus("Complete");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3450:    queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3452:    queuedChatUiState.messages.push({
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3456:    queuedChatSetStatus("Error");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3457:    queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3459:    queuedChatUiState.busy = false;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3465:  queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3467:  const form = document.getElementById("queuedChatForm");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3469:    form.onsubmit = queuedChatSubmit;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3472:  const clearBtn = document.getElementById("queuedChatClearBtn");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3475:      queuedChatUiState.messages = [];
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3476:      queuedChatSetStatus("Ready");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3477:      queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3512:      path === "/companion" ||
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3542:  "/companion": {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3544:    title: "A queued local AI companion for study and support.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3545:    body: "Send messages through the local queued AI path so the website stays responsive while your worker processes the response.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3547:      ["Queued responses", "Messages are submitted as jobs and polled until complete."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3548:      ["Study context", "Future companion features can use allowed study context."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3549:      ["Local-first", "Designed around your local server and worker queue."]
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3558:      ["Permissions", "Control what tools and companion features can access."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3567:      ["Free/local credits", "For local services running on your hardware."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3641:      path === "/companion" ||
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3691:  if (path === "/chat" || path === "/companion") {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3693:      renderPublicFeatureGate(path === "/chat" ? "/chat" : "/companion");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:4510:  cleanAdminUsers = users.status === "fulfilled"
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:4514:  cleanAdminTickets = tickets.status === "fulfilled"
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:4518:  cleanAdminSystem = system.status === "fulfilled"
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:4682:  if (status === "solved") {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:4688:  if (status === "waiting_admin") {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:4790:          <span>Study and companion</span>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:4792:          <p>Report issues with decks, reviews, companion replies, or learning workflows.</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:4848:      <p>Send a message if you need account, credit, billing, study, companion, or platform help.</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:5175:    t.status === "waiting_user"
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6260: * Stage 5F-31: queued-chat frontend flag detection.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6262: * This block intentionally does not wire queued chat send behavior.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6263: * It only records whether the disabled-by-default queued-chat frontend flag is enabled.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6266: * - queued chat remains disabled by default
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6268: * - does not call the queued chat API route
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6269: * - does not use the queued chat status helper yet
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6280:    source: "app_js_queued_chat_flag_detection",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6283:    queuedSendWired: false,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6288: * Stage 5F-32: disabled queued-chat send branch.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6290: * This block defines a future queued-chat send helper, but intentionally does not
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6294: * - branch is gated by the disabled-by-default queued-chat frontend flag
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6310:        reason: "queued_chat_disabled_stage_5f32",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6323:    if (payload && payload.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6324:      cleanPayload.requested_model = String(payload.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6327:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6351:    source: "app_js_disabled_queued_send_branch",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6358: * Stage 5F-35: disabled queued-chat status polling branch.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6360: * This block defines a future queued-chat status polling helper, but intentionally
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6364: * - branch is gated by the disabled-by-default queued-chat frontend flag
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6381:        reason: "queued_status_poll_disabled_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6388:    if (!helper || typeof helper.queuedChatBuildStatusView !== "function") {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6391:        error: "queued_status_helper_missing_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6404:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6424:    const view = helper.queuedChatBuildStatusView(job, elapsedMs);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6436:    source: "app_js_disabled_queued_status_poll_branch",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6443: * Stage 5F-37: disabled queued-chat assistant placeholder branch.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6445: * This block defines a future queued-chat assistant placeholder helper, but
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6449: * - branch is gated by the disabled-by-default queued-chat frontend flag
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6466:        reason: "queued_placeholder_disabled_stage_5f37",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6473:    if (!helper || typeof helper.queuedChatBuildStatusView !== "function") {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6476:        error: "queued_placeholder_helper_missing_stage_5f37",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6481:    const view = helper.queuedChatBuildStatusView(job || {}, elapsedMs);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6487:      placeholderText: view.placeholder || "Waiting for queued response status.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6495:    source: "app_js_disabled_queued_assistant_placeholder_branch",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6502: * Stage 5F-40: disabled queued-chat submit decision branch.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6504: * This block defines a future decision helper for selecting the queued-chat
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6508: * - decision is gated by the disabled-by-default queued-chat frontend flag
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6529:        reason: "queued_chat_flag_disabled_stage_5f40",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6537:     * Even if a mocked send branch reports wiredToSubmit=true, queued submit
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6545:        reason: "queued_chat_decision_not_wired_stage_5f41",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6556:        reason: "queued_chat_submit_not_wired_stage_5f40",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6566:      reason: "queued_chat_submit_selected_stage_5f40",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6572:        hasModel: Boolean(context && context.requested_model),
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6579:    source: "app_js_disabled_queued_submit_decision_branch",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6586: * Stage 5F-45: disabled queued-chat submit dry-run branch.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6589: * could use the queued-chat path, but intentionally does not wire it into
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6593: * - dry-run is gated by the disabled-by-default queued-chat frontend flag
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6621:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6622:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6628:      source: "app_js_disabled_queued_submit_dry_run_branch",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6632:      reason: enabled ? "queued_submit_dry_run_unwired_stage_5f45" : "queued_submit_dry_run_flag_disabled_stage_5f45",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6648:    source: "app_js_disabled_queued_submit_dry_run_branch",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6655: * Stage 5F-48: disabled queued-chat submit payload builder branch.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6657: * This block defines a future queued-chat submit payload builder, but
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6663: * - builds only message, chat_id, and requested_model
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6694:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6695:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6701:      source: "app_js_disabled_queued_submit_payload_builder_branch",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6709:    source: "app_js_disabled_queued_submit_payload_builder_branch",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6716: * Stage 5F-51: disabled queued-chat submit orchestration branch.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6718: * This block defines a future queued-chat submit orchestration helper, but
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6740:        reason: "queued_orchestration_flag_disabled_stage_5f51",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6758:        error: "queued_orchestration_payload_helper_missing_stage_5f51",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6771:        error: "queued_orchestration_payload_failed_stage_5f51",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6782:        error: "queued_orchestration_decision_helper_missing_stage_5f51",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6795:        error: "queued_orchestration_decision_refused_stage_5f51",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6808:        error: "queued_orchestration_send_helper_missing_stage_5f51",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6821:        error: "queued_orchestration_send_failed_stage_5f51",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6836:          status: "queued",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6852:      source: "app_js_disabled_queued_submit_orchestration_branch",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6868:    source: "app_js_disabled_queued_submit_orchestration_branch",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6876: * Stage 5F-57: disabled guarded queued submit skeleton branch.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6884: * - does not call queued orchestration
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6885: * - does not call queued send
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6886: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6887: * - does not render queued placeholders
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6899:      source: "app_js_disabled_guarded_queued_submit_skeleton_branch",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6903:      queuedSubmitSelected: false,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6905:        ? "guarded_queued_submit_skeleton_unwired_stage_5f57"
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6906:        : "guarded_queued_submit_skeleton_flag_disabled_stage_5f57",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6928:    source: "app_js_disabled_guarded_queued_submit_skeleton_branch",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6944: * - does not call queued orchestration
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6945: * - does not call queued send
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6946: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6947: * - does not render queued placeholders
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6969:        "single_queued_send",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7005: * - does not call queued orchestration
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7006: * - does not call queued send
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7007: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7008: * - does not render queued placeholders
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7026:      queuedSubmitAllowed: false,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7031:        "queued_orchestration",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7032:        "queued_send",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7033:        "queued_polling",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7034:        "queued_placeholder",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7035:        "queued_final_render"
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7067: * - does not call queued orchestration
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7068: * - does not call queued send
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7069: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7070: * - does not render queued placeholders
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7090:      queuedSubmitAllowed: false,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7097:        "queued_orchestration",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7098:        "queued_send",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7099:        "queued_placeholder",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7100:        "queued_polling",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7101:        "queued_final_render"
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7143:    "/companion",
frontend/wrapper-ui/index.html.bak-stage5o24-study-format-cleanup-2026-06-11-121612:26:      <a href="/companion" data-route="/companion">Companion</a>
frontend/wrapper-ui/index.html.bak-stage5o24-study-format-cleanup-2026-06-11-121612:99:          <input id="authEmail" type="email" autocomplete="email" required />
frontend/wrapper-ui/index.html.bak-stage5o24-study-format-cleanup-2026-06-11-121612:104:          <input id="authPassword" type="password" autocomplete="current-password" required />
frontend/wrapper-ui/index.html.bak-stage5o24-study-format-cleanup-2026-06-11-121612:117:  <script src="/queued_chat_config.js"></script>
frontend/wrapper-ui/index.html.bak-stage5o24-study-format-cleanup-2026-06-11-121612:118:<script src="/queued_chat_status.js"></script>
frontend/wrapper-ui/index.html.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:26:      <a href="/companion" data-route="/companion">Companion</a>
frontend/wrapper-ui/index.html.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:99:          <input id="authEmail" type="email" autocomplete="email" required />
frontend/wrapper-ui/index.html.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:104:          <input id="authPassword" type="password" autocomplete="current-password" required />
frontend/wrapper-ui/index.html.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:117:  <script src="/queued_chat_config.js"></script>
frontend/wrapper-ui/index.html.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:118:<script src="/queued_chat_status.js"></script>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:56:// can decide whether /study, /chat, /companion, /calendar, and /profile should proxy
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:129:const PRIVATE_APP_ROUTE_SET = new Set(["/study-wrapper-preview", "/study", "/chat", "/companion", "/calendar", "/profile"]);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:155:      "Practice smarter with study tools, guided review, and an AI companion designed to help you focus on what matters most.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:158:      ["Companion", "Use Companion for general conversation, study help, explanations, and supportive conversation.", "/companion"],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:159:      ["Profile", "Manage preferences, permissions, account settings, and future companion personalization.", "/profile"],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:164:      ["AI support", "The companion can eventually use study history, profile settings, and calendar context to support learning."],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:186:      ["Future companion support", "The companion can help grade answers and explain difficult concepts."],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:197:      ["Companion", "General local-first AI conversation through the existing queued worker path."],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:199:      ["Compatibility", "/chat stays available for old links while /companion is the primary route."],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:204:  "/companion": {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:239:      ["Permissions", "Control what data the companion and tools are allowed to use."],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:249:      "Credits control access to higher-cost features like AI jobs, companion usage, image generation, storage, and future premium tools.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:313: * - /api/companion/* = laptop controller-owned Companion API
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:686:  "workers",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:687:  "ct101-laptop-queue-worker",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:703:  workers: "Worker capacity and processing services.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:704:  "ct101-laptop-queue-worker": "Managed CT101 worker processing queued chat jobs with guarded one-at-a-time execution.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:848:function normalizeApiState(service, fallback = "planned") {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:849:  if (!service) return fallback;
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:857:  return service.state || fallback;
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:860:function normalizeApiDetail(service, fallback) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:861:  if (!service) return fallback;
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:869:  return service.detail || fallback;
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:883:      id: "companion-api",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:904:      detail: "Future ComfyUI-backed image generation for companion images and user-requested visuals.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:1002:        const isReserved = item.status === "reserved";
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:1343:            ${session.status === "running" ? `
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2256:          Credits are the platform currency for companion usage, AI jobs, storage, RAG indexing,
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2264:            <p>Can only be used on local platform services running on your hardware.</p>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2300:            <p>Used for uploaded files, future RAG data, generated assets, and companion memory.</p>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2484:            <li>Basic companion usage</li>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2492:          <p>For regular study and companion use.</p>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2496:            <li>More companion messages</li>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2713:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2762:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2873:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2940:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3120:  const statusText = document.getElementById("workerStatusText");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3224:            : "Shared-wrapper candidate route for Study. Use this to verify behavior before removing the standalone fallback."}
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3255:const queuedChatUiState = {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3261:function queuedChatEscape(value) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3270:function queuedChatSetStatus(text) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3271:  const el = document.getElementById("queuedChatStatus");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3275:function queuedChatRenderMessages() {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3276:  const el = document.getElementById("queuedChatMessages");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3279:  if (!queuedChatUiState.messages.length) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3280:    el.innerHTML = `<p class="muted">Send a message to start a queued local AI chat.</p>`;
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3284:  el.innerHTML = queuedChatUiState.messages.map((msg) => `
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3286:      <span>${queuedChatEscape(msg.role)}</span>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3287:      <strong>${queuedChatEscape(msg.content)}</strong>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3288:      ${msg.detail ? `<p>${queuedChatEscape(msg.detail)}</p>` : ""}
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3301:        Send a message through the existing laptop-owned queued AI path. CT101 processes one Ollama job at a time while the UI presents one main Companion surface.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3308:            <strong id="queuedChatStatus">Ready</strong>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3309:            <p>Uses the existing queued worker path and polls the returned job id.</p>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3313:            <strong>Companion queue worker</strong>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3314:            <p>Current model fallback: gemma4:e4b.</p>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3318:        <form id="queuedChatForm" class="form-grid">
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3321:            <textarea id="queuedChatInput" rows="5" placeholder="Ask Companion something..."></textarea>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3325:            <button class="primary-btn" type="submit" id="queuedChatSendBtn">Send message</button>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3326:            <button class="ghost-btn" type="button" id="queuedChatClearBtn">Clear</button>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3331:          <h2>Conversation</h2>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3332:          <div id="queuedChatMessages" class="summary-grid"></div>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3348:async function queuedChatPollJob(jobId) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3350:    queuedChatSetStatus(`Waiting for worker... poll ${i + 1}`);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3366:    if (status === "complete" || status === "completed") {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3371:        detail: `job ${jobId} · ${result.model || job.requested_model || "model unknown"}`
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3375:    if (status === "failed" || status === "error") {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3385:async function queuedChatSubmit(event) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3388:  if (queuedChatUiState.busy) return;
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3390:  const input = document.getElementById("queuedChatInput");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3391:  const button = document.getElementById("queuedChatSendBtn");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3395:    queuedChatSetStatus("Enter a message first.");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3399:  queuedChatUiState.busy = true;
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3402:  queuedChatUiState.messages.push({ role: "You", content: message });
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3403:  queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3408:    queuedChatSetStatus("Creating queued job...");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3416:        requested_model: "gemma4:e4b",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3434:    queuedChatUiState.lastJobId = jobId;
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3435:    queuedChatUiState.messages.push({
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3440:    queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3442:    const final = await queuedChatPollJob(jobId);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3444:    queuedChatUiState.messages.push({
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3449:    queuedChatSetStatus("Complete");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3450:    queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3452:    queuedChatUiState.messages.push({
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3456:    queuedChatSetStatus("Error");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3457:    queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3459:    queuedChatUiState.busy = false;
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3465:  queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3467:  const form = document.getElementById("queuedChatForm");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3469:    form.onsubmit = queuedChatSubmit;
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3472:  const clearBtn = document.getElementById("queuedChatClearBtn");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3475:      queuedChatUiState.messages = [];
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3476:      queuedChatSetStatus("Ready");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3477:      queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3512:      path === "/companion" ||
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3542:  "/companion": {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3544:    title: "A queued local AI companion for study and support.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3545:    body: "Send messages through the local queued AI path so the website stays responsive while your worker processes the response.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3547:      ["Queued responses", "Messages are submitted as jobs and polled until complete."],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3548:      ["Study context", "Future companion features can use allowed study context."],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3549:      ["Local-first", "Designed around your local server and worker queue."]
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3558:      ["Permissions", "Control what tools and companion features can access."],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3567:      ["Free/local credits", "For local services running on your hardware."],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3716:          <p>Set default learning style, companion behavior, notification preferences, and display options.</p>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3739:      path === "/companion" ||
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3789:  if (path === "/chat" || path === "/companion") {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3791:      renderPublicFeatureGate(path === "/chat" ? "/chat" : "/companion");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:4619:  cleanAdminUsers = users.status === "fulfilled"
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:4623:  cleanAdminTickets = tickets.status === "fulfilled"
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:4627:  cleanAdminSystem = system.status === "fulfilled"
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:4791:  if (status === "solved") {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:4797:  if (status === "waiting_admin") {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:4899:          <span>Study and companion</span>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:4901:          <p>Report issues with decks, reviews, companion replies, or learning workflows.</p>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:4957:      <p>Send a message if you need account, credit, billing, study, companion, or platform help.</p>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:5284:    t.status === "waiting_user"
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6369: * Stage 5F-31: queued-chat frontend flag detection.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6371: * This block intentionally does not wire queued chat send behavior.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6372: * It only records whether the disabled-by-default queued-chat frontend flag is enabled.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6375: * - queued chat remains disabled by default
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6377: * - does not call the queued chat API route
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6378: * - does not use the queued chat status helper yet
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6389:    source: "app_js_queued_chat_flag_detection",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6392:    queuedSendWired: false,
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6397: * Stage 5F-32: disabled queued-chat send branch.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6399: * This block defines a future queued-chat send helper, but intentionally does not
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6403: * - branch is gated by the disabled-by-default queued-chat frontend flag
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6419:        reason: "queued_chat_disabled_stage_5f32",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6432:    if (payload && payload.requested_model) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6433:      cleanPayload.requested_model = String(payload.requested_model);

=== Study phrase and command UI inventory ===
frontend/study-ui/app.js:21:    console.warn(`[study-ui] Missing element #${id}; skipped ${eventName} listener.`);
frontend/study-ui/app.js:197:  const data = await api("/study/progress", {
frontend/study-ui/app.js:212:  const data = await api("/study/decks", {
frontend/study-ui/app.js:274:  const data = await api("/study/decks", {
frontend/study-ui/app.js:305:  await api(`/study/decks/${state.selectedDeckId}/cards`, {
frontend/study-ui/app.js:323:  const data = await api(`/study/decks/${state.selectedDeckId}/card-stats`, {
frontend/study-ui/app.js:358:          <span class="pill">Wrong streak: ${card.recent_wrong_streak || 0}</span>
frontend/study-ui/app.js:373:  const data = await api(`/study/decks/${state.selectedDeckId}/review-queue?mode=${encodeURIComponent(mode)}&limit=10`, {
frontend/study-ui/app.js:434:        <button class="secondary" data-review="wrong">Wrong</button>
frontend/study-ui/app.js:435:        <button class="primary" data-review="correct">Correct</button>
frontend/study-ui/app.js:437:      <button class="secondary" id="skipCardBtn">Skip</button>
frontend/study-ui/app.js:449:  const skipCardBtn = $("skipCardBtn");
frontend/study-ui/app.js:450:  if (skipCardBtn) {
frontend/study-ui/app.js:451:    skipCardBtn.addEventListener("click", () => {
frontend/study-ui/app.js:466:async function submitReview(cardId, wasCorrect) {
frontend/study-ui/app.js:467:  await api(`/study/cards/${cardId}/reviews`, {
frontend/study-ui/app.js:471:      was_correct: wasCorrect,
frontend/study-ui/app.js:472:      confidence: wasCorrect ? 4 : 2
frontend/study-ui/app.js:668:    const data = await api(`/study/decks/${deckId}/review-queue?mode=${encodeURIComponent(mode)}&limit=10`, {
frontend/study-ui/app.js:735:    const data = await api("/companion/study/grade", {
frontend/study-ui/app.js:745:      companionAddMessage("assistant", `Correct. ${data.feedback}`);
frontend/study-ui/app.js:767:      `${data.feedback}\n\nStored answer: ${data.card.answer}\n\nShould I mark your answer correct or wrong?`
frontend/study-ui/app.js:776:async function companionRecordManualReview(wasCorrect) {
frontend/study-ui/app.js:782:  await api(`/study/cards/${card.id}/reviews`, {
frontend/study-ui/app.js:786:      was_correct: Boolean(wasCorrect),
frontend/study-ui/app.js:787:      confidence: wasCorrect ? 4 : 2,
frontend/study-ui/app.js:792:  companionAddMessage("assistant", wasCorrect ? "Marked correct." : "Marked wrong.");
frontend/study-ui/app.js:821:const companionConfirmCorrectBtn = $("companionConfirmCorrectBtn");
frontend/study-ui/app.js:822:if (companionConfirmCorrectBtn) {
frontend/study-ui/app.js:823:  companionConfirmCorrectBtn.addEventListener("click", () => companionRecordManualReview(true));
frontend/study-ui/app.js:1529:    if (path === "/study" || path.startsWith("/study/") || hash === "#study") {
frontend/study-ui/app.js:1583:    if (window.location.pathname === "/study" || window.location.pathname.startsWith("/study/")) {
frontend/study-ui/app.js:1584:      history.replaceState(null, "", "/study#study");
frontend/study-ui/app.js:1598:        safeNavigate(`${ACCOUNT_LOGIN}?next=${encodeURIComponent("https://alexhartel.com/study")}`, "window.location.href assignment");
frontend/study-ui/app.js:1905:      window.location.pathname === "/study" ||
frontend/study-ui/app.js:1906:      window.location.pathname.startsWith("/study/");
frontend/study-ui/study-dashboard.partial.html:1:<!-- Study dashboard-only partial for wrapper preview. Runtime /study does not use this file yet. -->
frontend/study-ui/index.html:7:  <link rel="stylesheet" href="/study/styles.css" />
frontend/study-ui/index.html:24:        <a class="app-shell-link nav-link" href="https://alexhartel.com/study">Study</a>
frontend/study-ui/index.html:282:  <script src="/study/app.js?v=20260624fc044d"></script>
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:8:  <link id="studyPreviewStyles" rel="stylesheet" href="/study/styles.css?v=20260611121619" disabled />
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:25:      <a href="/study" data-route="/study">Study</a>
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1487:body:not([data-current-route="/study"]) header a[data-route="/study"],
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1488:body:not([data-current-route="/study"]) .topbar a[data-route="/study"],
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1489:body:not([data-current-route="/study"]) .main-nav a[data-route="/study"],
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1490:body:not([data-current-route="/study"]) .route-nav a[data-route="/study"] {
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1537:body[data-current-route="/study"] .brand-mark,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1538:body[data-current-route="/study"] .helper-logo,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1539:body[data-current-route="/study"] .logo-only .brand-mark {
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1544:body[data-current-route="/study"] .system-section,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1545:body[data-current-route="/study"] .summary-box,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1546:body[data-current-route="/study"] .summary-card,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1547:body[data-current-route="/study"] .feature-card {
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1551:body[data-current-route="/study"] .summary-box,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1552:body[data-current-route="/study"] .summary-card,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1553:body[data-current-route="/study"] .feature-card,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1554:body[data-current-route="/study"] .clean-card,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1555:body[data-current-route="/study"] .study-card {
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1561:body[data-current-route="/study"] h1,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1562:body[data-current-route="/study"] h2,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1563:body[data-current-route="/study"] h3,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1564:body[data-current-route="/study"] .eyebrow {
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1574:body[data-current-route="/study"] .brand,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1575:body[data-current-route="/study"] .brand *,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1576:body[data-current-route="/study"] .brand-mark,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1577:body[data-current-route="/study"] .brand-logo,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1578:body[data-current-route="/study"] .brand-logo *,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1579:body[data-current-route="/study"] .logo-only,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1580:body[data-current-route="/study"] .logo-only *,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1581:body[data-current-route="/study"] .helper-logo,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1582:body[data-current-route="/study"] .helper-logo *,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1583:body[data-current-route="/study"] svg {
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1598:body[data-current-route="/study"] .topbar,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1599:body[data-current-route="/study"] .topbar *,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1600:body[data-current-route="/study"] .brand,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1601:body[data-current-route="/study"] .brand *,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1602:body[data-current-route="/study"] .logo-only,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1603:body[data-current-route="/study"] .logo-only *,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1604:body[data-current-route="/study"] .brand-mark,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1605:body[data-current-route="/study"] .brand-logo,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1606:body[data-current-route="/study"] .helper-logo {
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1614:body[data-current-route="/study"] .topbar svg,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1615:body[data-current-route="/study"] .brand svg,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1616:body[data-current-route="/study"] .logo-only svg,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1617:body[data-current-route="/study"] .brand-mark svg,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1618:body[data-current-route="/study"] .brand-logo svg {
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1666:body[data-current-route="/study"] .topbar,
frontend/wrapper-ui/styles.css.bak-stage5o17-study-shared-style-2026-06-11-120210:1487:body:not([data-current-route="/study"]) header a[data-route="/study"],
frontend/wrapper-ui/styles.css.bak-stage5o17-study-shared-style-2026-06-11-120210:1488:body:not([data-current-route="/study"]) .topbar a[data-route="/study"],
frontend/wrapper-ui/styles.css.bak-stage5o17-study-shared-style-2026-06-11-120210:1489:body:not([data-current-route="/study"]) .main-nav a[data-route="/study"],
frontend/wrapper-ui/styles.css.bak-stage5o17-study-shared-style-2026-06-11-120210:1490:body:not([data-current-route="/study"]) .route-nav a[data-route="/study"] {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:56:// can decide whether /study, /chat, /companion, /calendar, and /profile should proxy
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:129:const PRIVATE_APP_ROUTE_SET = new Set(["/study-wrapper-preview", "/study", "/chat", "/companion", "/calendar", "/profile"]);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:157:      ["Study", "Create decks, review cards, track progress, and focus on cards that need more practice.", "/study"],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:170:  "/study-wrapper-preview": {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:177:  "/study": {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:312: * - /api/study/* = laptop controller-owned Study API
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2628:      <p>This shared-layout preview is read-only. Use <a href="/study">the live Study page</a> to create decks, add cards, or review cards.</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2664:  const wrongStreak = Number(card?.wrong_streak ?? card?.wrongStreak ?? 0);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2668:  if (wrongStreak >= 2) return "hard";
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2726:    const res = await fetch("/api/study/decks", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2734:    if (!res.ok) throw new Error(`/api/study/decks HTTP ${res.status}: ${text.slice(0, 160)}`);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2761:async function submitStudyWrapperPreviewReview(cardId, wasCorrect) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2769:    const res = await fetch(`/api/study/cards/${encodeURIComponent(cardId)}/reviews`, {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2774:        was_correct: Boolean(wasCorrect),
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2775:        confidence: wasCorrect ? 4 : 2
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2781:      throw new Error(`/api/study/cards/${cardId}/reviews HTTP ${res.status}: ${text.slice(0, 160)}`);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2842:        <button class="primary-btn" type="button" id="studyPreviewCorrectBtn">Correct</button>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2865:  document.getElementById("studyPreviewCorrectBtn")?.addEventListener("click", () => {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2886:    const res = await fetch(`/api/study/decks/${encodeURIComponent(deckId)}/review-queue?mode=${encodeURIComponent(mode)}&limit=10`, {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2893:      throw new Error(`/api/study/decks/${deckId}/review-queue HTTP ${res.status}: ${text.slice(0, 160)}`);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2964:    const res = await fetch(`/api/study/decks/${encodeURIComponent(deckId)}/cards`, {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2973:      throw new Error(`/api/study/decks/${deckId}/cards HTTP ${res.status}: ${text.slice(0, 160)}`);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3061:    const res = await fetch(`/api/study/decks/${encodeURIComponent(deckId)}/card-stats`, {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3067:    if (!res.ok) throw new Error(`/api/study/decks/${deckId}/card-stats HTTP ${res.status}: ${text.slice(0, 120)}`);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3093:          const wrongStreak = card.wrong_streak ?? card.wrongStreak ?? 0;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3102:                · Wrong streak: ${studyPreviewEscape(wrongStreak)}
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3128:      fetch("/api/study/progress", { credentials: "include", cache: "no-store" }),
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3129:      fetch("/api/study/decks", { credentials: "include", cache: "no-store" })
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3135:    if (!progressRes.ok) throw new Error(`/api/study/progress HTTP ${progressRes.status}: ${progressText.slice(0, 120)}`);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3136:    if (!decksRes.ok) throw new Error(`/api/study/decks HTTP ${decksRes.status}: ${decksText.slice(0, 120)}`);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3200:  const isLiveStudyRoute = window.location.pathname === "/study";
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3206:    const res = await fetch("/study/study-dashboard.partial.html", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3228:            <a class="primary-btn" href="/study">Open Live Study</a>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3229:            <a class="secondary" href="/study-standalone">Open Standalone Fallback</a>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3510:      path === "/study" ||
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3521:    console.warn("auth-ready rerender skipped", err);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3532:  "/study": {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3639:      path === "/study" ||
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3670:  const isStudyWrapperRoute = path === "/study-wrapper-preview" || path === "/study";
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3684:      renderPublicFeatureGate("/study");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6309:        skipped: true,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6380:        skipped: true,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6465:        skipped: true,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6738:        skipped: true,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7142:    "/study",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7156:    if (route === "/study-wrapper-preview") return "/study";
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7426:    if (route === "/study-wrapper-preview") return "/study";
frontend/wrapper-ui/index.html.bak-stage5o24-study-format-cleanup-2026-06-11-121612:8:  <link id="studyPreviewStyles" rel="stylesheet" href="/study/styles.css?v=20260611121251" disabled />
frontend/wrapper-ui/index.html.bak-stage5o24-study-format-cleanup-2026-06-11-121612:25:      <a href="/study" data-route="/study">Study</a>
frontend/wrapper-ui/index.html.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:8:  <link id="studyPreviewStyles" rel="stylesheet" href="/study/styles.css?v=20260611121619" disabled />
frontend/wrapper-ui/index.html.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:25:      <a href="/study" data-route="/study">Study</a>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:56:// can decide whether /study, /chat, /companion, /calendar, and /profile should proxy
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:129:const PRIVATE_APP_ROUTE_SET = new Set(["/study-wrapper-preview", "/study", "/chat", "/companion", "/calendar", "/profile"]);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:157:      ["Study", "Create decks, review cards, track progress, and focus on cards that need more practice.", "/study"],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:170:  "/study-wrapper-preview": {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:177:  "/study": {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:312: * - /api/study/* = laptop controller-owned Study API
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2628:      <p>This shared-layout preview is read-only. Use <a href="/study">the live Study page</a> to create decks, add cards, or review cards.</p>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2664:  const wrongStreak = Number(card?.wrong_streak ?? card?.wrongStreak ?? 0);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2668:  if (wrongStreak >= 2) return "hard";
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2726:    const res = await fetch("/api/study/decks", {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:2734:    if (!res.ok) throw new Error(`/api/study/decks HTTP ${res.status}: ${text.slice(0, 160)}`);
```
