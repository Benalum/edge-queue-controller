# Stage 16 FC-O45-E-BJ-R4 — Companion Structural Minimal Source Repair

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `3bb2005`
- Prior live deploy tag: `controller-stage-16-fc-o45-e-bi-deploy-companion-dedupe-minimal-visible-over-tailscale-restricted-path-2026-06-24`

## Purpose

BJ-R4 repairs the failed BJ dirty tree and keeps the correct direction:

- Render minimal signed-in Companion DOM directly.
- Preserve existing queued-chat IDs/classes.
- Place `window.__apcCompanionStructuralMinimalMode = true` before the first old Companion runtime IIFE.
- Guard old Companion runtime IIFEs so they do not mutate the DOM in structural mode.
- Avoid adding another MutationObserver or after-render cleanup loop.

## Scope

Modified repo source only:

- `frontend/wrapper-ui/app.js`
- `frontend/wrapper-ui/styles.css`
- `docs/stage-16-fc-o45-e-bj-companion-structural-minimal-source.md`
- `ops/smoke/check-stage-16-fc-o45-e-bj-companion-structural-minimal-source.sh`

No live deploy was performed.

Explicitly not allowed and not performed:

- NO live deploy.
- NO public `/var/www` mutation.
- NO DB write.
- NO job mutation.
- NO result insert.
- NO model/helper/Ollama call.
- NO model generation.
- NO scheduler activation.
- NO timer activation.
- NO persistent worker activation.
- NO backend API deploy.
- NO nginx/cloudflared config mutation.
- NO sshd config mutation.
- NO service restart/reload/start/stop/enable/disable.
- NO CT/VM restart.
- NO storage mutation.

## Source repair

BJ-R4 structurally replaces signed-in `renderQueuedChatPage()` with a minimal renderer that creates only:

```
Conversation
Type a message and press Enter to send.
Message
Send message
Clear
```

It preserves existing queued-chat IDs/classes:

- `queuedChatForm`
- `queuedChatMessages`
- `queuedChatInput`
- `queuedChatSendBtn`
- `queuedChatClearBtn`

This keeps current submit, polling, result, and clear handlers aligned.

Expected result after deploy:

- No old UI flash.
- No constant cleanup/reload feel from old Companion chrome scripts.
- No Thinking/Debug/Study/result-reader flicker.
- Minimal chat visible immediately.
- Existing queued-chat handlers remain compatible.
- Enter sends.
- Shift+Enter inserts a newline.
- Existing queued chat backend path remains unchanged.

## Next phase

Recommended next phase:

```
FC-O45-E-BK — deploy BJ-R4 structural minimal Companion source over the existing Tailscale restricted path
```

## Output

```
=== Stage 16 FC-O45-E-BJ-R4 Companion structural minimal dirty-tree repair ===
MUTATION_SCOPE=repo_source_docs_smoke_commit_tag_push_only
FIX=place_structural_flag_before_first_old_companion_runtime_and_preserve_existing_chat_ids
NO live deploy
NO public /var/www mutation
NO DB write
NO job mutation
NO result insert
NO model/helper/Ollama call
NO model generation
NO scheduler activation
NO timer activation
NO persistent worker activation
NO backend API deploy
NO nginx/cloudflared config mutation
NO sshd config mutation
NO service restart/reload/start/stop/enable/disable
NO CT/VM restart
NO storage mutation

=== git dirty-tree preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=3bb2005
head_now=3bb2005
origin_main_now=3bb2005
dirty_status_before:
 M frontend/wrapper-ui/app.js
 M frontend/wrapper-ui/styles.css
?? docs/stage-16-fc-o45-e-bj-companion-structural-minimal-source.md
?? ops/smoke/check-stage-16-fc-o45-e-bj-companion-structural-minimal-source.sh
dirty_tree_expected_from_failed_BJ=PASS

=== apply BJ-R4 structural source repair ===
=== source diff summary ===
diff --git a/frontend/wrapper-ui/app.js b/frontend/wrapper-ui/app.js
index 8a882ce..dd5417a 100644
--- a/frontend/wrapper-ui/app.js
+++ b/frontend/wrapper-ui/app.js
@@ -3737,12 +3737,12 @@ function queuedChatRenderMessages() {
 }
 
 function renderQueuedChatPage() {
-  const signedIn = Boolean(authState?.token);
-
-  // STAGE_5P8H_COMPANION_CANONICAL_RENDERER_BEGIN
-  // Canonical Companion renderer. This directly renders the polished UI while preserving
-  // the existing queued chat IDs used by bindQueuedChatPage / queuedChatSubmit.
-  if (!signedIn) {
+  /* Stage 16 FC-O45-E-BJ-R4 Companion structural minimal source.
+   * Signed-in Companion renders the minimal chat DOM directly.
+   * Existing queued-chat IDs/classes are preserved so current submit, polling,
+   * result, and clear handlers keep working.
+   */
+  if (!authState || !authState.token) {
     return `
       <section class="page-card stage5p8h-companion-page stage5p8h-companion-public" data-stage5p8h-canonical-companion="true">
         <p class="eyebrow">Companion</p>
@@ -3755,92 +3755,26 @@ function renderQueuedChatPage() {
   }
 
   return `
-    <section class="stage5p8h-companion-page" data-stage5p8h-canonical-companion="true" aria-label="Companion workspace">
-      <div class="stage5p8h-companion-hero">
-        <div>
-          <p class="stage5p8h-eyebrow">Companion</p>
-          <h1>Supportive chat workspace</h1>
-          <p>Talk with your local Companion while the queue handles work safely behind the scenes.</p>
-        </div>
-        <div class="stage5p8h-hero-badge">Queue-aware UI</div>
-      </div>
-
-      <div class="stage5p8h-companion-grid">
-        <section class="stage5p8h-conversation-card" aria-label="Companion conversation">
-          <div class="stage5p8h-empty-state">
-            <!-- Stage 16 FC-O45-E-BH removed companion empty icon -->
-            <div>
-              <!-- Stage 16 FC-O45-E-BF removed extra chat heading -->
-              <!-- Stage 16 FC-O45-E-BF removed queued-endpoint explanation -->
-            </div>
-          </div>
-
-          <section class="stage5p8h-message-stream">
-            <h2>Conversation</h2>
-            <div id="queuedChatMessages" class="stage5p8h-message-list"></div>
-          </section>
-
-          <form id="queuedChatForm" class="stage5p8h-message-form">
-            <label for="queuedChatInput">Message</label>
-            <textarea id="queuedChatInput" rows="5" placeholder="Message Companion..."></textarea>
-
-            <div class="stage5p8h-actions">
-              <button class="stage5p8h-send-button" type="submit" id="queuedChatSendBtn">Send message</button>
-              <button class="stage5p8h-clear-button" type="button" id="queuedChatClearBtn">Clear</button>
-            </div>
-          </form>
+    <section class="stage5p8h-companion-page stage16-fc-o45-e-bj-companion-minimal" data-stage5p8h-canonical-companion="true" data-stage16-fc-o45-e-bj="structural-minimal" aria-label="Companion workspace">
+      <section class="stage5p8h-conversation-card" aria-label="Companion conversation">
+        <section class="stage5p8h-message-stream">
+          <h2>Conversation</h2>
+          <p class="stage16-fc-o45-e-bj-helper">Type a message and press Enter to send.</p>
+          <div id="queuedChatMessages" class="stage5p8h-message-list"></div>
         </section>
 
-        <aside class="stage5p8h-status-rail" aria-label="Companion status">
-          <section class="stage5p8h-status-card">
-            <p class="stage5p8h-eyebrow">Companion status</p>
-            <div class="stage5p8h-status-row">
-              <span>Status</span>
-              <strong id="queuedChatStatus">Ready</strong>
-            </div>
-            <!-- STAGE_5P10G_SIMPLIFIED_QUEUE_DISPLAY_BEGIN -->
-            <div class="stage5p8h-status-row stage5p10g-queue-row">
-              <span>Queue</span>
-              <strong id="queuedChatQueueSummary">—</strong>
-            </div>
-            <!-- STAGE_5P10G_SIMPLIFIED_QUEUE_DISPLAY_END -->
-            <div class="stage5p8h-status-row">
-              <span>Worker</span>
-              <strong>Companion queue worker</strong>
-            </div>
-            <div class="stage5p8h-status-row">
-              <span>Model</span>
-              <strong>fallback: qwen2.5:0.5b</strong>
-            </div>
-          </section>
-
-          <section class="stage5p8h-status-card">
-            <p class="stage5p8h-eyebrow">How this works</p>
-            <p>
-              Messages continue through /api/chat/queued. The page polls the existing job status endpoint and displays the final assistant reply without changing backend behavior.
-            </p>
-          </section>
+        <form id="queuedChatForm" class="stage5p8h-message-form">
+          <label for="queuedChatInput">Message</label>
+          <textarea id="queuedChatInput" rows="5" placeholder="Message Companion..."></textarea>
 
-          <section class="stage5p8h-status-card stage5p11a-study-phrase-guide">
-            <!-- STAGE_5P11A_COMPANION_STUDY_PHRASE_GUIDE_BEGIN -->
-            <p class="stage5p8h-eyebrow">Study phrases</p>
-            <p>Use natural phrases with Companion to control Study sessions.</p>
-
-            <div class="stage5p11a-phrase-list">
-              <div><strong>Start:</strong> “Study session start” or “Start a study session.”</div>
-              <div><strong>Pause:</strong> “Study session pause.”</div>
-              <div><strong>Resume:</strong> “Study session resume.”</div>
-              <div><strong>Stop:</strong> “Study session stop.”</div>
-              <div><strong>Answer:</strong> “Read the answer.”</div>
-              <div><strong>Mark:</strong> “Correct,” “wrong,” or “skip.”</div>
-            </div>
-            <!-- STAGE_5P11A_COMPANION_STUDY_PHRASE_GUIDE_END -->
-          </section>
-        </aside>
-      </div>
+          <div class="stage5p8h-actions">
+            <button class="stage5p8h-send-button" type="submit" id="queuedChatSendBtn">Send message</button>
+            <button class="stage5p8h-clear-button" type="button" id="queuedChatClearBtn">Clear</button>
+          </div>
+        </form>
+      </section>
     </section>
   `;
-  // STAGE_5P8H_COMPANION_CANONICAL_RENDERER_END
 }
 
 
@@ -14216,7 +14150,19 @@ if (typeof window !== "undefined") {
  * - speaking
  * - needs_attention
  */
+/* Stage 16 FC-O45-E-BJ-R4 Companion structural minimal early flag.
+ * Must be defined before old Companion runtime IIFEs so they skip before mutating the DOM.
+ */
+if (typeof window !== "undefined") {
+  window.__apcCompanionStructuralMinimalMode = true;
+}
+
 (function stage16FcO45EAtWireCompanionImmersionPanel() {
+  if (window.__apcCompanionStructuralMinimalMode) {
+    window.__stage16FcO45EAtWireCompanionImmersionPanelSkippedForStructuralMinimalMode = true;
+    return;
+  }
+
   if (typeof window === "undefined" || window.__apcCompanionImmersionVisiblePanelInstalled) return;
   window.__apcCompanionImmersionVisiblePanelInstalled = true;
 
@@ -14488,6 +14434,11 @@ if (typeof window !== "undefined") {
  * - Keep the model label aligned with the proven qwen2.5:0.5b queue-worker path when the old fallback text is rendered.
  */
 (function stage16FcO45EAzCompanionImmersionPrimaryWorkspace() {
+  if (window.__apcCompanionStructuralMinimalMode) {
+    window.__stage16FcO45EAzCompanionImmersionPrimaryWorkspaceSkippedForStructuralMinimalMode = true;
+    return;
+  }
+
   if (window.__stage16FcO45EAzCompanionImmersionPrimaryWorkspaceInstalled) {
     return;
   }
@@ -14640,6 +14591,7 @@ if (typeof window !== "undefined") {
 })();
 
 
+
 /*
  * Stage 16 FC-O45-E-BB Companion clean chat workspace.
  *
@@ -14651,6 +14603,11 @@ if (typeof window !== "undefined") {
  * - Preserve existing queued chat endpoint, polling flow, result reader code, and backend behavior.
  */
 (function stage16FcO45EBbCompanionCleanChatWorkspace() {
+  if (window.__apcCompanionStructuralMinimalMode) {
+    window.__stage16FcO45EBbCompanionCleanChatWorkspaceSkippedForStructuralMinimalMode = true;
+    return;
+  }
+
   if (window.__stage16FcO45EBbCompanionCleanChatWorkspaceInstalled) {
     return;
   }
@@ -14842,6 +14799,11 @@ if (typeof window !== "undefined") {
  * - Companion result reader
  */
 (function stage16FcO45EBdCompanionHardCleanVisibleWorkspace() {
+  if (window.__apcCompanionStructuralMinimalMode) {
+    window.__stage16FcO45EBdCompanionHardCleanVisibleWorkspaceSkippedForStructuralMinimalMode = true;
+    return;
+  }
+
   if (window.__stage16FcO45EBdCompanionHardCleanVisibleWorkspaceInstalled) {
     return;
   }
@@ -15065,6 +15027,11 @@ if (typeof window !== "undefined") {
  * - Clear
  */
 (function stage16FcO45EBfCompanionMinimalChatSource() {
+  if (window.__apcCompanionStructuralMinimalMode) {
+    window.__stage16FcO45EBfCompanionMinimalChatSourceSkippedForStructuralMinimalMode = true;
+    return;
+  }
+
   if (window.__stage16FcO45EBfCompanionMinimalChatSourceInstalled) {
     return;
   }
@@ -15215,6 +15182,11 @@ if (typeof window !== "undefined") {
  * - Clear
  */
 (function stage16FcO45EBhCompanionDedupeMinimalVisibleSource() {
+  if (window.__apcCompanionStructuralMinimalMode) {
+    window.__stage16FcO45EBhCompanionDedupeMinimalVisibleSourceSkippedForStructuralMinimalMode = true;
+    return;
+  }
+
   if (window.__stage16FcO45EBhCompanionDedupeMinimalVisibleSourceInstalled) {
     return;
   }
@@ -15393,3 +15365,55 @@ if (typeof window !== "undefined") {
 
   runBoundedCleanup();
 })();
+
+
+/*
+ * Stage 16 FC-O45-E-BJ-R4 Companion structural minimal runtime.
+ *
+ * The Companion route renders minimal chat DOM directly. This runtime only installs
+ * Enter-to-send. It does not hide legacy panels after render and does not install a MutationObserver.
+ */
+(function stage16FcO45EBjR4CompanionStructuralMinimalRuntime() {
+  if (window.__stage16FcO45EBjR4CompanionStructuralMinimalRuntimeInstalled) {
+    return;
+  }
+  window.__stage16FcO45EBjR4CompanionStructuralMinimalRuntimeInstalled = true;
+
+  function installEnterToSend() {
+    const form = document.getElementById("queuedChatForm");
+    const textarea = document.getElementById("queuedChatInput");
+    if (!form || !textarea || textarea.dataset.stage16FcO45EBjR4EnterInstalled === "true") {
+      return;
+    }
+    textarea.dataset.stage16FcO45EBjR4EnterInstalled = "true";
+    textarea.addEventListener("keydown", (event) => {
+      if (event.key !== "Enter" || event.shiftKey || event.ctrlKey || event.altKey || event.metaKey || event.isComposing) {
+        return;
+      }
+      event.preventDefault();
+      if (typeof form.requestSubmit === "function") {
+        form.requestSubmit();
+      } else {
+        form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
+      }
+    });
+  }
+
+  function installMinimalHelpers() {
+    installEnterToSend();
+  }
+
+  document.addEventListener("DOMContentLoaded", installMinimalHelpers);
+  window.addEventListener("load", installMinimalHelpers);
+  window.addEventListener("hashchange", () => window.setTimeout(installMinimalHelpers, 0));
+  window.addEventListener("popstate", () => window.setTimeout(installMinimalHelpers, 0));
+
+  window.apcCompanionStructuralMinimalWorkspace = Object.freeze({
+    marker: "stage16FcO45EBjR4CompanionStructuralMinimalRuntime",
+    apply: installMinimalHelpers,
+    installEnterToSend,
+  });
+
+  installMinimalHelpers();
+})();
+
diff --git a/frontend/wrapper-ui/styles.css b/frontend/wrapper-ui/styles.css
index 656dc2c..6559e58 100644
--- a/frontend/wrapper-ui/styles.css
+++ b/frontend/wrapper-ui/styles.css
@@ -3121,3 +3121,87 @@ body[data-current-route="/support"] .public-feature-gate .summary-box {
   display: block;
 }
 
+
+
+/* Stage 16 FC-O45-E-BJ Companion structural minimal CSS. */
+.stage16-fc-o45-e-bj-companion-minimal {
+  display: grid;
+  gap: 1rem;
+}
+
+.stage16-fc-o45-e-bj-companion-minimal .stage5p8h-conversation-card {
+  display: grid;
+  gap: 1rem;
+}
+
+.stage16-fc-o45-e-bj-companion-minimal .stage5p8h-conversation-header h2 {
+  margin-bottom: 0.25rem;
+}
+
+.stage16-fc-o45-e-bj-companion-minimal .stage5p8h-message-form {
+  display: grid;
+  gap: 0.75rem;
+}
+
+.stage16-fc-o45-e-bj-companion-minimal .stage5p8h-form-actions {
+  display: flex;
+  gap: 0.75rem;
+  flex-wrap: wrap;
+}
+
+
+
+/* Stage 16 FC-O45-E-BJ-R3 Companion structural minimal CSS. */
+.stage16-fc-o45-e-bj-companion-minimal {
+  display: grid;
+  gap: 1rem;
+}
+
+.stage16-fc-o45-e-bj-companion-minimal .stage5p8h-conversation-card {
+  display: grid;
+  gap: 1rem;
+}
+
+.stage16-fc-o45-e-bj-companion-minimal .stage5p8h-message-stream {
+  display: grid;
+  gap: 0.5rem;
+}
+
+.stage16-fc-o45-e-bj-companion-minimal .stage16-fc-o45-e-bj-helper {
+  margin-top: 0;
+  opacity: 0.9;
+}
+
+.stage16-fc-o45-e-bj-companion-minimal .stage5p8h-message-form {
+  display: grid;
+  gap: 0.75rem;
+}
+
+
+
+/* Stage 16 FC-O45-E-BJ-R4 Companion structural minimal CSS. */
+.stage16-fc-o45-e-bj-companion-minimal {
+  display: grid;
+  gap: 1rem;
+}
+
+.stage16-fc-o45-e-bj-companion-minimal .stage5p8h-conversation-card {
+  display: grid;
+  gap: 1rem;
+}
+
+.stage16-fc-o45-e-bj-companion-minimal .stage5p8h-message-stream {
+  display: grid;
+  gap: 0.5rem;
+}
+
+.stage16-fc-o45-e-bj-companion-minimal .stage16-fc-o45-e-bj-helper {
+  margin-top: 0;
+  opacity: 0.9;
+}
+
+.stage16-fc-o45-e-bj-companion-minimal .stage5p8h-message-form {
+  display: grid;
+  gap: 0.75rem;
+}
+

=== corrected structural checks ===
PASS: renderQueuedChatPage structural minimal body excludes legacy copy and preserves existing IDs
PASS: structural minimal flag is before old Companion runtime IIFEs
PASS: old Companion runtime IIFEs are guarded
3740:  /* Stage 16 FC-O45-E-BJ-R4 Companion structural minimal source.
14153:/* Stage 16 FC-O45-E-BJ-R4 Companion structural minimal early flag.
15376:(function stage16FcO45EBjR4CompanionStructuralMinimalRuntime() {
15377:  if (window.__stage16FcO45EBjR4CompanionStructuralMinimalRuntimeInstalled) {
15380:  window.__stage16FcO45EBjR4CompanionStructuralMinimalRuntimeInstalled = true;
15412:    marker: "stage16FcO45EBjR4CompanionStructuralMinimalRuntime",
15411:  window.apcCompanionStructuralMinimalWorkspace = Object.freeze({
3722:  const el = document.getElementById("queuedChatMessages");
3763:          <div id="queuedChatMessages" class="stage5p8h-message-list"></div>
3767:          <label for="queuedChatInput">Message</label>
3768:          <textarea id="queuedChatInput" rows="5" placeholder="Message Companion..."></textarea>
4877:  const input = document.getElementById("queuedChatInput");
15384:    const textarea = document.getElementById("queuedChatInput");
3771:            <button class="stage5p8h-send-button" type="submit" id="queuedChatSendBtn">Send message</button>
4878:  const button = document.getElementById("queuedChatSendBtn");
3772:            <button class="stage5p8h-clear-button" type="button" id="queuedChatClearBtn">Clear</button>
5059:  const clearBtn = document.getElementById("queuedChatClearBtn");
3182:/* Stage 16 FC-O45-E-BJ-R4 Companion structural minimal CSS. */
source_repair=PASS
```
