# Stage 16 FC-O45-E-AT — Companion Immersion Visible Panel Source-Only

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `084a5c4`
- Prior tag: `controller-stage-16-fc-o45-e-as-companion-immersion-ui-scaffold-source-only-2026-06-24`

## Scope

This phase modifies repo source only and records docs/smoke.

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
- NO public `/var/www` mutation.
- NO service restart/reload/start/stop/enable/disable.
- NO CT/VM restart.
- NO nginx/cloudflared/storage mutation.
- NO file deletion.

## Source changes

Files changed:

- `frontend/wrapper-ui/app.js`
- `frontend/wrapper-ui/styles.css`

Added visible-source wiring markers:

- `Stage 16 FC-O45-E-AT Companion Immersion visible panel source wiring`
- `stage16FcO45EAtWireCompanionImmersionPanel`
- `companionImmersionEnsureMount`
- `companionImmersionSetRuntime`
- `companionImmersionRenderVisiblePanel`
- `companionImmersionProcessQueuedChatResponse`
- `apcCompanionImmersionObservedFetch`
- `window.apcCompanionImmersionRuntime`
- `#companionImmersionVisiblePanel`

## Behavior

This source-only wiring prepares the live Companion page to show Immersion Mode after a separate deploy.

It observes the existing `/api/chat/queued` fetch flow without creating new requests or jobs.

Expected visible behavior after later deploy:

```
You: <last user message>

Companion: Listening / Thinking / Speaking / Needs attention

<last response when available>

Debug details
```

## Important safety boundary

This phase does not publish the UI. It only changes repo source.

Deploy remains a separate approval-gated phase.

## Next recommended phase

Next phase should be a no-runtime source/readiness check or deploy contract:

```
FC-O45-E-AU — Companion Immersion visible panel deploy readiness
```

Then, only after explicit approval, a deploy phase can copy the wrapper UI to the live public static location and verify the cache-busted app.js marker.

## Live output

```
=== Stage 16 FC-O45-E-AT Companion Immersion visible panel source-only ===
MUTATION_SCOPE=repo_source_docs_smoke_commit_tag_push_only
ALLOWED: modify repo source files only
ALLOWED: wire Companion Immersion panel into source UI path
ALLOWED: observe existing /api/chat/queued fetches without creating extra jobs
NO DB write
NO job mutation
NO result insert
NO model/helper/Ollama call
NO model generation
NO scheduler activation
NO timer activation
NO persistent worker activation
NO backend/frontend deploy
NO public /var/www mutation
NO service restart/reload/start/stop/enable/disable
NO CT/VM restart
NO nginx/cloudflared/storage mutation
NO file deletion

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=084a5c4
head_now=084a5c4
origin_main_now=084a5c4
git_preflight=PASS

=== source patch: wire visible Companion Immersion panel ===
patched=frontend/wrapper-ui/app.js
patched=frontend/wrapper-ui/styles.css

=== patch markers ===
14204: * Stage 16 FC-O45-E-AT Companion Immersion visible panel source wiring.
14219:(function stage16FcO45EAtWireCompanionImmersionPanel() {
14470:  window.apcCompanionImmersionRuntime = Object.freeze({
14422:    window.fetch = async function apcCompanionImmersionObservedFetch(input, init = {}) {
14389:  function companionImmersionProcessQueuedChatResponse(url, method, payload) {
14441:          companionImmersionProcessQueuedChatResponse(url, method, payload);
3001:/* Stage 16 FC-O45-E-AT Companion Immersion visible panel CSS wiring. */
3002:#companionImmersionVisiblePanel {
3006:#companionImmersionVisiblePanel .companion-immersion-panel {
3010:#companionImmersionVisiblePanel .companion-immersion-state {
3015:#companionImmersionVisiblePanel .companion-immersion-response {
3019:#companionImmersionVisiblePanel .companion-immersion-debug summary {

=== optional JS syntax check ===

=== git diff summary ===
diff --git a/frontend/wrapper-ui/app.js b/frontend/wrapper-ui/app.js
index 66c17ea..e702bd8 100644
--- a/frontend/wrapper-ui/app.js
+++ b/frontend/wrapper-ui/app.js
@@ -14199,3 +14199,279 @@ if (typeof window !== "undefined") {
   });
 }
 
+
+/**
+ * Stage 16 FC-O45-E-AT Companion Immersion visible panel source wiring.
+ *
+ * Source-only wiring. This does not deploy, does not create jobs, does not call
+ * models, and does not mutate backend state. When this source is later deployed,
+ * it observes the existing Companion queued-chat flow and renders a lightweight
+ * Immersion panel:
+ *
+ *   last user message + state + final response + optional debug details
+ *
+ * State labels:
+ * - listening
+ * - thinking
+ * - speaking
+ * - needs_attention
+ */
+(function stage16FcO45EAtWireCompanionImmersionPanel() {
+  if (typeof window === "undefined" || window.__apcCompanionImmersionVisiblePanelInstalled) return;
+  window.__apcCompanionImmersionVisiblePanelInstalled = true;
+
+  const IMMERSION_MOUNT_ID = "companionImmersionVisiblePanel";
+  const QUEUED_CHAT_PATH = "/api/chat/queued";
+  const runtime = {
+    lastUserMessage: "",
+    state: "listening",
+    job: {},
+    resultPayload: {},
+    queue_write: false,
+    worker: "Companion queue worker",
+  };
+
+  function companionImmersionIsCompanionRoute() {
+    const bodyRoute = document.body?.getAttribute("data-current-route") || "";
+    const path = window.location?.pathname || "";
+    return bodyRoute === "/companion" || path === "/companion" || path === "/chat";
+  }
+
+  function companionImmersionFindAnchor() {
+    const headings = Array.from(document.querySelectorAll("h1,h2,h3,h4,strong,summary"));
+    return headings.find((node) => {
+      const text = String(node.textContent || "").trim().toLowerCase();
+      return text === "conversation" ||
+        text === "companion" ||
+        text.includes("start a companion conversation") ||
+        text.includes("supportive chat workspace");
+    });
+  }
+
+  function companionImmersionEnsureMount() {
+    if (!companionImmersionIsCompanionRoute()) return null;
+
+    let mount = document.getElementById(IMMERSION_MOUNT_ID);
+    if (mount) return mount;
+
+    const main = document.querySelector("main") || document.querySelector("#app") || document.body;
+    if (!main) return null;
+
+    const anchor = companionImmersionFindAnchor();
+    const anchorCard = anchor?.closest?.("section,.summary-box,.feature-card,.clean-card,.study-card,.companion-card,.route-card,.panel,div");
+    mount = document.createElement("div");
+    mount.id = IMMERSION_MOUNT_ID;
+    mount.setAttribute("data-stage", "FC-O45-E-AT");
+    mount.setAttribute("data-companion-immersion-visible-panel", "true");
+
+    if (anchorCard && anchorCard.parentNode) {
+      anchorCard.parentNode.insertBefore(mount, anchorCard);
+    } else {
+      main.insertBefore(mount, main.firstChild);
+    }
+
+    return mount;
+  }
+
+  function companionImmersionSetRuntime(next = {}) {
+    if (typeof next.lastUserMessage === "string" && next.lastUserMessage.trim()) {
+      runtime.lastUserMessage = next.lastUserMessage.trim();
+    }
+    if (typeof next.state === "string" && next.state.trim()) {
+      runtime.state = next.state.trim();
+    }
+    if (next.job && typeof next.job === "object") {
+      runtime.job = { ...runtime.job, ...next.job };
+    }
+    if (next.resultPayload && typeof next.resultPayload === "object") {
+      runtime.resultPayload = { ...runtime.resultPayload, ...next.resultPayload };
+    }
+    if (typeof next.queue_write !== "undefined") {
+      runtime.queue_write = next.queue_write;
+    }
+    if (typeof next.worker === "string" && next.worker.trim()) {
+      runtime.worker = next.worker.trim();
+    }
+    companionImmersionRenderVisiblePanel();
+  }
+
+  function companionImmersionRenderVisiblePanel() {
+    if (!companionImmersionIsCompanionRoute()) return;
+
+    const api = window.apcCompanionImmersion;
+    if (!api || typeof api.renderPanel !== "function") return;
+
+    const mount = companionImmersionEnsureMount();
+    if (!mount) return;
+
+    const context = {
+      ...runtime.job,
+      ...runtime.resultPayload,
+      lastUserMessage: runtime.lastUserMessage,
+      state: runtime.state,
+      job: runtime.job,
+      resultPayload: runtime.resultPayload,
+      job_id: runtime.job.job_id || runtime.job.id || runtime.resultPayload.job_id,
+      status: runtime.job.status || runtime.resultPayload.status,
+      job_type: runtime.job.job_type || runtime.resultPayload.job_type,
+      requested_model: runtime.job.requested_model || runtime.resultPayload.requested_model,
+      queue_write: runtime.queue_write,
+      worker: runtime.worker,
+    };
+
+    mount.innerHTML = api.renderPanel(context);
+  }
+
+  function companionImmersionExtractMessageFromBody(body) {
+    if (!body) return "";
+
+    try {
+      if (typeof body === "string") {
+        const parsed = JSON.parse(body);
+        return companionImmersionExtractMessageFromObject(parsed);
+      }
+
+      if (body instanceof FormData) {
+        for (const key of ["message", "user_message", "prompt", "text", "input"]) {
+          const value = body.get(key);
+          if (typeof value === "string" && value.trim()) return value.trim();
+        }
+      }
+
+      if (body instanceof URLSearchParams) {
+        for (const key of ["message", "user_message", "prompt", "text", "input"]) {
+          const value = body.get(key);
+          if (typeof value === "string" && value.trim()) return value.trim();
+        }
+      }
+    } catch (_) {
+      return "";
+    }
+
+    return "";
+  }
+
+  function companionImmersionExtractMessageFromObject(payload) {
+    if (!payload || typeof payload !== "object") return "";
+
+    for (const key of ["message", "user_message", "prompt", "text", "input", "content"]) {
+      const value = payload[key];
+      if (typeof value === "string" && value.trim()) return value.trim();
+    }
+
+    for (const value of Object.values(payload)) {
+      if (value && typeof value === "object") {
+        const nested = companionImmersionExtractMessageFromObject(value);
+        if (nested) return nested;
+      }
+    }
+
+    return "";
+  }
+
+  function companionImmersionExtractJobFromPayload(payload) {
+    if (!payload || typeof payload !== "object") return {};
+
+    const job = payload.job && typeof payload.job === "object" ? payload.job : payload;
+    const jobId = payload.job_id || payload.id || job.job_id || job.id;
+    const status = payload.status || job.status;
+    const jobType = payload.job_type || job.job_type;
+    const requestedModel = payload.requested_model || job.requested_model;
+
+    return {
+      ...(jobId ? { job_id: jobId, id: jobId } : {}),
+      ...(status ? { status } : {}),
+      ...(jobType ? { job_type: jobType } : {}),
+      ...(requestedModel ? { requested_model: requestedModel } : {}),
+    };
+  }
+
+  function companionImmersionProcessQueuedChatResponse(url, method, payload) {
+    if (!payload || typeof payload !== "object") return;
+
+    const job = companionImmersionExtractJobFromPayload(payload);
+    const api = window.apcCompanionImmersion;
+    const resultText = api?.extractResultText?.(payload) || api?.extractResultText?.(payload.result || {}) || "";
+
+    let state = "listening";
+    const status = String(job.status || payload.status || "").toLowerCase();
+
+    if (payload.error || status === "failed" || status === "error") {
+      state = "needs_attention";
+    } else if (resultText || status === "completed" || status === "complete") {
+      state = "speaking";
+    } else if (method === "POST" || status === "queued" || status === "running" || status === "pending" || status === "claimed") {
+      state = "thinking";
+    }
+
+    companionImmersionSetRuntime({
+      state,
+      job,
+      resultPayload: payload,
+      queue_write: typeof payload.queue_write === "undefined" ? false : payload.queue_write,
+    });
+  }
+
+  function companionImmersionInstallFetchObserver() {
+    if (window.__apcCompanionImmersionFetchObserverInstalled) return;
+    window.__apcCompanionImmersionFetchObserverInstalled = true;
+
+    const originalFetch = window.fetch;
+    if (typeof originalFetch !== "function") return;
+
+    window.fetch = async function apcCompanionImmersionObservedFetch(input, init = {}) {
+      const url = typeof input === "string" ? input : String(input?.url || "");
+      const method = String(init?.method || input?.method || "GET").toUpperCase();
+      const isQueuedChat = url.includes(QUEUED_CHAT_PATH);
+
+      if (isQueuedChat && method === "POST") {
+        const message = companionImmersionExtractMessageFromBody(init?.body);
+        companionImmersionSetRuntime({
+          lastUserMessage: message || runtime.lastUserMessage,
+          state: "thinking",
+          job: { status: "queued" },
+          queue_write: true,
+        });
+      }
+
+      const response = await originalFetch.apply(this, arguments);
+
+      if (isQueuedChat && response && typeof response.clone === "function") {
+        response.clone().json().then((payload) => {
+          companionImmersionProcessQueuedChatResponse(url, method, payload);
+        }).catch(() => {
+          if (method === "POST") {
+            companionImmersionSetRuntime({ state: "thinking" });
+          }
+        });
+      }
+
+      return response;
+    };
+  }
+
+  function companionImmersionScheduleRender() {
+    window.requestAnimationFrame(() => {
+      companionImmersionRenderVisiblePanel();
+    });
+  }
+
+  companionImmersionInstallFetchObserver();
+  document.addEventListener("DOMContentLoaded", companionImmersionScheduleRender);
+  window.addEventListener("popstate", companionImmersionScheduleRender);
+  window.addEventListener("hashchange", companionImmersionScheduleRender);
+  window.addEventListener("apc:route-rendered", companionImmersionScheduleRender);
+
+  const observer = new MutationObserver(() => {
+    companionImmersionScheduleRender();
+  });
+  observer.observe(document.documentElement, { childList: true, subtree: true });
+
+  window.apcCompanionImmersionRuntime = Object.freeze({
+    set: companionImmersionSetRuntime,
+    render: companionImmersionRenderVisiblePanel,
+  });
+
+  companionImmersionScheduleRender();
+})();
+
diff --git a/frontend/wrapper-ui/styles.css b/frontend/wrapper-ui/styles.css
index 2edffb2..3af078c 100644
--- a/frontend/wrapper-ui/styles.css
+++ b/frontend/wrapper-ui/styles.css
@@ -2997,3 +2997,26 @@ body[data-current-route="/support"] .public-feature-gate .summary-box {
   margin: 0.5rem 0 0;
 }
 
+
+/* Stage 16 FC-O45-E-AT Companion Immersion visible panel CSS wiring. */
+#companionImmersionVisiblePanel {
+  margin: 0 0 1rem;
+}
+
+#companionImmersionVisiblePanel .companion-immersion-panel {
+  position: relative;
+}
+
+#companionImmersionVisiblePanel .companion-immersion-state {
+  text-transform: uppercase;
+  font-size: 0.82rem;
+}
+
+#companionImmersionVisiblePanel .companion-immersion-response {
+  font-size: 1.02rem;
+}
+
+#companionImmersionVisiblePanel .companion-immersion-debug summary {
+  cursor: pointer;
+}
+
```
