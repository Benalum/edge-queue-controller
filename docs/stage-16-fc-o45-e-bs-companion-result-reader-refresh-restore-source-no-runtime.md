# Stage 16 FC-O45-E-BS — Companion Result-Reader Refresh Restore Source No-Runtime

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `ae5dde7`
- Prior diagnostic tag: `controller-stage-16-fc-o45-e-br-companion-ui-result-reader-refresh-diagnostic-read-only-2026-06-24`

## Purpose

BS adds a frontend source-only result-reader/refresh-restore layer for the Companion queued chat UI.

BR proved:

```
job_id=571
requested_model=qwen2.5:0.5b
status=completed
result_rows=1
```

but the browser hard-refresh Companion page still showed the empty start state. BS addresses that UI gap by adding a layer that:

- stores the last queued Companion job id after a send response,
- stores the prompt before the current submit handler clears the input,
- restores the last job after hard refresh,
- polls `/api/chat/queued/<job_id>` with the existing bearer token,
- renders completed `response_text` into `#queuedChatMessages`,
- preserves the existing form, send button, clear button, and delegated Enter-to-send behavior.

## Scope

Modified repo frontend source/docs/smoke only.

Explicitly not allowed and not performed:

- NO live deploy.
- NO public `/var/www` mutation.
- NO backend deploy.
- NO CT203 runtime patch.
- NO DB write.
- NO job mutation.
- NO result insert.
- NO model/helper/Ollama call.
- NO scheduler activation.
- NO timer activation.
- NO persistent worker activation.
- NO service restart/reload/start/stop/enable/disable.
- NO CT/VM restart.
- NO nginx/cloudflared/sshd config mutation.
- NO storage mutation.
- NO file deletion.

## Source markers

```
stage16FcO45EBsCompanionResultReaderRefreshRestore
apcCompanionQueuedChatLastJobId
fetchQueuedJob
pollQueuedJob
renderCachedConversation
```

## Next phase

```
FC-O45-E-BT — deploy the updated wrapper app.js over the existing restricted VM200 static deploy path
```

BT will require explicit approval because it mutates public static files.

## Output

```
=== Stage 16 FC-O45-E-BS Companion result-reader refresh restore source no-runtime ===
MUTATION_SCOPE=repo_frontend_source_docs_smoke_commit_tag_push_only
GOAL=add_companion_ui_result_reader_hard_refresh_restore_layer
NO live deploy
NO public /var/www mutation
NO backend deploy
NO CT203 runtime patch
NO DB write
NO job mutation
NO result insert
NO model/helper/Ollama call
NO scheduler activation
NO timer activation
NO persistent worker activation
NO service restart/reload/start/stop/enable/disable
NO CT/VM restart
NO nginx/cloudflared/sshd config mutation
NO storage mutation
NO file deletion

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=ae5dde7
head_now=ae5dde7
origin_main_now=ae5dde7
git_preflight=PASS

=== source preflight ===
3722:  const el = document.getElementById("queuedChatMessages");
3740:  /* Stage 16 FC-O45-E-BJ-R4 Companion structural minimal source.
3763:          <div id="queuedChatMessages" class="stage5p8h-message-list"></div>
3766:        <form id="queuedChatForm" class="stage5p8h-message-form">
3767:          <label for="queuedChatInput">Message</label>
3768:          <textarea id="queuedChatInput" rows="5" placeholder="Message Companion..."></textarea>
3771:            <button class="stage5p8h-send-button" type="submit" id="queuedChatSendBtn">Send message</button>
3772:            <button class="stage5p8h-clear-button" type="button" id="queuedChatClearBtn">Clear</button>
4877:  const input = document.getElementById("queuedChatInput");
4878:  const button = document.getElementById("queuedChatSendBtn");
5054:  const form = document.getElementById("queuedChatForm");
5059:  const clearBtn = document.getElementById("queuedChatClearBtn");
14153:/* Stage 16 FC-O45-E-BJ-R4 Companion structural minimal early flag.
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

=== append BS result-reader refresh restore layer ===
BS_RESULT_READER_REFRESH_RESTORE_PATCH_APPENDED=PASS

=== source context after patch ===
13820:    lines.push(String(data.response_text || result.response_text || ""));
13899:      if (data && data.has_result === true && data.response_text) {
15473: * Stage 16 FC-O45-E-BS: Companion result-reader hard-refresh restore.
15477: * authenticated queued-job status endpoint, and renders completed response_text.
15479:(function stage16FcO45EBsCompanionResultReaderRefreshRestore() {
15481:  const marker = "stage16FcO45EBsCompanionResultReaderRefreshRestore";
15485:    jobId: "apcCompanionQueuedChatLastJobId",
15605:        data.response_text ||
15609:        (data.result && (data.result.response_text || data.result.responseText)) ||
15610:        (Array.isArray(data.results) && data.results[0] && (data.results[0].response_text || data.results[0].responseText)) ||
15611:        findDeep(data, ["response_text", "responseText", "assistant_reply", "assistantReply", "completion", "output_text"], 6) ||
15679:  function renderCachedConversation() {
15689:  async function fetchQueuedJob(jobId) {
15712:  async function pollQueuedJob(jobId, options) {
15727:        const payload = await fetchQueuedJob(jobId);
15755:    renderCachedConversation();
15756:    pollQueuedJob(jobId, { maxPolls: 8, intervalMs: 1200 });
15803:              pollQueuedJob(jobId, { maxPolls: 40, intervalMs: 1500 });

=== syntax check ===
node_syntax_check=PASS

=== git diff summary ===
 frontend/wrapper-ui/app.js | 398 +++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 398 insertions(+)
diff --git a/frontend/wrapper-ui/app.js b/frontend/wrapper-ui/app.js
index bfba463..2a6ed62 100644
--- a/frontend/wrapper-ui/app.js
+++ b/frontend/wrapper-ui/app.js
@@ -15467,3 +15467,401 @@ if (typeof window !== "undefined") {
     sendButtonId: "queuedChatSendBtn",
   });
 })();
+
+
+/*
+ * Stage 16 FC-O45-E-BS: Companion result-reader hard-refresh restore.
+ *
+ * Source-only layer. It does not submit jobs by itself and does not call any model.
+ * It restores the last queued Companion job id after hard refresh, polls the
+ * authenticated queued-job status endpoint, and renders completed response_text.
+ */
+(function stage16FcO45EBsCompanionResultReaderRefreshRestore() {
+  const root = window;
+  const marker = "stage16FcO45EBsCompanionResultReaderRefreshRestore";
+  if (root[marker]) return;
+
+  const storage = {
+    jobId: "apcCompanionQueuedChatLastJobId",
+    prompt: "apcCompanionQueuedChatLastPrompt",
+    reply: "apcCompanionQueuedChatLastReply",
+    status: "apcCompanionQueuedChatLastStatus",
+    updatedAt: "apcCompanionQueuedChatLastUpdatedAt"
+  };
+
+  root[marker] = {
+    installed: true,
+    storageKey: storage.jobId,
+    source: "frontend/wrapper-ui/app.js"
+  };
+
+  let pollGeneration = 0;
+  const originalFetch = typeof root.fetch === "function" ? root.fetch.bind(root) : null;
+
+  function delay(ms) {
+    return new Promise((resolve) => setTimeout(resolve, ms));
+  }
+
+  function safeString(value) {
+    if (value === null || value === undefined) return "";
+    return String(value);
+  }
+
+  function escapeHtml(value) {
+    return safeString(value)
+      .replace(/&/g, "&amp;")
+      .replace(/</g, "&lt;")
+      .replace(/>/g, "&gt;")
+      .replace(/"/g, "&quot;")
+      .replace(/'/g, "&#39;");
+  }
+
+  function getToken() {
+    try {
+      return (
+        (root.authState && root.authState.token) ||
+        localStorage.getItem("edgeStudyToken") ||
+        ""
+      );
+    } catch (_err) {
+      return "";
+    }
+  }
+
+  function getLast(key) {
+    try {
+      return localStorage.getItem(key) || "";
+    } catch (_err) {
+      return "";
+    }
+  }
+
+  function setLast(key, value) {
+    try {
+      if (value === null || value === undefined || value === "") {
+        localStorage.removeItem(key);
+      } else {
+        localStorage.setItem(key, String(value));
+      }
+    } catch (_err) {
+      // Storage may be unavailable in private/browser-restricted contexts.
+    }
+  }
+
+  function clearStoredConversation() {
+    setLast(storage.jobId, "");
+    setLast(storage.prompt, "");
+    setLast(storage.reply, "");
+    setLast(storage.status, "");
+    setLast(storage.updatedAt, "");
+  }
+
+  function findDeep(value, keys, depth) {
+    if (!value || depth <= 0) return "";
+    if (Array.isArray(value)) {
+      for (const item of value) {
+        const found = findDeep(item, keys, depth - 1);
+        if (found) return found;
+      }
+      return "";
+    }
+    if (typeof value !== "object") return "";
+    for (const key of keys) {
+      if (Object.prototype.hasOwnProperty.call(value, key)) {
+        const candidate = value[key];
+        if (candidate !== null && candidate !== undefined && String(candidate).trim()) {
+          return String(candidate);
+        }
+      }
+    }
+    for (const nested of Object.values(value)) {
+      const found = findDeep(nested, keys, depth - 1);
+      if (found) return found;
+    }
+    return "";
+  }
+
+  function normalizeQueuedJobPayload(payload) {
+    const data = payload && typeof payload === "object" ? payload : {};
+    const job = data.job && typeof data.job === "object" ? data.job : data;
+
+    const jobId =
+      safeString(data.job_id || data.id || job.job_id || job.id || getLast(storage.jobId)).trim();
+
+    const prompt =
+      safeString(data.prompt || job.prompt || findDeep(data, ["prompt"], 5) || getLast(storage.prompt)).trim();
+
+    const requestedModel =
+      safeString(data.requested_model || job.requested_model || findDeep(data, ["requested_model"], 5)).trim();
+
+    const status =
+      safeString(data.status || job.status || findDeep(data, ["status"], 5) || getLast(storage.status)).trim();
+
+    const error =
+      safeString(data.error || job.error || data.last_error || job.last_error || findDeep(data, ["error", "last_error"], 5)).trim();
+
+    const responseText =
+      safeString(
+        data.response_text ||
+        data.responseText ||
+        data.assistant_reply ||
+        data.assistantReply ||
+        (data.result && (data.result.response_text || data.result.responseText)) ||
+        (Array.isArray(data.results) && data.results[0] && (data.results[0].response_text || data.results[0].responseText)) ||
+        findDeep(data, ["response_text", "responseText", "assistant_reply", "assistantReply", "completion", "output_text"], 6) ||
+        getLast(storage.reply)
+      ).trim();
+
+    return { jobId, prompt, requestedModel, status, error, responseText };
+  }
+
+  function companionElementsReady() {
+    return Boolean(
+      document.getElementById("queuedChatMessages") &&
+      document.getElementById("queuedChatForm")
+    );
+  }
+
+  function setStatus(text) {
+    const statusEl = document.getElementById("queuedChatStatus");
+    if (statusEl) statusEl.textContent = text;
+  }
+
+  function renderConversation(view) {
+    const messagesEl = document.getElementById("queuedChatMessages");
+    if (!messagesEl) return false;
+
+    const rows = [];
+    if (view.prompt) {
+      rows.push({
+        role: "You",
+        content: view.prompt,
+        detail: view.jobId ? `Job ${view.jobId}${view.requestedModel ? ` · ${view.requestedModel}` : ""}` : ""
+      });
+    }
+
+    if (view.responseText) {
+      rows.push({
+        role: "Assistant",
+        content: view.responseText,
+        detail: view.status ? `Status: ${view.status}` : "Completed"
+      });
+    } else if (view.status) {
+      rows.push({
+        role: view.status === "failed" ? "System" : "Companion",
+        content: view.status === "failed" ? "The queued job failed." : `Queued job is ${view.status}.`,
+        detail: view.error || (view.jobId ? `Job ${view.jobId}` : "")
+      });
+    }
+
+    if (!rows.length) return false;
+
+    messagesEl.innerHTML = rows.map((msg) => `
+      <article class="summary-card queued-chat-message">
+        <span>${escapeHtml(msg.role)}</span>
+        <strong>${escapeHtml(msg.content)}</strong>
+        ${msg.detail ? `<p>${escapeHtml(msg.detail)}</p>` : ""}
+      </article>
+    `).join("");
+
+    if (view.status) setStatus(view.status === "completed" ? "Complete" : view.status);
+    return true;
+  }
+
+  function persistView(view) {
+    if (view.jobId) setLast(storage.jobId, view.jobId);
+    if (view.prompt) setLast(storage.prompt, view.prompt);
+    if (view.responseText) setLast(storage.reply, view.responseText);
+    if (view.status) setLast(storage.status, view.status);
+    setLast(storage.updatedAt, new Date().toISOString());
+  }
+
+  function renderCachedConversation() {
+    if (!companionElementsReady()) return false;
+    const jobId = getLast(storage.jobId);
+    const prompt = getLast(storage.prompt);
+    const responseText = getLast(storage.reply);
+    const status = getLast(storage.status);
+    if (!jobId && !prompt && !responseText) return false;
+    return renderConversation({ jobId, prompt, responseText, status });
+  }
+
+  async function fetchQueuedJob(jobId) {
+    const token = getToken();
+    const headers = { "Cache-Control": "no-cache" };
+    if (token) headers.Authorization = `Bearer ${token}`;
+
+    const res = await originalFetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
+      method: "GET",
+      headers,
+      cache: "no-store"
+    });
+    const text = await res.text();
+    let data = null;
+    try {
+      data = text ? JSON.parse(text) : {};
+    } catch (_err) {
+      data = { error: text || `HTTP ${res.status}` };
+    }
+    if (!res.ok) {
+      throw new Error(`Queued status HTTP ${res.status}: ${text.slice(0, 180)}`);
+    }
+    return data;
+  }
+
+  async function pollQueuedJob(jobId, options) {
+    if (!originalFetch || !jobId) return;
+    const generation = ++pollGeneration;
+    const maxPolls = Math.max(1, Number((options && options.maxPolls) || 20));
+    const intervalMs = Math.max(500, Number((options && options.intervalMs) || 1500));
+
+    for (let i = 0; i < maxPolls; i += 1) {
+      if (generation !== pollGeneration) return;
+      if (!companionElementsReady()) {
+        await delay(intervalMs);
+        continue;
+      }
+
+      try {
+        setStatus(i === 0 ? "Loading last reply..." : `Waiting for worker... poll ${i + 1}`);
+        const payload = await fetchQueuedJob(jobId);
+        const view = normalizeQueuedJobPayload(payload);
+        if (!view.jobId) view.jobId = jobId;
+        persistView(view);
+        renderConversation(view);
+
+        if (view.status === "completed" || view.status === "failed") {
+          return;
+        }
+      } catch (err) {
+        setStatus("Result reader error");
+        renderConversation({
+          jobId,
+          prompt: getLast(storage.prompt),
+          status: "error",
+          error: err && err.message ? err.message : String(err)
+        });
+        return;
+      }
+
+      await delay(intervalMs);
+    }
+  }
+
+  function restoreLastQueuedJob() {
+    if (!companionElementsReady()) return false;
+    const jobId = getLast(storage.jobId);
+    if (!jobId) return false;
+    renderCachedConversation();
+    pollQueuedJob(jobId, { maxPolls: 8, intervalMs: 1200 });
+    return true;
+  }
+
+  function capturePromptFromForm() {
+    const input = document.getElementById("queuedChatInput");
+    const message = input && input.value ? input.value.trim() : "";
+    if (message) setLast(storage.prompt, message);
+  }
+
+  function extractUrl(input) {
+    try {
+      if (typeof input === "string") return input;
+      if (input && input.url) return input.url;
+    } catch (_err) {}
+    return "";
+  }
+
+  function extractMethod(input, init) {
+    return safeString((init && init.method) || (input && input.method) || "GET").toUpperCase();
+  }
+
+  function extractJobId(payload) {
+    const data = payload && typeof payload === "object" ? payload : {};
+    return safeString(
+      data.job_id ||
+      data.id ||
+      (data.job && (data.job.job_id || data.job.id)) ||
+      findDeep(data, ["job_id"], 4)
+    ).trim();
+  }
+
+  if (originalFetch && !root.stage16FcO45EBsFetchWrapped) {
+    root.stage16FcO45EBsFetchWrapped = true;
+    root.fetch = async function stage16FcO45EBsFetch(input, init) {
+      const method = extractMethod(input, init);
+      const url = extractUrl(input);
+      const response = await originalFetch(input, init);
+
+      try {
+        if (url.includes("/api/chat/queued")) {
+          response.clone().json().then((payload) => {
+            const jobId = extractJobId(payload);
+            if (method !== "GET" && jobId) {
+              setLast(storage.jobId, jobId);
+              setLast(storage.status, "queued");
+              setLast(storage.updatedAt, new Date().toISOString());
+              pollQueuedJob(jobId, { maxPolls: 40, intervalMs: 1500 });
+            } else if (method === "GET") {
+              const view = normalizeQueuedJobPayload(payload);
+              if (view.jobId || view.status || view.responseText) {
+                persistView(view);
+                renderConversation(view);
+              }
+            }
+          }).catch(() => {});
+        }
+      } catch (_err) {
+        // Fetch wrapper must never break the original caller.
+      }
+
+      return response;
+    };
+  }
+
+  document.addEventListener("submit", (event) => {
+    const form = event.target;
+    if (form && form.id === "queuedChatForm") {
+      capturePromptFromForm();
+      setStatus("Creating queued job...");
+    }
+  }, true);
+
+  document.addEventListener("click", (event) => {
+    const target = event.target && event.target.closest ? event.target.closest("#queuedChatClearBtn, a, button") : null;
+    if (!target) return;
+    if (target.id === "queuedChatClearBtn") {
+      clearStoredConversation();
+      return;
+    }
+    setTimeout(restoreLastQueuedJob, 80);
+    setTimeout(restoreLastQueuedJob, 500);
+  }, true);
+
+  window.addEventListener("DOMContentLoaded", () => {
+    setTimeout(restoreLastQueuedJob, 0);
+    setTimeout(restoreLastQueuedJob, 500);
+    setTimeout(restoreLastQueuedJob, 1500);
+  });
+
+  window.addEventListener("hashchange", () => {
+    setTimeout(restoreLastQueuedJob, 80);
+    setTimeout(restoreLastQueuedJob, 500);
+  });
+
+  window.addEventListener("popstate", () => {
+    setTimeout(restoreLastQueuedJob, 80);
+    setTimeout(restoreLastQueuedJob, 500);
+  });
+
+  let bootTicks = 0;
+  const bootTimer = window.setInterval(() => {
+    bootTicks += 1;
+    restoreLastQueuedJob();
+    if (bootTicks >= 20) window.clearInterval(bootTimer);
+  }, 500);
+
+  setTimeout(restoreLastQueuedJob, 0);
+  setTimeout(restoreLastQueuedJob, 500);
+  setTimeout(restoreLastQueuedJob, 1500);
+})();
+

BS_SOURCE_PATCH_RECORDED=PASS
PATCHED_FILE=frontend/wrapper-ui/app.js
NEXT_REQUIRED=BT_static_deploy_over_restricted_path_after_approval
```
