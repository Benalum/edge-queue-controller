# Stage 16 FC-O45-E-BV — Companion Stable Result Poller Source No-Runtime

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `8333c38`
- Prior proof tag: `controller-stage-16-fc-o45-e-bu-exact-job572-companion-qwen25-one-shot-worker-model-proof-2026-06-24`

## User-observed behavior

After BU completed job 572, the public Companion page did render the assistant response after hard reload:

```
Job 572
Assistant ... 
Status: completed
```

However, the page kept reloading/re-rendering, and after a while it could fall back to no conversation.

## Purpose

BV changes the Companion result-reader layer from aggressive repeated restore/poll behavior to a stable single-flight poller:

- On submit, store the job id and prompt.
- Poll one active job at a time.
- Wait until the job reaches `completed` or `failed`.
- Render the terminal response once.
- Stop polling after terminal status.
- Keep the rendered completed conversation visible until Clear is clicked.
- Restore only when the chat DOM remounts, using debounced restore.
- Avoid constant re-rendering by skipping identical render signatures.

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
stage16FcO45EBvCompanionStableResultPoller
activePollJobId
lastRenderSignature
scheduleRestoreLastQueuedJob
maxPolls: 120
intervalMs: 2000
force: true
Still queued. The worker may not be running yet.
```

## Next phase

```
FC-O45-E-BW — deploy stable Companion result poller over the existing restricted VM200 static deploy path
```

BW requires explicit approval because it mutates public static files.

## Output

```
=== Stage 16 FC-O45-E-BV Companion stable result poller source no-runtime ===
MUTATION_SCOPE=repo_frontend_source_docs_smoke_commit_tag_push_only
GOAL=single_flight_companion_poll_until_terminal_then_render_once_and_stop
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
expected_head=8333c38
head_now=8333c38
origin_main_now=8333c38
git_preflight=PASS

=== source preflight ===
source_preflight=PASS

=== patch BS layer into stable single-flight poller ===
BV_STABLE_POLLER_SOURCE_PATCH_APPLIED=PASS

=== source context after patch ===
5627:      loadProfilePreferencesForProfilePage({ force: true });
7201:    await sendWebPresence({ force: true });
7232:        { force: true }
15499:  let activePollJobId = "";
15500:  let lastRenderSignature = "";
15502:  root.stage16FcO45EBvCompanionStableResultPoller = {
15667:    if (signature === lastRenderSignature && messagesEl.innerHTML.trim()) {
15671:    lastRenderSignature = signature;
15741:    if (!force && activePollJobId === normalizedJobId) {
15745:    activePollJobId = normalizedJobId;
15767:            activePollJobId = "";
15778:          activePollJobId = "";
15785:      activePollJobId = "";
15791:        error: "Still queued. The worker may not be running yet."
15794:      if (activePollJobId === normalizedJobId) activePollJobId = "";
15812:    pollQueuedJob(jobId, { maxPolls: 120, intervalMs: 2000 });
15816:  function scheduleRestoreLastQueuedJob(delayMs) {
15868:              pollQueuedJob(jobId, { maxPolls: 120, intervalMs: 2000, force: true });
15901:    scheduleRestoreLastQueuedJob(120);
15905:    scheduleRestoreLastQueuedJob(0);
15909:    scheduleRestoreLastQueuedJob(120);
15913:    scheduleRestoreLastQueuedJob(120);
15928:          scheduleRestoreLastQueuedJob(120);
15932:      root.stage16FcO45EBvCompanionStableResultPoller.observer = true;
15935:    root.stage16FcO45EBvCompanionStableResultPoller.observer = false;
15938:  scheduleRestoreLastQueuedJob(0);

=== syntax check ===
node_syntax_check=PASS

=== git diff summary ===
 frontend/wrapper-ui/app.js | 159 +++++++++++++++++++++++++++++++++------------
 1 file changed, 116 insertions(+), 43 deletions(-)
diff --git a/frontend/wrapper-ui/app.js b/frontend/wrapper-ui/app.js
index 2a6ed62..aaa8727 100644
--- a/frontend/wrapper-ui/app.js
+++ b/frontend/wrapper-ui/app.js
@@ -15496,6 +15496,13 @@ if (typeof window !== "undefined") {
   };
 
   let pollGeneration = 0;
+  let activePollJobId = "";
+  let lastRenderSignature = "";
+  let restoreScheduled = false;
+  root.stage16FcO45EBvCompanionStableResultPoller = {
+    installed: true,
+    behavior: "single-flight poll until completed/failed, then stop and keep rendered result"
+  };
   const originalFetch = typeof root.fetch === "function" ? root.fetch.bind(root) : null;
 
   function delay(ms) {
@@ -15656,6 +15663,13 @@ if (typeof window !== "undefined") {
 
     if (!rows.length) return false;
 
+    const signature = JSON.stringify(rows);
+    if (signature === lastRenderSignature && messagesEl.innerHTML.trim()) {
+      if (view.status) setStatus(view.status === "completed" ? "Complete" : view.status);
+      return true;
+    }
+    lastRenderSignature = signature;
+
     messagesEl.innerHTML = rows.map((msg) => `
       <article class="summary-card queued-chat-message">
         <span>${escapeHtml(msg.role)}</span>
@@ -15711,40 +15725,73 @@ if (typeof window !== "undefined") {
 
   async function pollQueuedJob(jobId, options) {
     if (!originalFetch || !jobId) return;
+    const normalizedJobId = safeString(jobId).trim();
+    if (!normalizedJobId) return;
+
+    const force = Boolean(options && options.force);
+    const cachedStatus = getLast(storage.status);
+    const cachedReply = getLast(storage.reply);
+    const cachedJobId = getLast(storage.jobId);
+
+    if (!force && cachedJobId === normalizedJobId && cachedStatus === "completed" && cachedReply) {
+      renderCachedConversation();
+      return;
+    }
+
+    if (!force && activePollJobId === normalizedJobId) {
+      return;
+    }
+
+    activePollJobId = normalizedJobId;
     const generation = ++pollGeneration;
-    const maxPolls = Math.max(1, Number((options && options.maxPolls) || 20));
-    const intervalMs = Math.max(500, Number((options && options.intervalMs) || 1500));
+    const maxPolls = Math.max(1, Number((options && options.maxPolls) || 120));
+    const intervalMs = Math.max(1000, Number((options && options.intervalMs) || 2000));
 
-    for (let i = 0; i < maxPolls; i += 1) {
-      if (generation !== pollGeneration) return;
-      if (!companionElementsReady()) {
-        await delay(intervalMs);
-        continue;
-      }
+    try {
+      for (let i = 0; i < maxPolls; i += 1) {
+        if (generation !== pollGeneration) return;
+        if (!companionElementsReady()) {
+          await delay(intervalMs);
+          continue;
+        }
 
-      try {
-        setStatus(i === 0 ? "Loading last reply..." : `Waiting for worker... poll ${i + 1}`);
-        const payload = await fetchQueuedJob(jobId);
-        const view = normalizeQueuedJobPayload(payload);
-        if (!view.jobId) view.jobId = jobId;
-        persistView(view);
-        renderConversation(view);
-
-        if (view.status === "completed" || view.status === "failed") {
+        try {
+          setStatus(i === 0 ? "Waiting for worker..." : `Waiting for worker... poll ${i + 1}`);
+          const payload = await fetchQueuedJob(normalizedJobId);
+          const view = normalizeQueuedJobPayload(payload);
+          if (!view.jobId) view.jobId = normalizedJobId;
+          persistView(view);
+          renderConversation(view);
+
+          if (view.status === "completed" || view.status === "failed") {
+            activePollJobId = "";
+            return;
+          }
+        } catch (err) {
+          setStatus("Result reader error");
+          renderConversation({
+            jobId: normalizedJobId,
+            prompt: getLast(storage.prompt),
+            status: "error",
+            error: err && err.message ? err.message : String(err)
+          });
+          activePollJobId = "";
           return;
         }
-      } catch (err) {
-        setStatus("Result reader error");
-        renderConversation({
-          jobId,
-          prompt: getLast(storage.prompt),
-          status: "error",
-          error: err && err.message ? err.message : String(err)
-        });
-        return;
+
+        await delay(intervalMs);
       }
 
-      await delay(intervalMs);
+      activePollJobId = "";
+      setStatus("Queued job is still waiting.");
+      renderConversation({
+        jobId: normalizedJobId,
+        prompt: getLast(storage.prompt),
+        status: "queued",
+        error: "Still queued. The worker may not be running yet."
+      });
+    } finally {
+      if (activePollJobId === normalizedJobId) activePollJobId = "";
     }
   }
 
@@ -15752,11 +15799,29 @@ if (typeof window !== "undefined") {
     if (!companionElementsReady()) return false;
     const jobId = getLast(storage.jobId);
     if (!jobId) return false;
+
+    const status = getLast(storage.status);
+    const reply = getLast(storage.reply);
+
     renderCachedConversation();
-    pollQueuedJob(jobId, { maxPolls: 8, intervalMs: 1200 });
+
+    if ((status === "completed" && reply) || status === "failed") {
+      return true;
+    }
+
+    pollQueuedJob(jobId, { maxPolls: 120, intervalMs: 2000 });
     return true;
   }
 
+  function scheduleRestoreLastQueuedJob(delayMs) {
+    if (restoreScheduled) return;
+    restoreScheduled = true;
+    setTimeout(() => {
+      restoreScheduled = false;
+      restoreLastQueuedJob();
+    }, Math.max(0, Number(delayMs) || 0));
+  }
+
   function capturePromptFromForm() {
     const input = document.getElementById("queuedChatInput");
     const message = input && input.value ? input.value.trim() : "";
@@ -15800,7 +15865,7 @@ if (typeof window !== "undefined") {
               setLast(storage.jobId, jobId);
               setLast(storage.status, "queued");
               setLast(storage.updatedAt, new Date().toISOString());
-              pollQueuedJob(jobId, { maxPolls: 40, intervalMs: 1500 });
+              pollQueuedJob(jobId, { maxPolls: 120, intervalMs: 2000, force: true });
             } else if (method === "GET") {
               const view = normalizeQueuedJobPayload(payload);
               if (view.jobId || view.status || view.responseText) {
@@ -15833,35 +15898,43 @@ if (typeof window !== "undefined") {
       clearStoredConversation();
       return;
     }
-    setTimeout(restoreLastQueuedJob, 80);
-    setTimeout(restoreLastQueuedJob, 500);
+    scheduleRestoreLastQueuedJob(120);
   }, true);
 
   window.addEventListener("DOMContentLoaded", () => {
-    setTimeout(restoreLastQueuedJob, 0);
-    setTimeout(restoreLastQueuedJob, 500);
-    setTimeout(restoreLastQueuedJob, 1500);
+    scheduleRestoreLastQueuedJob(0);
   });
 
   window.addEventListener("hashchange", () => {
-    setTimeout(restoreLastQueuedJob, 80);
-    setTimeout(restoreLastQueuedJob, 500);
+    scheduleRestoreLastQueuedJob(120);
   });
 
   window.addEventListener("popstate", () => {
-    setTimeout(restoreLastQueuedJob, 80);
-    setTimeout(restoreLastQueuedJob, 500);
+    scheduleRestoreLastQueuedJob(120);
   });
 
   let bootTicks = 0;
   const bootTimer = window.setInterval(() => {
     bootTicks += 1;
-    restoreLastQueuedJob();
-    if (bootTicks >= 20) window.clearInterval(bootTimer);
+    const restored = restoreLastQueuedJob();
+    if (restored || bootTicks >= 8) window.clearInterval(bootTimer);
   }, 500);
 
-  setTimeout(restoreLastQueuedJob, 0);
-  setTimeout(restoreLastQueuedJob, 500);
-  setTimeout(restoreLastQueuedJob, 1500);
+  try {
+    const observerRoot = document.getElementById("app") || document.body;
+    if (observerRoot && root.MutationObserver) {
+      const observer = new MutationObserver(() => {
+        if (document.getElementById("queuedChatForm")) {
+          scheduleRestoreLastQueuedJob(120);
+        }
+      });
+      observer.observe(observerRoot, { childList: true, subtree: true });
+      root.stage16FcO45EBvCompanionStableResultPoller.observer = true;
+    }
+  } catch (_err) {
+    root.stage16FcO45EBvCompanionStableResultPoller.observer = false;
+  }
+
+  scheduleRestoreLastQueuedJob(0);
 })();
 

BV_STABLE_POLLER_SOURCE_PATCH_RECORDED=PASS
PATCHED_FILE=frontend/wrapper-ui/app.js
NEXT_REQUIRED=BW_deploy_stable_poller_over_restricted_static_path_after_approval
```
