# Stage 16 FC-O45-E-BR — Companion UI Result-Reader Hard-Refresh Diagnostic Read-Only

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `7c44fba`
- Prior proof tag: `controller-stage-16-fc-o45-e-bq-r3-recover-job571-via-docker-ollama-model-proof-2026-06-24`

## User-observed browser state

After a hard refresh, the Companion page showed the empty start state:

```
Study
Companion
Profile
Admin
System
Conversation

Type a message and press Enter to send.

Send a message to start a queued local AI chat.
Message
```

## Purpose

BR diagnoses whether the remaining issue is the UI result-reader / refresh restoration path.

The backend/model path is already proven by BQ-R3:

```
job_id=571
requested_model=qwen2.5:0.5b
status=completed
result_rows=1
```

## Scope

Read-only public/source/runtime/DB diagnostic plus repo docs/smoke commit/tag only.

Explicitly not allowed and not performed:

- NO source patch.
- NO live deploy.
- NO public `/var/www` mutation.
- NO DB write.
- NO job mutation.
- NO result insert.
- NO model/helper/Ollama call.
- NO scheduler activation.
- NO timer activation.
- NO persistent worker activation.
- NO backend deploy.
- NO service restart/reload/start/stop/enable/disable.
- NO CT/VM restart.
- NO nginx/cloudflared/sshd config mutation.
- NO storage mutation.
- NO file deletion.

## Expected interpretation

If BR confirms job 571 is completed with a result while the page hard-refreshes to an empty state, then the remaining gap is not model execution. It is one of:

- UI does not persist/restore the last submitted Companion job id after refresh.
- UI does not load recent completed Companion jobs on page render.
- UI result-reader/poller does not render completed `response_text`.

## Recommended next phase

```
FC-O45-E-BS — source patch to restore or surface recent completed Companion job after refresh, no runtime activation
```

## Output

```
=== Stage 16 FC-O45-E-BR Companion UI result-reader hard-refresh diagnostic read-only ===
MUTATION_SCOPE=read_only_public_source_runtime_db_diagnostic_plus_repo_doc_smoke_commit_tag_push
OBSERVED_BROWSER_STATE=hard_refresh_companion_page_shows_empty_start_state_not_job571_reply
NO source patch
NO live deploy
NO public /var/www mutation
NO DB write
NO job mutation
NO result insert
NO model/helper/Ollama call
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
expected_head=7c44fba
head_now=7c44fba
origin_main_now=7c44fba
git_preflight=PASS

=== backend proven state read-only: job571 ===
job571_json={"id": 571, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence after BP2.", "requested_model": "qwen2.5:0.5b", "status": "completed", "attempts": 2, "last_error": null, "created_at": "2026-06-25T02:29:36.806186+00:00", "updated_at": "2026-06-25T02:43:17.792838+00:00"}
job571_results_json=[{"job_id": 571, "model": "qwen2.5:0.5b", "response_text": "Hello! I'm a text-based AI and don't have an immediate physical form like a\na human can. However, I'm always here to answer your questions or offer ass\nassistance as needed. Please feel free to ask me anything you'd like to kno\nknow.", "error": null, "created_at": "2026-06-25T02:43:17.792838+00:00", "updated_at": "2026-06-25T02:43:17.792838+00:00"}]
recent_companion_jobs_json=[{"id": 571, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence after BP2.", "requested_model": "qwen2.5:0.5b", "status": "completed", "attempts": 2, "last_error": null, "created_at": "2026-06-25T02:29:36.806186+00:00", "updated_at": "2026-06-25T02:43:17.792838+00:00"}, {"id": 570, "user_id": 16, "job_type": "companion.chat", "prompt": "ask me how my day is in 1 sentence.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T02:16:12.718709+00:00", "updated_at": "2026-06-25T02:16:12.718709+00:00"}, {"id": 569, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:43:16.805622+00:00", "updated_at": "2026-06-25T01:43:16.805622+00:00"}, {"id": 568, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello i 1 sentence", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:36:29.420762+00:00", "updated_at": "2026-06-25T01:36:29.420762+00:00"}, {"id": 567, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence to me.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.603874+00:00", "updated_at": "2026-06-25T01:15:17.603874+00:00"}, {"id": 566, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence to me.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.592859+00:00", "updated_at": "2026-06-25T01:15:17.592859+00:00"}, {"id": 565, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence to me.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.580188+00:00", "updated_at": "2026-06-25T01:15:17.580188+00:00"}, {"id": 564, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence to me.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.568611+00:00", "updated_at": "2026-06-25T01:15:17.568611+00:00"}]

=== public app/root read-only ===
public_root_http=200
public_app_js_http=200
public_unauth_job571_http=401
{"detail":"Missing bearer token."}
root_script_refs:
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045ebm"
<script src="/queued_chat_config.js"

=== live public app.js result-reader markers ===
380:  token: localStorage.getItem("edgeStudyToken") || "",
3700:// This replaces the static /chat summary with a real send/poll/render loop.
3701:const queuedChatUiState = {
3707:function queuedChatEscape(value) {
3716:function queuedChatSetStatus(text) {
3717:  const el = document.getElementById("queuedChatStatus");
3721:function queuedChatRenderMessages() {
3722:  const el = document.getElementById("queuedChatMessages");
3725:  if (!queuedChatUiState.messages.length) {
3730:  el.innerHTML = queuedChatUiState.messages.map((msg) => `
3732:      <span>${queuedChatEscape(msg.role)}</span>
3733:      <strong>${queuedChatEscape(msg.content)}</strong>
3734:      ${msg.detail ? `<p>${queuedChatEscape(msg.detail)}</p>` : ""}
3740:  /* Stage 16 FC-O45-E-BJ-R4 Companion structural minimal source.
3742:   * Existing queued-chat IDs/classes are preserved so current submit, polling,
3763:          <div id="queuedChatMessages" class="stage5p8h-message-list"></div>
3766:        <form id="queuedChatForm" class="stage5p8h-message-form">
3767:          <label for="queuedChatInput">Message</label>
3768:          <textarea id="queuedChatInput" rows="5" placeholder="Message Companion..."></textarea>
3771:            <button class="stage5p8h-send-button" type="submit" id="queuedChatSendBtn">Send message</button>
3772:            <button class="stage5p8h-clear-button" type="button" id="queuedChatClearBtn">Clear</button>
3784:function queuedChatSessionToken() {
3788:      || window.localStorage.getItem("edgeStudyToken")
3796:function queuedChatAuthHeaders() {
3798:  const token = queuedChatSessionToken();
3823:  const job = data && data.job ? data.job : (data && data.job_id ? data : null);
3841:      stage5p10fSetText("queuedChatQueueSummary", "Queued");
3848:      stage5p10fSetText("queuedChatQueueSummary", `${job.position} / ${Math.max(denominator, job.position)}`);
3854:      stage5p10fSetText("queuedChatQueueSummary", "Running");
3859:      stage5p10fSetText("queuedChatQueueSummary", "Done");
3864:      stage5p10fSetText("queuedChatQueueSummary", "Failed");
3869:      stage5p10fSetText("queuedChatQueueSummary", "Cancelled");
3876:    stage5p10fSetText("queuedChatQueueSummary", `— / ${total}`);
3878:    stage5p10fSetText("queuedChatQueueSummary", "0 / 0");
3885:    ? `/api/chat/queue/status?job_id=${encodeURIComponent(cleanJobId)}`
3893:      headers: queuedChatAuthHeaders()
3935:async function queuedChatPollJob(jobId) {
3937:    queuedChatSetStatus(`Waiting for worker... poll ${i + 1}`);
3942:      headers: queuedChatAuthHeaders()
3947:      throw new Error(`Status poll HTTP ${res.status}: ${text.slice(0, 180)}`);
3960:        reply: "Your message is queued safely. The model worker is not active yet, so no assistant reply has been generated.",
3982:  throw new Error("Queued job did not finish before polling timed out.");
4071:    return String(window.localStorage.getItem("stage5p9aSelectedStudyDeckId") || "").trim();
4099:    const value = String(window.localStorage.getItem(stage5p11qReviewStyleKey()) || "").trim().toLowerCase();
4110:    window.localStorage.setItem(stage5p11qReviewStyleKey(), clean);
4180:    window.localStorage.setItem("stage5p9aSelectedStudyDeckId", clean);
4226:    headers: queuedChatAuthHeaders()
4426:    headers: queuedChatAuthHeaders(),
4524:    headers: queuedChatAuthHeaders(),
4784:    headers: queuedChatAuthHeaders()
4800:    headers: queuedChatAuthHeaders(),
4872:async function queuedChatSubmit(event) {
4875:  if (queuedChatUiState.busy) return;
4877:  const input = document.getElementById("queuedChatInput");
4878:  const button = document.getElementById("queuedChatSendBtn");
4882:    queuedChatSetStatus("Enter a message first.");
4888:    queuedChatUiState.messages.push({ role: "You", content: message });
4889:    queuedChatRenderMessages();
4892:    queuedChatUiState.busy = true;
4894:    queuedChatSetStatus("Handling Study command...");
4898:      queuedChatUiState.messages.push({
4903:      queuedChatSetStatus("Study command complete");
4905:      queuedChatUiState.messages.push({
4910:      queuedChatSetStatus("Study command failed");
4912:      queuedChatUiState.busy = false;
4914:      queuedChatRenderMessages();
4924:    queuedChatSetStatus("Checking Study answer...");
4930:        queuedChatUiState.messages.push({ role: "You", content: message });
4931:        queuedChatRenderMessages();
4934:        queuedChatUiState.busy = true;
4937:        queuedChatUiState.messages.push({
4943:        queuedChatSetStatus("Study answer checked");
4944:        queuedChatUiState.busy = false;
4946:        queuedChatRenderMessages();
4950:      queuedChatUiState.messages.push({ role: "You", content: message });
4951:      queuedChatUiState.messages.push({
4957:      queuedChatSetStatus("Study answer check failed");
4958:      queuedChatRenderMessages();
4962:    queuedChatSetStatus("Ready");
4966:  queuedChatUiState.busy = true;
4969:  queuedChatUiState.messages.push({ role: "You", content: message });
4970:  queuedChatRenderMessages();
4975:    queuedChatSetStatus("Creating queued job...");
4980:      headers: queuedChatAuthHeaders(),
4998:    const jobId = data.job_id || data?.job?.job_id;
5001:      throw new Error("Queued job response did not include a job_id.");
5004:    queuedChatUiState.lastJobId = jobId;
5008:        source: "queuedChatSubmit",
5013:    queuedChatUiState.messages.push({
5018:    queuedChatRenderMessages();
5026:    const final = await queuedChatPollJob(jobId);
5028:    queuedChatUiState.messages.push({
5033:    queuedChatSetStatus("Complete");
5037:    queuedChatRenderMessages();
5039:    queuedChatUiState.messages.push({
5043:    queuedChatSetStatus("Error");
5044:    queuedChatRenderMessages();
5046:    queuedChatUiState.busy = false;
5052:  queuedChatRenderMessages();
5054:  const form = document.getElementById("queuedChatForm");
5056:    form.onsubmit = queuedChatSubmit;
5059:  const clearBtn = document.getElementById("queuedChatClearBtn");
5062:      queuedChatUiState.messages = [];
5063:      queuedChatSetStatus("Ready");
5064:      queuedChatRenderMessages();
5140:      ["Queued responses", "Messages are submitted as jobs and polled until complete."],
5747:    if (window.localStorage && (localStorage.getItem("edgeStudyToken") || localStorage.getItem("edgeAuthToken"))) return true;
6705:  // Keep system polling lightweight.
6790:      sessionStorage.setItem("pendingVerificationEmail", pendingVerificationEmail);
6799:    pendingVerificationEmail = sessionStorage.getItem("pendingVerificationEmail") || "";
7025:    localStorage.setItem("edgeStudyToken", token);
7070:  localStorage.removeItem("edgeStudyToken");
7090:    localStorage.removeItem("edgeStudyToken");
8306:// Keeps header credits fresh without tying credits to system polling.
8482:    localStorage.setItem("edgeStudyToken", token);
8531:  const oldToken = authState?.token || localStorage.getItem("edgeStudyToken") || "";
8536:  localStorage.removeItem("edgeStudyToken");
8614:  let id = localStorage.getItem(WEB_PRESENCE_VISITOR_KEY);
8622:    localStorage.setItem(WEB_PRESENCE_VISITOR_KEY, id);
8874:    localStorage.removeItem("edgeStudyToken");
8914:  const token = localStorage.getItem("edgeStudyToken") || authState?.token || "";
9212: * Stage 5F-35: disabled queued-chat status polling branch.
9214: * This block defines a future queued-chat status polling helper, but intentionally
9215: * does not wire it into the current chat submit flow or any runtime polling loop.
9220: * - branch is not wired to automatic polling
9235:        reason: "queued_status_poll_disabled_stage_5f35",
9242:    if (!helper || typeof helper.queuedChatBuildStatusView !== "function") {
9254:        error: "missing_job_id_stage_5f35",
9278:    const view = helper.queuedChatBuildStatusView(job, elapsedMs);
9290:    source: "app_js_disabled_queued_status_poll_branch",
9291:    pollerWired: false,
9292:    pollQueuedChatStatus: stage5f35PollQueuedChatStatus,
9297: * Stage 5F-37: disabled queued-chat assistant placeholder branch.
9299: * This block defines a future queued-chat assistant placeholder helper, but
9327:    if (!helper || typeof helper.queuedChatBuildStatusView !== "function") {
9335:    const view = helper.queuedChatBuildStatusView(job || {}, elapsedMs);
9343:      assistantReply: view.assistantReply || "",
9349:    source: "app_js_disabled_queued_assistant_placeholder_branch",
9366: * - does not start polling
9452: * - does not start polling
9464:    const pollBranch = root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH;
9490:      pollBranchPresent: Boolean(pollBranch),
9494:      pollerWired: Boolean(pollBranch && pollBranch.pollerWired === true),
9520: * - does not start polling
9604:    const pollBranch = root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH;
9671:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
9688:          id: sendResult.job_id,
9689:          job_id: sendResult.job_id,
9698:    if (pollBranch && typeof pollBranch.pollQueuedChatStatus === "function") {
9699:      calls.push("poll");
9700:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
9714:      job_id: sendResult.job_id,
9740: * - does not call queued status polling
9766:        "poll_status_once",
9774:        poll: Boolean(root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH),
9800: * - does not call queued status polling
9825:        "single_poll_loop",
9835:        poll: Boolean(root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH),
9861: * - does not call queued status polling
9887:        "queued_polling",
9896:        "single_poll_loop_proven",
9923: * - does not call queued status polling
9954:        "queued_polling",
9967:        "single_poll_loop_proven",
10394:    if (/companion|queued chat|message|assistant|worker|model/i.test(text)) return true;
10417:      return JSON.parse(window.localStorage.getItem(snapshotKey) || "{}") || {};
10429:      window.localStorage.setItem(snapshotKey, JSON.stringify(merged));
10455:      const jobId = stagePickValue(data, ["job_id", "jobId", "id"]);
10544:      const hasMessages = !!shell.querySelector(".message, .chat-message, .assistant-message, .user-message, [data-role='assistant'], [data-role='user']")
10545:        || /\bassistant\s*·|\buser\s*·/i.test(String(shell.innerText || ""));
10565:    shell.querySelectorAll(".message, .chat-message, [data-role='assistant'], [data-role='user']").forEach(function (msg) {
10569:      if (role.includes("assistant")) msg.classList.add("stage5o35-assistant-bubble");
10673:      '<p>Messages continue through <code>/api/chat/queued</code>. The page watches the same polling flow and displays queue state without changing backend behavior.</p>',
10796:        const token = readTokenCandidate(window.localStorage.getItem(key));
10800:      for (let i = 0; i < window.localStorage.length; i += 1) {
10801:        const key = window.localStorage.key(i);
10803:        const token = readTokenCandidate(window.localStorage.getItem(key));
10807:      /* localStorage may be unavailable */
11095:        const token = readTokenCandidate(window.localStorage.getItem(key));
11099:      for (let i = 0; i < window.localStorage.length; i += 1) {
11100:        const key = window.localStorage.key(i);
11102:        const token = readTokenCandidate(window.localStorage.getItem(key));
11106:      /* localStorage may be unavailable */
11242:      return String(window.localStorage.getItem(selectedDeckKey) || "").trim();
11458:      const edgeStudyToken = readTokenCandidate(window.localStorage.getItem("edgeStudyToken"));
11461:      /* authState/localStorage may be unavailable */
11484:        const token = readTokenCandidate(window.localStorage.getItem(key));
11488:      for (let i = 0; i < window.localStorage.length; i += 1) {
11489:        const key = window.localStorage.key(i);
11491:        const token = readTokenCandidate(window.localStorage.getItem(key));
11495:      /* localStorage may be unavailable */
11541:      return window.localStorage.getItem(selectedDeckKey) || "";
11549:      if (id) window.localStorage.setItem(selectedDeckKey, String(id));
11550:      else window.localStorage.removeItem(selectedDeckKey);
12561:      [window.localStorage, window.sessionStorage].forEach(function (store) {
12803:      [window.localStorage, window.sessionStorage].forEach(function (store) {
13201:      [window.localStorage, window.sessionStorage].forEach(function (store) {
13585:      const value = localStorage.getItem(key) || sessionStorage.getItem(key);
13595:    for (const store of [localStorage, sessionStorage]) {
13764:      const value = localStorage.getItem(key) || sessionStorage.getItem(key);
13774:    for (const store of [localStorage, sessionStorage]) {
13814:    lines.push("job_id: " + String(job.id || result.job_id || ""));
13820:    lines.push(String(data.response_text || result.response_text || ""));
13826:      window.localStorage.setItem("apc_companion_latest_submitted_job_id", String(jobId || ""));
13832:      return String(window.localStorage.getItem("apc_companion_latest_submitted_job_id") || "").trim();
13879:          job_id: jobId,
13899:      if (data && data.has_result === true && data.response_text) {
14003: * assistant-like state vocabulary that can be wired into the visible panel:
14085:  if (context.job_id || context.jobId) lines.push(`job_id: ${context.job_id || context.jobId}`);
14153:/* Stage 16 FC-O45-E-BJ-R4 Companion structural minimal early flag.
14260:      job_id: runtime.job.job_id || runtime.job.id || runtime.resultPayload.job_id,
14322:    const jobId = payload.job_id || payload.id || job.job_id || job.id;
14328:      ...(jobId ? { job_id: jobId, id: jobId } : {}),
14603: * - Preserve existing queued chat endpoint, polling flow, result reader code, and backend behavior.
14685:      if (text === "Send a message below. New work still uses the existing queued chat endpoint and polling flow.") {
14833:        "Send a message below. New work still uses the existing queued chat endpoint and polling flow."
14847:        "Messages continue through /api/chat/queued. The page polls the existing job status endpoint and displays the final assistant reply without changing backend behavior."
15113:    hideExactLooseText("Send a message below. New work still uses the existing queued chat endpoint and polling flow.", "queued-endpoint-explanation");
15114:    hidePanelContaining("Send a message below. New work still uses the existing queued chat endpoint and polling flow.", "queued-endpoint-explanation-panel");
15303:      return normalized.replace(/^Assistant\s+/i, "assistant:");
15371: * Stage 16 FC-O45-E-BJ-R4 Companion structural minimal runtime.
15383:    const form = document.getElementById("queuedChatForm");
15384:    const textarea = document.getElementById("queuedChatInput");
15423: * Stage 16 FC-O45-E-BL Companion delegated Enter-to-send source.
15426: * This is delegated on document, so it works for future #queuedChatInput nodes.
15437:    if (!target || target.id !== "queuedChatInput") {
15444:    const form = document.getElementById("queuedChatForm");
15454:      const submit = document.getElementById("queuedChatSendBtn");
15465:    inputId: "queuedChatInput",
15466:    formId: "queuedChatForm",
15467:    sendButtonId: "queuedChatSendBtn",

=== repo source result-reader context ===
frontend/study-ui/app.js:126:    localStorage.removeItem("edgeStudyToken");
frontend/study-ui/app.js:154:    localStorage.setItem("edgeStudyToken", state.token);
frontend/study-ui/app.js:181:  localStorage.removeItem("edgeStudyToken");
frontend/study-ui/app.js:660:    companionAddMessage("assistant", "Please select a deck first.");
frontend/study-ui/app.js:666:    companionAddMessage("assistant", "Loading your review queue...");
frontend/study-ui/app.js:679:      companionAddMessage("assistant", "This deck does not have cards yet. Add cards on the Study page first.");
frontend/study-ui/app.js:691:    companionAddMessage("assistant", `I could not load the queue: ${err.message}`);
frontend/study-ui/app.js:703:    companionAddMessage("assistant", "Review complete. Load another queue when you are ready.");
frontend/study-ui/app.js:711:    "assistant",
frontend/study-ui/app.js:724:    companionAddMessage("assistant", "Load a review queue first.");
frontend/study-ui/app.js:745:      companionAddMessage("assistant", `Correct. ${data.feedback}`);
frontend/study-ui/app.js:752:        "assistant",
frontend/study-ui/app.js:766:      "assistant",
frontend/study-ui/app.js:772:    companionAddMessage("assistant", `I could not grade that answer: ${err.message}`);
frontend/study-ui/app.js:792:  companionAddMessage("assistant", wasCorrect ? "Marked correct." : "Marked wrong.");
frontend/study-ui/app.js:859:      const value = localStorage.getItem(key);
frontend/study-ui/app.js:882:      return JSON.parse(localStorage.getItem(key) || JSON.stringify(fallback));
frontend/study-ui/app.js:889:    localStorage.setItem(key, JSON.stringify(value));
frontend/study-ui/app.js:934:  // Cloudflare/proxy errors must never be saved as assistant chat text.
frontend/study-ui/app.js:937:    return data?.job_id || data?.id || data?.job?.id || data?.result?.job_id || data?.result?.id || null;
frontend/study-ui/app.js:941:    return data?.poll_url || data?.job?.poll_url || data?.result?.poll_url || "";
frontend/study-ui/app.js:1012:  async function pollJob(jobId, pollUrl = "") {
frontend/study-ui/app.js:1024:      normalizePollUrl(pollUrl),
frontend/study-ui/app.js:1048:          if (text && !/queued|poll|pending|running/i.test(text)) return text;
frontend/study-ui/app.js:1050:          if (!err.transient && attempt > 2) console.warn("Job poll issue:", err);
frontend/study-ui/app.js:1139:        const pollUrl = getPollUrl(data);
frontend/study-ui/app.js:1147:          return await pollJob(jobId, pollUrl);
frontend/study-ui/app.js:1150:        if (directText && !/queued|poll|pending|running/i.test(directText)) return directText;
frontend/study-ui/app.js:1167:        role: "assistant",
frontend/study-ui/app.js:1212:      addCompanionMessage("assistant", answer || "I got a response, but it did not include readable text.");
frontend/study-ui/app.js:1248:        localStorage.removeItem(CHAT_KEY);
frontend/study-ui/app.js:1678:      localStorage.getItem("edgeStudyToken") ||
frontend/study-ui/app.js:1679:      localStorage.getItem("aiStudyToken") ||
frontend/study-ui/app.js:1680:      localStorage.getItem("authToken") ||
frontend/study-ui/app.js:1681:      localStorage.getItem("token") ||
frontend/study-ui/app.js:1921:    if (authLink && localStorage.getItem("edgeStudyToken")) {
frontend/study-ui/styles.css:546:.chat-bubble.assistant {
frontend/study-ui/styles.css:619:.chat-bubble.assistant {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:50:  token: localStorage.getItem("edgeStudyToken") || "",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3254:// This replaces the static /chat summary with a real send/poll/render loop.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3255:const queuedChatUiState = {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3261:function queuedChatEscape(value) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3270:function queuedChatSetStatus(text) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3271:  const el = document.getElementById("queuedChatStatus");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3275:function queuedChatRenderMessages() {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3276:  const el = document.getElementById("queuedChatMessages");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3279:  if (!queuedChatUiState.messages.length) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3284:  el.innerHTML = queuedChatUiState.messages.map((msg) => `
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3286:      <span>${queuedChatEscape(msg.role)}</span>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3287:      <strong>${queuedChatEscape(msg.content)}</strong>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3288:      ${msg.detail ? `<p>${queuedChatEscape(msg.detail)}</p>` : ""}
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3293:function renderQueuedChatPage() {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3308:            <strong id="queuedChatStatus">Ready</strong>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3309:            <p>Uses the existing queued worker path and polls the returned job id.</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3318:        <form id="queuedChatForm" class="form-grid">
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3321:            <textarea id="queuedChatInput" rows="5" placeholder="Ask Companion something..."></textarea>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3325:            <button class="primary-btn" type="submit" id="queuedChatSendBtn">Send message</button>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3326:            <button class="ghost-btn" type="button" id="queuedChatClearBtn">Clear</button>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3332:          <div id="queuedChatMessages" class="summary-grid"></div>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3348:async function queuedChatPollJob(jobId) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3350:    queuedChatSetStatus(`Waiting for worker... poll ${i + 1}`);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3359:      throw new Error(`Status poll HTTP ${res.status}: ${text.slice(0, 180)}`);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3382:  throw new Error("Queued job did not finish before polling timed out.");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3385:async function queuedChatSubmit(event) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3388:  if (queuedChatUiState.busy) return;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3390:  const input = document.getElementById("queuedChatInput");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3391:  const button = document.getElementById("queuedChatSendBtn");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3395:    queuedChatSetStatus("Enter a message first.");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3399:  queuedChatUiState.busy = true;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3402:  queuedChatUiState.messages.push({ role: "You", content: message });
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3403:  queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3408:    queuedChatSetStatus("Creating queued job...");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3428:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3431:      throw new Error("Queued job response did not include a job_id.");
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
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3547:      ["Queued responses", "Messages are submitted as jobs and polled until complete."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3697:    $("app").innerHTML = renderQueuedChatPage();
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3949:  // Keep system polling lightweight.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:4033:      sessionStorage.setItem("pendingVerificationEmail", pendingVerificationEmail);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:4042:    pendingVerificationEmail = sessionStorage.getItem("pendingVerificationEmail") || "";
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:4268:    localStorage.setItem("edgeStudyToken", token);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:4313:  localStorage.removeItem("edgeStudyToken");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:4333:    localStorage.removeItem("edgeStudyToken");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:5545:// Keeps header credits fresh without tying credits to system polling.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:5721:    localStorage.setItem("edgeStudyToken", token);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:5770:  const oldToken = authState?.token || localStorage.getItem("edgeStudyToken") || "";
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:5775:  localStorage.removeItem("edgeStudyToken");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:5819:  let id = localStorage.getItem(WEB_PRESENCE_VISITOR_KEY);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:5827:    localStorage.setItem(WEB_PRESENCE_VISITOR_KEY, id);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6020:    localStorage.removeItem("edgeStudyToken");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6060:  const token = localStorage.getItem("edgeStudyToken") || authState?.token || "";
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6358: * Stage 5F-35: disabled queued-chat status polling branch.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6360: * This block defines a future queued-chat status polling helper, but intentionally
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6361: * does not wire it into the current chat submit flow or any runtime polling loop.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6366: * - branch is not wired to automatic polling
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6381:        reason: "queued_status_poll_disabled_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6388:    if (!helper || typeof helper.queuedChatBuildStatusView !== "function") {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6400:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6424:    const view = helper.queuedChatBuildStatusView(job, elapsedMs);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6436:    source: "app_js_disabled_queued_status_poll_branch",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6437:    pollerWired: false,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6438:    pollQueuedChatStatus: stage5f35PollQueuedChatStatus,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6443: * Stage 5F-37: disabled queued-chat assistant placeholder branch.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6445: * This block defines a future queued-chat assistant placeholder helper, but
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6473:    if (!helper || typeof helper.queuedChatBuildStatusView !== "function") {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6481:    const view = helper.queuedChatBuildStatusView(job || {}, elapsedMs);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6489:      assistantReply: view.assistantReply || "",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6495:    source: "app_js_disabled_queued_assistant_placeholder_branch",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6512: * - does not start polling
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6598: * - does not start polling
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6610:    const pollBranch = root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6636:      pollBranchPresent: Boolean(pollBranch),
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6640:      pollerWired: Boolean(pollBranch && pollBranch.pollerWired === true),
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6666: * - does not start polling
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6750:    const pollBranch = root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6817:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6834:          id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6835:          job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6844:    if (pollBranch && typeof pollBranch.pollQueuedChatStatus === "function") {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6845:      calls.push("poll");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6846:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6860:      job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6886: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6912:        "poll_status_once",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6920:        poll: Boolean(root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH),
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6946: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6971:        "single_poll_loop",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6981:        poll: Boolean(root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH),
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7007: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7033:        "queued_polling",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7042:        "single_poll_loop_proven",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7069: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7100:        "queued_polling",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:7113:        "single_poll_loop_proven",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:50:  token: localStorage.getItem("edgeStudyToken") || "",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3254:// This replaces the static /chat summary with a real send/poll/render loop.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3255:const queuedChatUiState = {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3261:function queuedChatEscape(value) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3270:function queuedChatSetStatus(text) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3271:  const el = document.getElementById("queuedChatStatus");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3275:function queuedChatRenderMessages() {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3276:  const el = document.getElementById("queuedChatMessages");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3279:  if (!queuedChatUiState.messages.length) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3284:  el.innerHTML = queuedChatUiState.messages.map((msg) => `
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3286:      <span>${queuedChatEscape(msg.role)}</span>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3287:      <strong>${queuedChatEscape(msg.content)}</strong>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3288:      ${msg.detail ? `<p>${queuedChatEscape(msg.detail)}</p>` : ""}
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3293:function renderQueuedChatPage() {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3308:            <strong id="queuedChatStatus">Ready</strong>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3309:            <p>Uses the existing queued worker path and polls the returned job id.</p>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3318:        <form id="queuedChatForm" class="form-grid">
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3321:            <textarea id="queuedChatInput" rows="5" placeholder="Ask Companion something..."></textarea>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3325:            <button class="primary-btn" type="submit" id="queuedChatSendBtn">Send message</button>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3326:            <button class="ghost-btn" type="button" id="queuedChatClearBtn">Clear</button>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3332:          <div id="queuedChatMessages" class="summary-grid"></div>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3348:async function queuedChatPollJob(jobId) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3350:    queuedChatSetStatus(`Waiting for worker... poll ${i + 1}`);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3359:      throw new Error(`Status poll HTTP ${res.status}: ${text.slice(0, 180)}`);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3382:  throw new Error("Queued job did not finish before polling timed out.");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3385:async function queuedChatSubmit(event) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3388:  if (queuedChatUiState.busy) return;
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3390:  const input = document.getElementById("queuedChatInput");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3391:  const button = document.getElementById("queuedChatSendBtn");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3395:    queuedChatSetStatus("Enter a message first.");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3399:  queuedChatUiState.busy = true;
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3402:  queuedChatUiState.messages.push({ role: "You", content: message });
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3403:  queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3408:    queuedChatSetStatus("Creating queued job...");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3428:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3431:      throw new Error("Queued job response did not include a job_id.");
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
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3547:      ["Queued responses", "Messages are submitted as jobs and polled until complete."],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3795:    $("app").innerHTML = renderQueuedChatPage();
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:4058:  // Keep system polling lightweight.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:4142:      sessionStorage.setItem("pendingVerificationEmail", pendingVerificationEmail);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:4151:    pendingVerificationEmail = sessionStorage.getItem("pendingVerificationEmail") || "";
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:4377:    localStorage.setItem("edgeStudyToken", token);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:4422:  localStorage.removeItem("edgeStudyToken");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:4442:    localStorage.removeItem("edgeStudyToken");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:5654:// Keeps header credits fresh without tying credits to system polling.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:5830:    localStorage.setItem("edgeStudyToken", token);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:5879:  const oldToken = authState?.token || localStorage.getItem("edgeStudyToken") || "";
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:5884:  localStorage.removeItem("edgeStudyToken");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:5928:  let id = localStorage.getItem(WEB_PRESENCE_VISITOR_KEY);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:5936:    localStorage.setItem(WEB_PRESENCE_VISITOR_KEY, id);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6129:    localStorage.removeItem("edgeStudyToken");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6169:  const token = localStorage.getItem("edgeStudyToken") || authState?.token || "";
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6467: * Stage 5F-35: disabled queued-chat status polling branch.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6469: * This block defines a future queued-chat status polling helper, but intentionally
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6470: * does not wire it into the current chat submit flow or any runtime polling loop.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6475: * - branch is not wired to automatic polling
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6490:        reason: "queued_status_poll_disabled_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6497:    if (!helper || typeof helper.queuedChatBuildStatusView !== "function") {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6509:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6533:    const view = helper.queuedChatBuildStatusView(job, elapsedMs);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6545:    source: "app_js_disabled_queued_status_poll_branch",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6546:    pollerWired: false,
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6547:    pollQueuedChatStatus: stage5f35PollQueuedChatStatus,
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6552: * Stage 5F-37: disabled queued-chat assistant placeholder branch.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6554: * This block defines a future queued-chat assistant placeholder helper, but
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6582:    if (!helper || typeof helper.queuedChatBuildStatusView !== "function") {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6590:    const view = helper.queuedChatBuildStatusView(job || {}, elapsedMs);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6598:      assistantReply: view.assistantReply || "",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6604:    source: "app_js_disabled_queued_assistant_placeholder_branch",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6621: * - does not start polling
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6707: * - does not start polling
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6719:    const pollBranch = root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH;
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6745:      pollBranchPresent: Boolean(pollBranch),
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6749:      pollerWired: Boolean(pollBranch && pollBranch.pollerWired === true),
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6775: * - does not start polling
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6859:    const pollBranch = root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH;
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6926:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6943:          id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6944:          job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6953:    if (pollBranch && typeof pollBranch.pollQueuedChatStatus === "function") {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6954:      calls.push("poll");
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6955:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6969:      job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6995: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:7021:        "poll_status_once",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:7029:        poll: Boolean(root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH),
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:7055: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:7080:        "single_poll_loop",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:7090:        poll: Boolean(root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH),
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:7116: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:7142:        "queued_polling",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:7151:        "single_poll_loop_proven",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:7178: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:7209:        "queued_polling",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:7222:        "single_poll_loop_proven",
frontend/wrapper-ui/dev_server.py:529:    #   GET  /api/backend/chats/{chat_id}/messages/jobs/{job_id}
frontend/wrapper-ui/dev_server.py:533:    #   GET  /api/chat/queued/{job_id}
frontend/wrapper-ui/dev_server.py:649:    def _stage5g9_transform_status_response(self, chat_id, job_id, data):
frontend/wrapper-ui/dev_server.py:658:        out.setdefault("job_id", job_id)
frontend/wrapper-ui/dev_server.py:663:        #   pollData.status === "complete" && pollData.assistant_message
frontend/wrapper-ui/dev_server.py:666:        # result_json. Convert that to CT101-compatible assistant_message only
frontend/wrapper-ui/dev_server.py:668:        # assistant message row and therefore cannot duplicate final messages.
frontend/wrapper-ui/dev_server.py:669:        assistant_message = out.get("assistant_message")
frontend/wrapper-ui/dev_server.py:671:        if assistant_message is None and out.get("status") == "complete":
frontend/wrapper-ui/dev_server.py:690:                assistant_id = ""
frontend/wrapper-ui/dev_server.py:692:                    assistant_id = str(
frontend/wrapper-ui/dev_server.py:693:                        result.get("chat_assistant_message_id")
frontend/wrapper-ui/dev_server.py:694:                        or result.get("assistant_message_id")
frontend/wrapper-ui/dev_server.py:698:                if not assistant_id:
frontend/wrapper-ui/dev_server.py:699:                    assistant_id = f"{job_id}-assistant"
frontend/wrapper-ui/dev_server.py:701:                assistant_message = {
frontend/wrapper-ui/dev_server.py:702:                    "id": assistant_id,
frontend/wrapper-ui/dev_server.py:703:                    "role": "assistant",
frontend/wrapper-ui/dev_server.py:713:        out["assistant_message"] = assistant_message
frontend/wrapper-ui/dev_server.py:773:            job_id = status_match.group(2)
frontend/wrapper-ui/dev_server.py:776:                f"/api/chat/queued/{job_id}",
frontend/wrapper-ui/dev_server.py:783:                self._stage5g9_transform_status_response(chat_id, job_id, data),
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:50:  token: localStorage.getItem("edgeStudyToken") || "",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3250:// This replaces the static /chat summary with a real send/poll/render loop.
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3251:const queuedChatUiState = {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3257:function queuedChatEscape(value) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3266:function queuedChatSetStatus(text) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3267:  const el = document.getElementById("queuedChatStatus");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3271:function queuedChatRenderMessages() {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3272:  const el = document.getElementById("queuedChatMessages");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3275:  if (!queuedChatUiState.messages.length) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3280:  el.innerHTML = queuedChatUiState.messages.map((msg) => `
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3282:      <span>${queuedChatEscape(msg.role)}</span>
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3283:      <strong>${queuedChatEscape(msg.content)}</strong>
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3284:      ${msg.detail ? `<p>${queuedChatEscape(msg.detail)}</p>` : ""}
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3289:function renderQueuedChatPage() {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3304:            <strong id="queuedChatStatus">Ready</strong>
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3305:            <p>Uses the existing queued worker path and polls the returned job id.</p>
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3314:        <form id="queuedChatForm" class="form-grid">
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3317:            <textarea id="queuedChatInput" rows="5" placeholder="Ask Companion something..."></textarea>
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3321:            <button class="primary-btn" type="submit" id="queuedChatSendBtn">Send message</button>
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3322:            <button class="ghost-btn" type="button" id="queuedChatClearBtn">Clear</button>
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3328:          <div id="queuedChatMessages" class="summary-grid"></div>
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3344:async function queuedChatPollJob(jobId) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3346:    queuedChatSetStatus(`Waiting for worker... poll ${i + 1}`);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3355:      throw new Error(`Status poll HTTP ${res.status}: ${text.slice(0, 180)}`);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3378:  throw new Error("Queued job did not finish before polling timed out.");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3381:async function queuedChatSubmit(event) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3384:  if (queuedChatUiState.busy) return;
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3386:  const input = document.getElementById("queuedChatInput");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3387:  const button = document.getElementById("queuedChatSendBtn");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3391:    queuedChatSetStatus("Enter a message first.");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3395:  queuedChatUiState.busy = true;
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3398:  queuedChatUiState.messages.push({ role: "You", content: message });
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3399:  queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3404:    queuedChatSetStatus("Creating queued job...");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3424:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3427:      throw new Error("Queued job response did not include a job_id.");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3430:    queuedChatUiState.lastJobId = jobId;
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3431:    queuedChatUiState.messages.push({
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3436:    queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3438:    const final = await queuedChatPollJob(jobId);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3440:    queuedChatUiState.messages.push({
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3445:    queuedChatSetStatus("Complete");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3446:    queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3448:    queuedChatUiState.messages.push({
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3452:    queuedChatSetStatus("Error");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3453:    queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3455:    queuedChatUiState.busy = false;
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3461:  queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3463:  const form = document.getElementById("queuedChatForm");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3465:    form.onsubmit = queuedChatSubmit;
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3468:  const clearBtn = document.getElementById("queuedChatClearBtn");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3471:      queuedChatUiState.messages = [];
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3472:      queuedChatSetStatus("Ready");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3473:      queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3501:    $("app").innerHTML = renderQueuedChatPage();
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3753:  // Keep system polling lightweight.
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3837:      sessionStorage.setItem("pendingVerificationEmail", pendingVerificationEmail);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3846:    pendingVerificationEmail = sessionStorage.getItem("pendingVerificationEmail") || "";
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:4072:    localStorage.setItem("edgeStudyToken", token);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:4114:  localStorage.removeItem("edgeStudyToken");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:4134:    localStorage.removeItem("edgeStudyToken");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5311:// Keeps header credits fresh without tying credits to system polling.
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5474:    localStorage.setItem("edgeStudyToken", token);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5521:  const oldToken = authState?.token || localStorage.getItem("edgeStudyToken") || "";
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5526:  localStorage.removeItem("edgeStudyToken");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5570:  let id = localStorage.getItem(WEB_PRESENCE_VISITOR_KEY);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5578:    localStorage.setItem(WEB_PRESENCE_VISITOR_KEY, id);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5770:    localStorage.removeItem("edgeStudyToken");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:5810:  const token = localStorage.getItem("edgeStudyToken") || authState?.token || "";
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6087: * Stage 5F-35: disabled queued-chat status polling branch.
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6089: * This block defines a future queued-chat status polling helper, but intentionally
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6090: * does not wire it into the current chat submit flow or any runtime polling loop.
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6095: * - branch is not wired to automatic polling
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6110:        reason: "queued_status_poll_disabled_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6117:    if (!helper || typeof helper.queuedChatBuildStatusView !== "function") {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6129:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6153:    const view = helper.queuedChatBuildStatusView(job, elapsedMs);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6165:    source: "app_js_disabled_queued_status_poll_branch",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6166:    pollerWired: false,
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6167:    pollQueuedChatStatus: stage5f35PollQueuedChatStatus,
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6172: * Stage 5F-37: disabled queued-chat assistant placeholder branch.
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6174: * This block defines a future queued-chat assistant placeholder helper, but
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6202:    if (!helper || typeof helper.queuedChatBuildStatusView !== "function") {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6210:    const view = helper.queuedChatBuildStatusView(job || {}, elapsedMs);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6218:      assistantReply: view.assistantReply || "",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6224:    source: "app_js_disabled_queued_assistant_placeholder_branch",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6241: * - does not start polling
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6327: * - does not start polling
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6339:    const pollBranch = root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH;
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6365:      pollBranchPresent: Boolean(pollBranch),
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6369:      pollerWired: Boolean(pollBranch && pollBranch.pollerWired === true),
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6395: * - does not start polling
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6479:    const pollBranch = root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH;
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6546:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6563:          id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6564:          job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6573:    if (pollBranch && typeof pollBranch.pollQueuedChatStatus === "function") {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6574:      calls.push("poll");
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6575:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6589:      job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6615: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6641:        "poll_status_once",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6649:        poll: Boolean(root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH),
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6675: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6700:        "single_poll_loop",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6710:        poll: Boolean(root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH),
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6736: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6762:        "queued_polling",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6771:        "single_poll_loop_proven",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6798: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6829:        "queued_polling",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6842:        "single_poll_loop_proven",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:50:  token: localStorage.getItem("edgeStudyToken") || "",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3255:// This replaces the static /chat summary with a real send/poll/render loop.
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3256:const queuedChatUiState = {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3262:function queuedChatEscape(value) {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3271:function queuedChatSetStatus(text) {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3272:  const el = document.getElementById("queuedChatStatus");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3276:function queuedChatRenderMessages() {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3277:  const el = document.getElementById("queuedChatMessages");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3280:  if (!queuedChatUiState.messages.length) {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3285:  el.innerHTML = queuedChatUiState.messages.map((msg) => `
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3287:      <span>${queuedChatEscape(msg.role)}</span>
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3288:      <strong>${queuedChatEscape(msg.content)}</strong>
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3289:      ${msg.detail ? `<p>${queuedChatEscape(msg.detail)}</p>` : ""}
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3294:function renderQueuedChatPage() {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3309:            <strong id="queuedChatStatus">Ready</strong>
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3310:            <p>Uses the existing queued worker path and polls the returned job id.</p>
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3319:        <form id="queuedChatForm" class="form-grid">
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3322:            <textarea id="queuedChatInput" rows="5" placeholder="Ask Companion something..."></textarea>
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3326:            <button class="primary-btn" type="submit" id="queuedChatSendBtn">Send message</button>
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3327:            <button class="ghost-btn" type="button" id="queuedChatClearBtn">Clear</button>
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3333:          <div id="queuedChatMessages" class="summary-grid"></div>
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3349:async function queuedChatPollJob(jobId) {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3351:    queuedChatSetStatus(`Waiting for worker... poll ${i + 1}`);
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3360:      throw new Error(`Status poll HTTP ${res.status}: ${text.slice(0, 180)}`);
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3383:  throw new Error("Queued job did not finish before polling timed out.");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3386:async function queuedChatSubmit(event) {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3389:  if (queuedChatUiState.busy) return;
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3391:  const input = document.getElementById("queuedChatInput");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3392:  const button = document.getElementById("queuedChatSendBtn");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3396:    queuedChatSetStatus("Enter a message first.");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3400:  queuedChatUiState.busy = true;
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3403:  queuedChatUiState.messages.push({ role: "You", content: message });
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3404:  queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3409:    queuedChatSetStatus("Creating queued job...");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3429:    const jobId = data.job_id || data?.job?.job_id;
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3432:      throw new Error("Queued job response did not include a job_id.");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3435:    queuedChatUiState.lastJobId = jobId;
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3436:    queuedChatUiState.messages.push({
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3441:    queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3443:    const final = await queuedChatPollJob(jobId);
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3445:    queuedChatUiState.messages.push({
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3450:    queuedChatSetStatus("Complete");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3451:    queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3453:    queuedChatUiState.messages.push({
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3457:    queuedChatSetStatus("Error");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3458:    queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3460:    queuedChatUiState.busy = false;
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3466:  queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3468:  const form = document.getElementById("queuedChatForm");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3470:    form.onsubmit = queuedChatSubmit;
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3473:  const clearBtn = document.getElementById("queuedChatClearBtn");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3476:      queuedChatUiState.messages = [];
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3477:      queuedChatSetStatus("Ready");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3478:      queuedChatRenderMessages();
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3511:    $("app").innerHTML = renderQueuedChatPage();
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3763:  // Keep system polling lightweight.
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3847:      sessionStorage.setItem("pendingVerificationEmail", pendingVerificationEmail);
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3856:    pendingVerificationEmail = sessionStorage.getItem("pendingVerificationEmail") || "";
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:4082:    localStorage.setItem("edgeStudyToken", token);
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:4124:  localStorage.removeItem("edgeStudyToken");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:4144:    localStorage.removeItem("edgeStudyToken");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:5321:// Keeps header credits fresh without tying credits to system polling.
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:5484:    localStorage.setItem("edgeStudyToken", token);
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:5531:  const oldToken = authState?.token || localStorage.getItem("edgeStudyToken") || "";
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:5536:  localStorage.removeItem("edgeStudyToken");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:5580:  let id = localStorage.getItem(WEB_PRESENCE_VISITOR_KEY);
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:5588:    localStorage.setItem(WEB_PRESENCE_VISITOR_KEY, id);
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:5780:    localStorage.removeItem("edgeStudyToken");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:5820:  const token = localStorage.getItem("edgeStudyToken") || authState?.token || "";
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6118: * Stage 5F-35: disabled queued-chat status polling branch.
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6120: * This block defines a future queued-chat status polling helper, but intentionally
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6121: * does not wire it into the current chat submit flow or any runtime polling loop.
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6126: * - branch is not wired to automatic polling
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6141:        reason: "queued_status_poll_disabled_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6148:    if (!helper || typeof helper.queuedChatBuildStatusView !== "function") {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6160:        error: "missing_job_id_stage_5f35",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6184:    const view = helper.queuedChatBuildStatusView(job, elapsedMs);
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6196:    source: "app_js_disabled_queued_status_poll_branch",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6197:    pollerWired: false,
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6198:    pollQueuedChatStatus: stage5f35PollQueuedChatStatus,
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6203: * Stage 5F-37: disabled queued-chat assistant placeholder branch.
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6205: * This block defines a future queued-chat assistant placeholder helper, but
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6233:    if (!helper || typeof helper.queuedChatBuildStatusView !== "function") {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6241:    const view = helper.queuedChatBuildStatusView(job || {}, elapsedMs);
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6249:      assistantReply: view.assistantReply || "",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6255:    source: "app_js_disabled_queued_assistant_placeholder_branch",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6272: * - does not start polling
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6358: * - does not start polling
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6370:    const pollBranch = root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH;
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6396:      pollBranchPresent: Boolean(pollBranch),
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6400:      pollerWired: Boolean(pollBranch && pollBranch.pollerWired === true),
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6426: * - does not start polling
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6510:    const pollBranch = root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH;
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6577:    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6594:          id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6595:          job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6604:    if (pollBranch && typeof pollBranch.pollQueuedChatStatus === "function") {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6605:      calls.push("poll");
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6606:      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6620:      job_id: sendResult.job_id,
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6646: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6672:        "poll_status_once",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6680:        poll: Boolean(root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH),
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6706: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6731:        "single_poll_loop",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6741:        poll: Boolean(root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH),
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6767: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6793:        "queued_polling",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6802:        "single_poll_loop_proven",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6829: * - does not call queued status polling
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6860:        "queued_polling",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6873:        "single_poll_loop_proven",
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:50:  token: localStorage.getItem("edgeStudyToken") || "",
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3260:// This replaces the static /chat summary with a real send/poll/render loop.
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3261:const queuedChatUiState = {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3267:function queuedChatEscape(value) {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3276:function queuedChatSetStatus(text) {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3277:  const el = document.getElementById("queuedChatStatus");
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3281:function queuedChatRenderMessages() {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3282:  const el = document.getElementById("queuedChatMessages");
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3285:  if (!queuedChatUiState.messages.length) {
frontend/wrapper-ui/app.js.bak-stage5o22-remove-study-style-link-2026-06-11-121107:3290:  el.innerHTML = queuedChatUiState.messages.map((msg) => `

=== result-reader interpretation ===
BACKEND_MODEL_RESULT_STATUS=job571_completed_result_rows_1_model_qwen2.5:0.5b
BROWSER_OBSERVED_STATE=hard_refresh_empty_companion_start_state
LIKELY_GAP=companion_ui_result_reader_or_refresh_state_restore
EXPECTED_NEXT=FC-O45-E-BS_source_patch_restore_or_surface_recent_completed_companion_job_after_refresh_no_runtime
```
