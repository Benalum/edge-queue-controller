# Stage 16 FC-O45-E-BB — Companion Clean Chat Workspace Source

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `215f14d`
- Prior live deploy tag: `controller-stage-16-fc-o45-e-ba-deploy-companion-immersion-primary-workspace-over-tailscale-restricted-path-2026-06-24`

## Purpose

After BA, user observation showed the Companion page still included too much debug/admin chrome:

- Companion auth test
- Supportive chat workspace header text
- Companion status
- How this works
- Study phrases
- Companion result reader

The desired primary view is simpler:

```
Chat with your Companion
Conversation
Message
Send message
Clear
```

The user also requested Enter-to-send so sending does not require clicking the Send Message button.

## Scope

Modified repo source only:

- `frontend/wrapper-ui/app.js`
- `frontend/wrapper-ui/styles.css`

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
- NO deletion.

## Source changes

BB adds source markers:

- `Stage 16 FC-O45-E-BB Companion clean chat workspace`
- `window.apcCompanionCleanChatWorkspace`
- `installEnterToSend`
- `Stage 16 FC-O45-E-BB Companion clean chat workspace CSS`
- `.companion-clean-hidden`

Behavior added in source:

1. Hide Companion auth test from the primary flow.
2. Hide Companion status from the primary flow.
3. Hide How this works from the primary flow.
4. Hide Study phrases from the primary flow.
5. Hide Companion result reader from the primary flow.
6. Hide supportive/debug product text.
7. Rename the chat card to `Chat with your Companion`.
8. Change the helper copy to `Type a message and press Enter to send.`
9. Add Enter-to-send for the Companion message field.
10. Preserve Shift+Enter for newline.
11. Preserve existing queued chat endpoint, polling flow, and backend behavior.

## Next phase

Recommended next phase:

```
FC-O45-E-BC — deploy BB clean chat workspace over the existing Tailscale restricted path
```

BC should use:

```
cat package.tgz | ssh apcdeploy@website-edge 'deploy sha256=<sha256> bust=<cache-bust-token>'
```

## Output

```
=== Stage 16 FC-O45-E-BB Companion clean chat workspace source patch ===
MUTATION_SCOPE=repo_source_docs_smoke_commit_tag_push_only
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
NO deletion

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=215f14d
head_now=215f14d
origin_main_now=215f14d
git_preflight=PASS

=== source marker preflight ===
14481: * Stage 16 FC-O45-E-AZ Companion Immersion primary workspace placement.
14634:  window.apcCompanionImmersionPrimaryWorkspace = Object.freeze({
3813:              <strong>fallback: qwen2.5:0.5b</strong>
14604:        node.textContent = "fallback: qwen2.5:0.5b";
3026:#companionImmersionPrimaryWorkspace {
3030:#companionImmersionPrimaryWorkspace #companionImmersionVisiblePanel {
3034:#companionImmersionPrimaryWorkspace .companion-immersion-panel {
3038:#companionImmersionPrimaryWorkspace .companion-immersion-state {
3042:#companionImmersionPrimaryWorkspace .companion-immersion-debug:not([open]) pre {

=== apply BB source patch ===
=== source patch diff summary ===
diff --git a/frontend/wrapper-ui/app.js b/frontend/wrapper-ui/app.js
index 8e41f89..cb1a007 100644
--- a/frontend/wrapper-ui/app.js
+++ b/frontend/wrapper-ui/app.js
@@ -3770,7 +3770,7 @@ function renderQueuedChatPage() {
           <div class="stage5p8h-empty-state">
             <div class="stage5p8h-empty-icon">💬</div>
             <div>
-              <h2>Start a Companion conversation</h2>
+              <h2>Chat with your Companion</h2>
               <p>Send a message below. New work still uses the existing queued chat endpoint and polling flow.</p>
             </div>
           </div>
@@ -10701,7 +10701,7 @@ async function handleResetPasswordRoute() {
     empty.innerHTML = [
       '<div class="stage5o35-empty-icon">💬</div>',
       '<div>',
-      '<h2>Start a Companion conversation</h2>',
+      '<h2>Chat with your Companion</h2>',
       '<p>Send a message below. New work still uses the existing queued chat endpoint and polling flow.</p>',
       '</div>'
     ].join("");
@@ -13598,7 +13598,7 @@ function stage8lObserveRouterShadowReadDisabled(payload) {
     const bodyText = visibleText(document.body);
     return bodyText.includes("Companion") &&
       (bodyText.includes("Supportive chat workspace") ||
-       bodyText.includes("Start a Companion conversation"));
+       bodyText.includes("Chat with your Companion"));
   }
 
   function removeStudyToolsBox() {
@@ -13618,7 +13618,7 @@ function stage8lObserveRouterShadowReadDisabled(payload) {
           text.includes("Review queue");
         const tooBroad =
           text.includes("Companion status") ||
-          text.includes("Start a Companion conversation") ||
+          text.includes("Chat with your Companion") ||
           text.includes("How this works");
         if (looksLikeStudyBox && !tooBroad) {
           parent.remove();
@@ -13808,7 +13808,7 @@ function stage8lObserveRouterShadowReadDisabled(payload) {
     const bodyText = visibleText(document.body);
     return bodyText.includes("Companion") &&
       (bodyText.includes("Supportive chat workspace") ||
-       bodyText.includes("Start a Companion conversation"));
+       bodyText.includes("Chat with your Companion"));
   }
 
   function findBearerToken() {
@@ -14638,3 +14638,182 @@ if (typeof window !== "undefined") {
 
   scheduleApply();
 })();
+
+
+/*
+ * Stage 16 FC-O45-E-BB Companion clean chat workspace.
+ *
+ * Source-only UI refinement:
+ * - Hide Companion auth test, Companion status, How this works, Study phrases, and Companion result reader from the primary user flow.
+ * - Remove the debug/product header feel from the Companion page.
+ * - Rename the chat card to "Chat with your Companion".
+ * - Add Enter-to-send for the Companion message box while preserving Shift+Enter for a newline.
+ * - Preserve existing queued chat endpoint, polling flow, result reader code, and backend behavior.
+ */
+(function stage16FcO45EBbCompanionCleanChatWorkspace() {
+  if (window.__stage16FcO45EBbCompanionCleanChatWorkspaceInstalled) {
+    return;
+  }
+  window.__stage16FcO45EBbCompanionCleanChatWorkspaceInstalled = true;
+
+  const BB_MARKER = "stage16FcO45EBbCompanionCleanChatWorkspace";
+
+  function safeText(node) {
+    return (node && node.textContent ? node.textContent : "").replace(/\s+/g, " ").trim();
+  }
+
+  function allElements() {
+    return Array.from((document.querySelector("main") || document.body).querySelectorAll("*"));
+  }
+
+  function closestBlock(node) {
+    if (!node) return null;
+    return node.closest("section, article, fieldset, .card, .panel, .summary-box, .auth-card, .status-card, .result-card, div");
+  }
+
+  function hideBlockByContent(requiredText, reason) {
+    const needle = String(requiredText || "").toLowerCase();
+    const match = allElements().find((node) => {
+      const text = safeText(node).toLowerCase();
+      return text.includes(needle);
+    });
+    if (!match) return false;
+    const block = closestBlock(match);
+    if (!block || block === document.body || block === document.documentElement) return false;
+    block.classList.add("companion-clean-hidden");
+    block.setAttribute("data-stage16-fc-o45-e-bb-hidden", reason);
+    return true;
+  }
+
+  function hideExactTextElement(text, reason) {
+    const wanted = String(text || "").toLowerCase();
+    let didHide = false;
+    allElements().forEach((node) => {
+      if (safeText(node).toLowerCase() === wanted) {
+        node.classList.add("companion-clean-hidden");
+        node.setAttribute("data-stage16-fc-o45-e-bb-hidden", reason);
+        didHide = true;
+      }
+    });
+    return didHide;
+  }
+
+  function renameText(oldText, newText) {
+    const wanted = String(oldText || "").toLowerCase();
+    allElements().forEach((node) => {
+      if (node.children && node.children.length) return;
+      if (safeText(node).toLowerCase() === wanted) {
+        node.textContent = newText;
+        node.setAttribute("data-stage16-fc-o45-e-bb-renamed", "chat-title");
+      }
+    });
+  }
+
+  function cleanCompanionChrome() {
+    hideBlockByContent("Checks your signed-in Companion connection without creating a queue job.", "companion-auth-test");
+    hideBlockByContent("Read a completed Companion job result by job id.", "companion-result-reader");
+    hideBlockByContent("Messages continue through /api/chat/queued.", "how-this-works");
+    hideBlockByContent("Use natural phrases with Companion to control Study sessions.", "study-phrases");
+    hideBlockByContent("Companion status Status Ready Queue", "companion-status");
+
+    hideExactTextElement("Supportive chat workspace", "supportive-chat-subtitle");
+    hideExactTextElement("Talk with your local Companion while the queue handles work safely behind the scenes.", "supportive-chat-description");
+    hideExactTextElement("Queue-aware UI", "queue-aware-chip");
+
+    renameText("Start a Companion conversation", "Chat with your Companion");
+    renameText("Start a companion conversation", "Chat with your Companion");
+
+    allElements().forEach((node) => {
+      const text = safeText(node);
+      if (text === "Send a message below. New work still uses the existing queued chat endpoint and polling flow.") {
+        node.classList.add("companion-clean-hidden");
+        node.setAttribute("data-stage16-fc-o45-e-bb-hidden", "queued-chat-explanation");
+      }
+      if (text === "Send a message to start a queued local AI chat.") {
+        node.textContent = "Type a message and press Enter to send.";
+        node.setAttribute("data-stage16-fc-o45-e-bb-renamed", "message-helper");
+      }
+    });
+  }
+
+  function findCompanionMessageField() {
+    const fields = Array.from(document.querySelectorAll("textarea, input[type='text'], input:not([type])"));
+    return fields.find((field) => {
+      const labelText = safeText(field.closest("label") || field.parentElement || document.body).toLowerCase();
+      const nameish = [
+        field.getAttribute("name"),
+        field.getAttribute("id"),
+        field.getAttribute("placeholder"),
+        field.getAttribute("aria-label")
+      ].filter(Boolean).join(" ").toLowerCase();
+      return /message|companion|chat/.test(labelText + " " + nameish);
+    }) || null;
+  }
+
+  function findSendButton(field) {
+    const form = field ? field.closest("form") : null;
+    const root = form || (document.querySelector("main") || document.body);
+    return Array.from(root.querySelectorAll("button, input[type='submit']"))
+      .find((button) => /send message|send/i.test(safeText(button) || button.value || "")) || null;
+  }
+
+  function installEnterToSend() {
+    const field = findCompanionMessageField();
+    if (!field || field.dataset.stage16FcO45EBbEnterToSend === "1") return false;
+
+    field.dataset.stage16FcO45EBbEnterToSend = "1";
+    field.addEventListener("keydown", (event) => {
+      if (event.key !== "Enter") return;
+      if (event.shiftKey) return;
+
+      const tag = String(field.tagName || "").toLowerCase();
+      if (tag === "textarea" || tag === "input") {
+        event.preventDefault();
+      }
+
+      const sendButton = findSendButton(field);
+      if (sendButton && !sendButton.disabled) {
+        sendButton.click();
+      } else {
+        const form = field.closest("form");
+        if (form && typeof form.requestSubmit === "function") {
+          form.requestSubmit();
+        }
+      }
+    });
+
+    field.setAttribute("data-stage16-fc-o45-e-bb-enter-to-send", "true");
+    return true;
+  }
+
+  function applyCleanChatWorkspace() {
+    cleanCompanionChrome();
+    installEnterToSend();
+  }
+
+  let scheduled = false;
+  function scheduleApply() {
+    if (scheduled) return;
+    scheduled = true;
+    window.requestAnimationFrame(() => {
+      scheduled = false;
+      applyCleanChatWorkspace();
+    });
+  }
+
+  document.addEventListener("DOMContentLoaded", scheduleApply);
+  window.addEventListener("load", scheduleApply);
+  window.addEventListener("hashchange", scheduleApply);
+  window.addEventListener("popstate", scheduleApply);
+
+  const observer = new MutationObserver(scheduleApply);
+  observer.observe(document.documentElement, { childList: true, subtree: true });
+
+  window.apcCompanionCleanChatWorkspace = Object.freeze({
+    marker: BB_MARKER,
+    apply: applyCleanChatWorkspace,
+    installEnterToSend,
+  });
+
+  scheduleApply();
+})();
diff --git a/frontend/wrapper-ui/styles.css b/frontend/wrapper-ui/styles.css
index 6404dc8..d30eb78 100644
--- a/frontend/wrapper-ui/styles.css
+++ b/frontend/wrapper-ui/styles.css
@@ -3052,3 +3052,28 @@ body[data-current-route="/support"] .public-feature-gate .summary-box {
   font-size: 0.85em;
 }
 
+
+
+/* Stage 16 FC-O45-E-BB Companion clean chat workspace CSS. */
+.companion-clean-hidden {
+  display: none !important;
+}
+
+[data-stage16-fc-o45-e-bb-renamed="chat-title"] {
+  font-size: 1.2rem;
+  font-weight: 700;
+}
+
+[data-stage16-fc-o45-e-bb-renamed="message-helper"] {
+  opacity: 0.82;
+}
+
+#companionImmersionPrimaryWorkspace {
+  margin-top: 0.75rem;
+  margin-bottom: 1rem;
+}

=== syntax and marker checks ===
14644: * Stage 16 FC-O45-E-BB Companion clean chat workspace.
14812:  window.apcCompanionCleanChatWorkspace = Object.freeze({
14760:  function installEnterToSend() {
14791:    installEnterToSend();
14815:    installEnterToSend,
3773:              <h2>Chat with your Companion</h2>
10704:      '<h2>Chat with your Companion</h2>',
13601:       bodyText.includes("Chat with your Companion"));
13621:          text.includes("Chat with your Companion") ||
13811:       bodyText.includes("Chat with your Companion"));
14649: * - Rename the chat card to "Chat with your Companion".
14723:    renameText("Start a Companion conversation", "Chat with your Companion");
14724:    renameText("Start a companion conversation", "Chat with your Companion");
3057:/* Stage 16 FC-O45-E-BB Companion clean chat workspace CSS. */
3058:.companion-clean-hidden {
source_patch=PASS
```
