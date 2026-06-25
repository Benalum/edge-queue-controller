# Stage 16 FC-O45-E-BF — Companion Minimal Chat Source

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `12465de`
- Prior live deploy tag: `controller-stage-16-fc-o45-e-be-deploy-companion-hard-clean-workspace-over-tailscale-restricted-path-2026-06-24`

## Purpose

After BE, user observation requested removing more visible chrome:

- Remove the block with `Listening`, `Debug details`, and `Companion`.
- Remove the extra `Chat with your Companion` heading.
- Remove `Send a message below. New work still uses the existing queued chat endpoint and polling flow.`

The desired primary Companion flow is now:

```
Conversation
Type a message and press Enter to send.
Message
Send message
Clear
```

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

BF adds source markers:

- `Stage 16 FC-O45-E-BF Companion minimal chat source`
- `window.apcCompanionMinimalChatWorkspace`
- `hideImmersionChrome`
- `hideExtraChatCardHeadingAndCopy`
- `companion-minimal-chat-hidden`
- `Stage 16 FC-O45-E-BF Companion minimal chat CSS`

Behavior added in source:

1. Hide the Immersion/status chrome block.
2. Hide loose `Listening` and `Debug details` text.
3. Hide the page-level `Companion` heading.
4. Hide supportive workspace text/chip chrome.
5. Hide the extra `Chat with your Companion` card heading.
6. Hide queued-endpoint explanation copy.
7. Preserve the primary chat controls.
8. Preserve Enter-to-send behavior.
9. Preserve existing queued chat endpoint, polling flow, and backend behavior.

## Next phase

Recommended next phase:

```
FC-O45-E-BG — deploy BF minimal chat source over the existing Tailscale restricted path
```

BG should use:

```
cat package.tgz | ssh apcdeploy@website-edge 'deploy sha256=<sha256> bust=<cache-bust-token>'
```

## Output

```
=== Stage 16 FC-O45-E-BF Companion minimal chat source patch ===
MUTATION_SCOPE=repo_source_docs_smoke_commit_tag_push_only
FIX=remove_remaining_companion_chrome_and_extra_chat_heading_from_visible_primary_flow
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
expected_head=12465de
head_now=12465de
origin_main_now=12465de
git_preflight=PASS

=== source marker preflight ===
14823: * Stage 16 FC-O45-E-BD Companion hard-clean visible workspace.
15041:  window.apcCompanionHardCleanWorkspace = Object.freeze({
3773:              <h2>Chat with your Companion</h2>
10704:      '<h2>Chat with your Companion</h2>',
13601:       bodyText.includes("Chat with your Companion"));
13621:          text.includes("Chat with your Companion") ||
13811:       bodyText.includes("Chat with your Companion"));
14649: * - Rename the chat card to "Chat with your Companion".
14723:    renameText("Start a Companion conversation", "Chat with your Companion");
14724:    renameText("Start a companion conversation", "Chat with your Companion");
14830: * - Chat with your Companion
14911:    return text.includes("Chat with your Companion") ||
15000:        node.textContent = "Chat with your Companion";
3774:              <p>Send a message below. New work still uses the existing queued chat endpoint and polling flow.</p>
10705:      '<p>Send a message below. New work still uses the existing queued chat endpoint and polling flow.</p>',
14728:      if (text === "Send a message below. New work still uses the existing queued chat endpoint and polling flow.") {
14871:        "Send a message below. New work still uses the existing queued chat endpoint and polling flow."
14733:        node.textContent = "Type a message and press Enter to send.";
14913:      text.includes("Type a message and press Enter to send.") ||
15004:        node.textContent = "Type a message and press Enter to send.";

=== apply BF source patch ===
=== source patch diff summary ===
diff --git a/frontend/wrapper-ui/app.js b/frontend/wrapper-ui/app.js
index aa85026..4676034 100644
--- a/frontend/wrapper-ui/app.js
+++ b/frontend/wrapper-ui/app.js
@@ -3770,8 +3770,8 @@ function renderQueuedChatPage() {
           <div class="stage5p8h-empty-state">
             <div class="stage5p8h-empty-icon">💬</div>
             <div>
-              <h2>Chat with your Companion</h2>
-              <p>Send a message below. New work still uses the existing queued chat endpoint and polling flow.</p>
+              <!-- Stage 16 FC-O45-E-BF removed extra chat heading -->
+              <!-- Stage 16 FC-O45-E-BF removed queued-endpoint explanation -->
             </div>
           </div>
 
@@ -10701,8 +10701,8 @@ async function handleResetPasswordRoute() {
     empty.innerHTML = [
       '<div class="stage5o35-empty-icon">💬</div>',
       '<div>',
-      '<h2>Chat with your Companion</h2>',
-      '<p>Send a message below. New work still uses the existing queued chat endpoint and polling flow.</p>',
+      '',
+      '',
       '</div>'
     ].join("");
 
@@ -15046,3 +15046,152 @@ if (typeof window !== "undefined") {
 
   scheduleApply();
 })();
+
+
+/*
+ * Stage 16 FC-O45-E-BF Companion minimal chat source.
+ *
+ * Corrective source patch after BE browser observation:
+ * - Remove the remaining "Listening / Debug details / Companion" chrome from the primary Companion flow.
+ * - Remove the extra "Chat with your Companion" heading from the card.
+ * - Remove queued-endpoint explanation copy from the card.
+ * - Keep only the actual chat controls and conversation area visible.
+ *
+ * Target visible primary flow:
+ * - Conversation
+ * - Type a message and press Enter to send.
+ * - Message
+ * - Send message
+ * - Clear
+ */
+(function stage16FcO45EBfCompanionMinimalChatSource() {
+  if (window.__stage16FcO45EBfCompanionMinimalChatSourceInstalled) {
+    return;
+  }
+  window.__stage16FcO45EBfCompanionMinimalChatSourceInstalled = true;
+
+  const BF_MARKER = "stage16FcO45EBfCompanionMinimalChatSource";
+
+  function safeText(node) {
+    return (node && node.textContent ? node.textContent : "").replace(/\s+/g, " ").trim();
+  }
+
+  function hideNode(node, reason) {
+    if (!node) return false;
+    const tag = String(node.tagName || "").toLowerCase();
+    if (tag === "html" || tag === "body" || tag === "main") return false;
+    node.classList.add("companion-minimal-chat-hidden");
+    node.classList.add("companion-hard-clean-hidden");
+    node.classList.add("companion-clean-hidden");
+    node.setAttribute("hidden", "");
+    node.setAttribute("aria-hidden", "true");
+    node.setAttribute("data-stage16-fc-o45-e-bf-hidden", reason);
+    return true;
+  }
+
+  function hideExactLooseText(text, reason) {
+    const root = document.querySelector("main") || document.body;
+    const wanted = String(text || "").toLowerCase();
+    Array.from(root.querySelectorAll("h1,h2,h3,h4,p,span,strong,small,div")).forEach((node) => {
+      if (node.children && node.children.length > 0) return;
+      if (safeText(node).toLowerCase() === wanted) {
+        hideNode(node, reason);
+      }
+    });
+  }
+
+  function hidePanelContaining(text, reason) {
+    const root = document.querySelector("main") || document.body;
+    const wanted = String(text || "").toLowerCase();
+    const candidates = Array.from(root.querySelectorAll("section, article, fieldset, .card, .panel, .summary-box, div"))
+      .filter((node) => {
+        const tag = String(node.tagName || "").toLowerCase();
+        if (tag === "main" || node.id === "app" || node.id === "root") return false;
+        return safeText(node).toLowerCase().includes(wanted);
+      });
+
+    candidates.sort((a, b) => {
+      return (safeText(a).length - safeText(b).length) ||
+        (a.querySelectorAll("*").length - b.querySelectorAll("*").length);
+    });
+
+    if (candidates[0]) {
+      hideNode(candidates[0], reason);
+      return true;
+    }
+    return false;
+  }
+
+  function hideImmersionChrome() {
+    const immersionHosts = [
+      document.getElementById("companionImmersionPrimaryWorkspace"),
+      document.getElementById("companionImmersionVisiblePanel")
+    ].filter(Boolean);
+
+    immersionHosts.forEach((node) => hideNode(node, "immersion-status-chrome"));
+
+    hideExactLooseText("Listening", "immersion-listening-text");
+    hideExactLooseText("Debug details", "immersion-debug-details-text");
+  }
+
+  function hideCompanionPageHeaderChrome() {
+    hideExactLooseText("Companion", "page-companion-heading");
+    hideExactLooseText("Supportive chat workspace", "supportive-chat-subtitle");
+    hideExactLooseText("Talk with your local Companion while the queue handles work safely behind the scenes.", "supportive-chat-description");
+    hideExactLooseText("Queue-aware UI", "queue-aware-chip");
+  }
+
+  function hideExtraChatCardHeadingAndCopy() {
+    hideExactLooseText("Chat with your Companion", "extra-chat-heading");
+    hideExactLooseText("Send a message below. New work still uses the existing queued chat endpoint and polling flow.", "queued-endpoint-explanation");
+    hidePanelContaining("Send a message below. New work still uses the existing queued chat endpoint and polling flow.", "queued-endpoint-explanation-panel");
+  }
+
+  function preservePrimaryChatControls() {
+    const root = document.querySelector("main") || document.body;
+    Array.from(root.querySelectorAll("h1,h2,h3,h4,p,span,strong,label,div")).forEach((node) => {
+      if (node.children && node.children.length > 0) return;
+      const text = safeText(node);
+      if (text === "Send a message to start a queued local AI chat.") {
+        node.textContent = "Type a message and press Enter to send.";
+        node.setAttribute("data-stage16-fc-o45-e-bf-renamed", "message-helper");
+      }
+    });
+
+    if (window.apcCompanionCleanChatWorkspace && typeof window.apcCompanionCleanChatWorkspace.installEnterToSend === "function") {
+      window.apcCompanionCleanChatWorkspace.installEnterToSend();
+    }
+  }
+
+  function applyMinimalChat() {
+    hideImmersionChrome();
+    hideCompanionPageHeaderChrome();
+    hideExtraChatCardHeadingAndCopy();
+    preservePrimaryChatControls();
+  }
+
+  let scheduled = false;
+  function scheduleApply() {
+    if (scheduled) return;
+    scheduled = true;
+    window.requestAnimationFrame(() => {
+      scheduled = false;
+      applyMinimalChat();
+    });
+  }
+
+  document.addEventListener("DOMContentLoaded", scheduleApply);
+  window.addEventListener("load", scheduleApply);
+  window.addEventListener("hashchange", scheduleApply);
+  window.addEventListener("popstate", scheduleApply);
+
+  const observer = new MutationObserver(scheduleApply);
+  observer.observe(document.documentElement, { childList: true, subtree: true, characterData: true });
+
+  window.apcCompanionMinimalChatWorkspace = Object.freeze({
+    marker: BF_MARKER,
+    apply: applyMinimalChat,
+  });
+
+  scheduleApply();
+})();
diff --git a/frontend/wrapper-ui/styles.css b/frontend/wrapper-ui/styles.css
index 2d6ecc5..e4dac0a 100644
--- a/frontend/wrapper-ui/styles.css
+++ b/frontend/wrapper-ui/styles.css
@@ -3095,3 +3095,16 @@ body[data-current-route="/support"] .public-feature-gate .summary-box {
   opacity: 0.86;
 }
 
+
+
+/* Stage 16 FC-O45-E-BF Companion minimal chat CSS. */
+.companion-minimal-chat-hidden,
+[data-stage16-fc-o45-e-bf-hidden],
+[hidden][data-stage16-fc-o45-e-bf-hidden] {
+  display: none !important;
+}
+
+[data-stage16-fc-o45-e-bf-renamed="message-helper"] {
+  opacity: 0.9;
+}
+

=== syntax and marker checks ===
15052: * Stage 16 FC-O45-E-BF Companion minimal chat source.
15191:  window.apcCompanionMinimalChatWorkspace = Object.freeze({
15125:  function hideImmersionChrome() {
15167:    hideImmersionChrome();
15144:  function hideExtraChatCardHeadingAndCopy() {
15169:    hideExtraChatCardHeadingAndCopy();
frontend/wrapper-ui/app.js:15083:    node.classList.add("companion-minimal-chat-hidden");
frontend/wrapper-ui/styles.css:3101:.companion-minimal-chat-hidden,
14733:        node.textContent = "Type a message and press Enter to send.";
14913:      text.includes("Type a message and press Enter to send.") ||
15004:        node.textContent = "Type a message and press Enter to send.";
15062: * - Type a message and press Enter to send.
15156:        node.textContent = "Type a message and press Enter to send.";
3100:/* Stage 16 FC-O45-E-BF Companion minimal chat CSS. */
source_patch=PASS
```
