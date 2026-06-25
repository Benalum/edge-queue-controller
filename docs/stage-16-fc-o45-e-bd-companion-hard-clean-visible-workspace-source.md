# Stage 16 FC-O45-E-BD — Companion Hard-Clean Visible Workspace Source

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `249beb3`
- Prior live deploy tag: `controller-stage-16-fc-o45-e-bc-deploy-companion-clean-chat-workspace-over-tailscale-restricted-path-2026-06-24`

## Purpose

BC deployed the BB clean chat patch, and user observation confirmed that some BB behavior worked:

- `Chat with your Companion` appeared.
- `Type a message and press Enter to send.` appeared.
- `fallback: qwen2.5:0.5b` appeared.

But the old panels remained visible:

- Companion auth test
- Supportive chat workspace text
- Companion status
- How this works
- Study phrases
- Companion result reader

BD corrects this by replacing the fragile first-match hide behavior with smallest matching panel/card hiding.

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

BD adds source markers:

- `Stage 16 FC-O45-E-BD Companion hard-clean visible workspace`
- `window.apcCompanionHardCleanWorkspace`
- `hideSmallestPanels`
- `companion-hard-clean-hidden`
- `Stage 16 FC-O45-E-BD Companion hard-clean visible workspace CSS`

Behavior added in source:

1. Hide the smallest matching panel/card for each old section.
2. Hide Companion auth test.
3. Hide supportive chat workspace text/chip/header chrome.
4. Hide queued endpoint explanation copy.
5. Hide Companion status.
6. Hide How this works.
7. Hide Study phrases.
8. Hide Companion result reader.
9. Reinforce `Chat with your Companion`.
10. Reinforce `Type a message and press Enter to send.`
11. Re-run BB Enter-to-send installation if available.
12. Preserve existing queued chat endpoint, polling flow, result-reader code, and backend behavior.

## Next phase

Recommended next phase:

```
FC-O45-E-BE — deploy BD hard-clean visible workspace over the existing Tailscale restricted path
```

BE should use:

```
cat package.tgz | ssh apcdeploy@website-edge 'deploy sha256=<sha256> bust=<cache-bust-token>'
```

## Output

```
=== Stage 16 FC-O45-E-BD Companion hard-clean visible workspace source patch ===
MUTATION_SCOPE=repo_source_docs_smoke_commit_tag_push_only
FIX=BC_observation_showed_BB_rename_worked_but_hide_logic_did_not_hide_old_panels
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
expected_head=249beb3
head_now=249beb3
origin_main_now=249beb3
git_preflight=PASS

=== source marker preflight ===
14644: * Stage 16 FC-O45-E-BB Companion clean chat workspace.
14812:  window.apcCompanionCleanChatWorkspace = Object.freeze({
3773:              <h2>Chat with your Companion</h2>
10704:      '<h2>Chat with your Companion</h2>',
13601:       bodyText.includes("Chat with your Companion"));
13621:          text.includes("Chat with your Companion") ||
13811:       bodyText.includes("Chat with your Companion"));
14649: * - Rename the chat card to "Chat with your Companion".
14723:    renameText("Start a Companion conversation", "Chat with your Companion");
14724:    renameText("Start a companion conversation", "Chat with your Companion");
14760:  function installEnterToSend() {
14791:    installEnterToSend();
14815:    installEnterToSend,
3058:.companion-clean-hidden {

=== apply BD source patch ===
=== source patch diff summary ===
diff --git a/frontend/wrapper-ui/app.js b/frontend/wrapper-ui/app.js
index cb1a007..aa85026 100644
--- a/frontend/wrapper-ui/app.js
+++ b/frontend/wrapper-ui/app.js
@@ -14817,3 +14817,232 @@ if (typeof window !== "undefined") {
 
   scheduleApply();
 })();
+
+
+/*
+ * Stage 16 FC-O45-E-BD Companion hard-clean visible workspace.
+ *
+ * Corrective source patch after BC browser observation:
+ * BB changed labels and Enter-to-send, but its first-match hide logic could match a broad page container
+ * before finding the actual small card/panel. BD instead hides the smallest matching panel-like block.
+ *
+ * Target visible primary flow:
+ * - Chat with your Companion
+ * - Conversation
+ * - Message
+ * - Send message
+ * - Clear
+ *
+ * Hidden from the primary flow:
+ * - Companion auth test
+ * - Supportive chat workspace text/chip/header chrome
+ * - Companion status
+ * - How this works
+ * - Study phrases
+ * - Companion result reader
+ */
+(function stage16FcO45EBdCompanionHardCleanVisibleWorkspace() {
+  if (window.__stage16FcO45EBdCompanionHardCleanVisibleWorkspaceInstalled) {
+    return;
+  }
+  window.__stage16FcO45EBdCompanionHardCleanVisibleWorkspaceInstalled = true;
+
+  const BD_MARKER = "stage16FcO45EBdCompanionHardCleanVisibleWorkspace";
+
+  const HIDE_RULES = [
+    {
+      reason: "companion-auth-test",
+      any: [
+        "Companion auth test",
+        "Checks your signed-in Companion connection without creating a queue job."
+      ]
+    },
+    {
+      reason: "supportive-chat-workspace",
+      any: [
+        "Supportive chat workspace",
+        "Talk with your local Companion while the queue handles work safely behind the scenes.",
+        "Queue-aware UI"
+      ]
+    },
+    {
+      reason: "queued-chat-explanation",
+      any: [
+        "Send a message below. New work still uses the existing queued chat endpoint and polling flow."
+      ]
+    },
+    {
+      reason: "companion-status",
+      any: [
+        "Companion status",
+        "Worker Companion queue worker Model fallback: qwen2.5:0.5b"
+      ]
+    },
+    {
+      reason: "how-this-works",
+      any: [
+        "How this works",
+        "Messages continue through /api/chat/queued. The page polls the existing job status endpoint and displays the final assistant reply without changing backend behavior."
+      ]
+    },
+    {
+      reason: "study-phrases",
+      any: [
+        "Study phrases",
+        "Use natural phrases with Companion to control Study sessions."
+      ]
+    },
+    {
+      reason: "companion-result-reader",
+      any: [
+        "Companion result reader",
+        "Read a completed Companion job result by job id.",
+        "Latest submitted Companion job id"
+      ]
+    }
+  ];
+
+  function safeText(node) {
+    return (node && node.textContent ? node.textContent : "").replace(/\s+/g, " ").trim();
+  }
+
+  function isProtectedPrimaryChat(node) {
+    const text = safeText(node);
+    return text.includes("Chat with your Companion") ||
+      text.includes("Conversation") ||
+      text.includes("Type a message and press Enter to send.") ||
+      text.includes("Send message") ||
+      text.includes("Clear");
+  }
+
+  function isTooBroad(node) {
+    if (!node) return true;
+    const tag = String(node.tagName || "").toLowerCase();
+    if (tag === "html" || tag === "body" || tag === "main") return true;
+    if (node.id === "app" || node.id === "root") return true;
+    return false;
+  }
+
+  function panelCandidates() {
+    const root = document.querySelector("main") || document.body;
+    return Array.from(root.querySelectorAll("section, article, fieldset, form, .card, .panel, .summary-box, .auth-card, .status-card, .result-card, .stage5p8h-status-card, .stage5p8h-empty-state, .stage5p8h-card, div"))
+      .filter((node) => !isTooBroad(node));
+  }
+
+  function smallestMatchingPanel(phrases) {
+    const needles = phrases.map((item) => String(item || "").toLowerCase()).filter(Boolean);
+    const matches = panelCandidates().filter((node) => {
+      const text = safeText(node).toLowerCase();
+      if (!text) return false;
+      if (isProtectedPrimaryChat(node) && !needles.some((needle) => needle.includes("supportive chat workspace") || needle.includes("companion status") || needle.includes("companion result reader"))) {
+        return false;
+      }
+      return needles.some((needle) => text.includes(needle));
+    });
+
+    matches.sort((a, b) => {
+      const aText = safeText(a);
+      const bText = safeText(b);
+      const aChildren = a.querySelectorAll("*").length;
+      const bChildren = b.querySelectorAll("*").length;
+      return (aText.length - bText.length) || (aChildren - bChildren);
+    });
+
+    return matches[0] || null;
+  }
+
+  function hideNode(node, reason) {
+    if (!node || isTooBroad(node)) return false;
+    node.classList.add("companion-hard-clean-hidden");
+    node.classList.add("companion-clean-hidden");
+    node.setAttribute("hidden", "");
+    node.setAttribute("aria-hidden", "true");
+    node.setAttribute("data-stage16-fc-o45-e-bd-hidden", reason);
+    return true;
+  }
+
+  function hideSmallestPanels() {
+    HIDE_RULES.forEach((rule) => {
+      const panel = smallestMatchingPanel(rule.any);
+      if (panel) {
+        hideNode(panel, rule.reason);
+      }
+    });
+  }
+
+  function hideLooseTextChrome() {
+    const root = document.querySelector("main") || document.body;
+    Array.from(root.querySelectorAll("h1,h2,h3,h4,p,span,strong,small,div")).forEach((node) => {
+      if (node.children && node.children.length > 0) return;
+      const text = safeText(node);
+      if (!text) return;
+      const exactHide = [
+        "Companion auth test",
+        "Supportive chat workspace",
+        "Talk with your local Companion while the queue handles work safely behind the scenes.",
+        "Queue-aware UI",
+        "How this works",
+        "Study phrases",
+        "Companion result reader"
+      ];
+      if (exactHide.includes(text)) {
+        hideNode(node, "loose-text-chrome");
+      }
+    });
+  }
+
+  function reinforceCleanTitleAndSendCopy() {
+    const root = document.querySelector("main") || document.body;
+    Array.from(root.querySelectorAll("h1,h2,h3,h4,p,span,strong,label,div")).forEach((node) => {
+      if (node.children && node.children.length > 0) return;
+      const text = safeText(node);
+      if (text === "Start a Companion conversation" || text === "Start a companion conversation") {
+        node.textContent = "Chat with your Companion";
+        node.setAttribute("data-stage16-fc-o45-e-bd-renamed", "chat-title");
+      }
+      if (text === "Send a message to start a queued local AI chat.") {
+        node.textContent = "Type a message and press Enter to send.";
+        node.setAttribute("data-stage16-fc-o45-e-bd-renamed", "message-helper");
+      }
+    });
+  }
+
+  function ensureEnterToSendStillInstalled() {
+    if (window.apcCompanionCleanChatWorkspace && typeof window.apcCompanionCleanChatWorkspace.installEnterToSend === "function") {
+      window.apcCompanionCleanChatWorkspace.installEnterToSend();
+    }
+  }
+
+  function applyHardClean() {
+    reinforceCleanTitleAndSendCopy();
+    hideSmallestPanels();
+    hideLooseTextChrome();
+    ensureEnterToSendStillInstalled();
+  }
+
+  let scheduled = false;
+  function scheduleApply() {
+    if (scheduled) return;
+    scheduled = true;
+    window.requestAnimationFrame(() => {
+      scheduled = false;
+      applyHardClean();
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
+  window.apcCompanionHardCleanWorkspace = Object.freeze({
+    marker: BD_MARKER,
+    apply: applyHardClean,
+    hideSmallestPanels,
+  });
+
+  scheduleApply();
+})();
diff --git a/frontend/wrapper-ui/styles.css b/frontend/wrapper-ui/styles.css
index d30eb78..2d6ecc5 100644
--- a/frontend/wrapper-ui/styles.css
+++ b/frontend/wrapper-ui/styles.css
@@ -3077,3 +3077,21 @@ body[data-current-route="/support"] .public-feature-gate .summary-box {
   opacity: 0.8;
 }
 
+
+
+/* Stage 16 FC-O45-E-BD Companion hard-clean visible workspace CSS. */
+.companion-hard-clean-hidden,
+[data-stage16-fc-o45-e-bd-hidden],
+[hidden][data-stage16-fc-o45-e-bd-hidden] {
+  display: none !important;
+}
+
+[data-stage16-fc-o45-e-bd-renamed="chat-title"] {
+  font-size: 1.25rem;
+  font-weight: 750;
+}
+
+[data-stage16-fc-o45-e-bd-renamed="message-helper"] {
+  opacity: 0.86;
+}
+

=== syntax and marker checks ===
14823: * Stage 16 FC-O45-E-BD Companion hard-clean visible workspace.
15041:  window.apcCompanionHardCleanWorkspace = Object.freeze({
14964:  function hideSmallestPanels() {
15018:    hideSmallestPanels();
15044:    hideSmallestPanels,
frontend/wrapper-ui/app.js:14956:    node.classList.add("companion-hard-clean-hidden");
frontend/wrapper-ui/styles.css:3083:.companion-hard-clean-hidden,
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
14733:        node.textContent = "Type a message and press Enter to send.";
14913:      text.includes("Type a message and press Enter to send.") ||
15004:        node.textContent = "Type a message and press Enter to send.";
3082:/* Stage 16 FC-O45-E-BD Companion hard-clean visible workspace CSS. */
source_patch=PASS
```
