# Stage 16 FC-O45-E-BH — Companion Dedupe Minimal Visible Source

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `c076d1e`
- Prior live deploy tag: `controller-stage-16-fc-o45-e-bg-deploy-companion-minimal-chat-over-tailscale-restricted-path-2026-06-24`

## Purpose

After BG, user observation showed the UI was mostly reduced but still had two problems:

1. Remaining chrome:
   - `Thinking`
   - `Debug details`
   - decorative `💬`
   - `Study phrases`
2. Duplicate visible user message rows:
   - repeated `You Say hello in 1 sentence to me.`

BH is a source-only corrective patch to hide remaining chrome and deduplicate repeated visible message rows.

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

BH adds markers:

- `Stage 16 FC-O45-E-BH Companion dedupe minimal visible source`
- `window.apcCompanionDedupeMinimalVisible`
- `dedupeVisibleMessages`
- `hideRemainingChrome`
- `companion-dedupe-minimal-hidden`
- `Stage 16 FC-O45-E-BH Companion dedupe minimal visible CSS`

Behavior added:

1. Hide remaining `Thinking`, `Listening`, `Speaking`, and `Debug details` loose chrome.
2. Hide decorative `💬` icon.
3. Hide Study phrases panel and related lines.
4. Deduplicate repeated visible `You ...` and `Assistant ...` rows.
5. Use bounded cleanup passes instead of another continuous MutationObserver loop.
6. Preserve Enter-to-send behavior.
7. Preserve queued chat endpoint, polling flow, and backend behavior.

## Next phase

Recommended next phase:

```
FC-O45-E-BI — deploy BH dedupe minimal visible patch over the existing Tailscale restricted path
```

BI should use:

```
cat package.tgz | ssh apcdeploy@website-edge 'deploy sha256=<sha256> bust=<cache-bust-token>'
```

## Output

```
=== Stage 16 FC-O45-E-BH Companion dedupe minimal visible source patch ===
MUTATION_SCOPE=repo_source_docs_smoke_commit_tag_push_only
FIX=dedupe_repeated_visible_user_messages_and_hide_remaining_thinking_debug_study_chrome
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
expected_head=c076d1e
head_now=c076d1e
origin_main_now=c076d1e
git_preflight=PASS

=== source marker preflight ===
15052: * Stage 16 FC-O45-E-BF Companion minimal chat source.
15191:  window.apcCompanionMinimalChatWorkspace = Object.freeze({
14733:        node.textContent = "Type a message and press Enter to send.";
14913:      text.includes("Type a message and press Enter to send.") ||
15004:        node.textContent = "Type a message and press Enter to send.";
15062: * - Type a message and press Enter to send.
15156:        node.textContent = "Type a message and press Enter to send.";

=== apply BH source patch ===
=== source patch diff summary ===
diff --git a/frontend/wrapper-ui/app.js b/frontend/wrapper-ui/app.js
index 4676034..8a882ce 100644
--- a/frontend/wrapper-ui/app.js
+++ b/frontend/wrapper-ui/app.js
@@ -3768,7 +3768,7 @@ function renderQueuedChatPage() {
       <div class="stage5p8h-companion-grid">
         <section class="stage5p8h-conversation-card" aria-label="Companion conversation">
           <div class="stage5p8h-empty-state">
-            <div class="stage5p8h-empty-icon">💬</div>
+            <!-- Stage 16 FC-O45-E-BH removed companion empty icon -->
             <div>
               <!-- Stage 16 FC-O45-E-BF removed extra chat heading -->
               <!-- Stage 16 FC-O45-E-BF removed queued-endpoint explanation -->
@@ -10699,7 +10699,7 @@ async function handleResetPasswordRoute() {
     const empty = document.createElement("div");
     empty.className = "stage5o35-empty-state";
     empty.innerHTML = [
-      '<div class="stage5o35-empty-icon">💬</div>',
+      '',
       '<div>',
       '',
       '',
@@ -15195,3 +15195,201 @@ if (typeof window !== "undefined") {
 
   scheduleApply();
 })();
+
+
+/*
+ * Stage 16 FC-O45-E-BH Companion dedupe minimal visible source.
+ *
+ * Corrective source patch after BG browser observation:
+ * - Hide remaining Thinking / Debug details / Immersion chrome.
+ * - Hide remaining Study phrases helper block.
+ * - Hide the decorative chat icon.
+ * - Deduplicate repeated visible "You ..." and "Assistant ..." message rows.
+ * - Avoid another continuous MutationObserver loop; use a bounded cleanup pass.
+ *
+ * Target visible primary flow:
+ * - Conversation
+ * - Type a message and press Enter to send.
+ * - Message
+ * - Send message
+ * - Clear
+ */
+(function stage16FcO45EBhCompanionDedupeMinimalVisibleSource() {
+  if (window.__stage16FcO45EBhCompanionDedupeMinimalVisibleSourceInstalled) {
+    return;
+  }
+  window.__stage16FcO45EBhCompanionDedupeMinimalVisibleSourceInstalled = true;
+
+  const BH_MARKER = "stage16FcO45EBhCompanionDedupeMinimalVisibleSource";
+
+  function safeText(node) {
+    return (node && node.textContent ? node.textContent : "").replace(/\s+/g, " ").trim();
+  }
+
+  function hideNode(node, reason) {
+    if (!node) return false;
+    const tag = String(node.tagName || "").toLowerCase();
+    if (tag === "html" || tag === "body" || tag === "main") return false;
+    node.classList.add("companion-dedupe-minimal-hidden");
+    node.classList.add("companion-minimal-chat-hidden");
+    node.classList.add("companion-hard-clean-hidden");
+    node.classList.add("companion-clean-hidden");
+    node.setAttribute("hidden", "");
+    node.setAttribute("aria-hidden", "true");
+    node.setAttribute("data-stage16-fc-o45-e-bh-hidden", reason);
+    return true;
+  }
+
+  function isHidden(node) {
+    return !node || node.hidden || node.getAttribute("aria-hidden") === "true" ||
+      node.classList.contains("companion-dedupe-minimal-hidden") ||
+      node.classList.contains("companion-minimal-chat-hidden") ||
+      node.classList.contains("companion-hard-clean-hidden") ||
+      node.classList.contains("companion-clean-hidden");
+  }
+
+  function leafishElements(root) {
+    return Array.from(root.querySelectorAll("h1,h2,h3,h4,p,span,strong,small,li,div"))
+      .filter((node) => !isHidden(node))
+      .filter((node) => node.querySelectorAll("h1,h2,h3,h4,p,span,strong,small,li,button,input,textarea").length <= 2);
+  }
+
+  function hideExactLooseText(root, text, reason) {
+    const wanted = String(text || "").toLowerCase();
+    leafishElements(root).forEach((node) => {
+      if (safeText(node).toLowerCase() === wanted) {
+        hideNode(node, reason);
+      }
+    });
+  }
+
+  function smallestPanelContaining(root, text) {
+    const wanted = String(text || "").toLowerCase();
+    const candidates = Array.from(root.querySelectorAll("section, article, fieldset, .card, .panel, .summary-box, div"))
+      .filter((node) => {
+        if (isHidden(node)) return false;
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
+    return candidates[0] || null;
+  }
+
+  function hideRemainingChrome(root) {
+    [
+      "Thinking",
+      "Listening",
+      "Speaking",
+      "Debug details",
+      "Companion",
+      "Study phrases",
+      "Use natural phrases with Companion to control Study sessions.",
+      "Start: “Study session start” or “Start a study session.”",
+      "Pause: “Study session pause.”",
+      "Resume: “Study session resume.”",
+      "Stop: “Study session stop.”",
+      "Answer: “Read the answer.”",
+      "Mark: “Correct,” “wrong,” or “skip.”",
+      "💬"
+    ].forEach((text) => hideExactLooseText(root, text, "remaining-chrome"));
+
+    [
+      "Use natural phrases with Companion to control Study sessions.",
+      "Start: “Study session start” or “Start a study session.”",
+      "Study phrases"
+    ].forEach((text) => {
+      const panel = smallestPanelContaining(root, text);
+      if (panel) hideNode(panel, "study-phrases-panel");
+    });
+
+    [
+      document.getElementById("companionImmersionPrimaryWorkspace"),
+      document.getElementById("companionImmersionVisiblePanel")
+    ].filter(Boolean).forEach((node) => hideNode(node, "immersion-chrome-panel"));
+  }
+
+  function normalizeMessageText(text) {
+    return String(text || "")
+      .replace(/\s+/g, " ")
+      .replace(/^You\s*:\s*/i, "You ")
+      .replace(/^Assistant\s*:\s*/i, "Assistant ")
+      .trim();
+  }
+
+  function messageKeyFor(text) {
+    const normalized = normalizeMessageText(text);
+    if (/^You\s+\S.+/i.test(normalized)) {
+      return normalized.replace(/^You\s+/i, "you:");
+    }
+    if (/^Assistant\s+\S.+/i.test(normalized)) {
+      return normalized.replace(/^Assistant\s+/i, "assistant:");
+    }
+    return "";
+  }
+
+  function dedupeVisibleMessages(root) {
+    const seen = new Set();
+    const candidates = leafishElements(root)
+      .filter((node) => {
+        const text = normalizeMessageText(safeText(node));
+        if (text.length < 6 || text.length > 420) return false;
+        return /^You\s+\S.+/i.test(text) || /^Assistant\s+\S.+/i.test(text);
+      });
+
+    candidates.forEach((node) => {
+      const key = messageKeyFor(safeText(node));
+      if (!key) return;
+      if (seen.has(key)) {
+        hideNode(node, "duplicate-visible-message");
+      } else {
+        seen.add(key);
+        node.setAttribute("data-stage16-fc-o45-e-bh-message-kept", "true");
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
+  function applyDedupeMinimalVisible() {
+    const root = document.querySelector("main") || document.body;
+    hideRemainingChrome(root);
+    dedupeVisibleMessages(root);
+    ensureEnterToSendStillInstalled();
+  }
+
+  function runBoundedCleanup() {
+    let remaining = 12;
+    function tick() {
+      applyDedupeMinimalVisible();
+      remaining -= 1;
+      if (remaining > 0) {
+        window.setTimeout(tick, 250);
+      }
+    }
+    tick();
+  }
+
+  document.addEventListener("DOMContentLoaded", runBoundedCleanup);
+  window.addEventListener("load", runBoundedCleanup);
+  window.addEventListener("hashchange", runBoundedCleanup);
+  window.addEventListener("popstate", runBoundedCleanup);
+
+  window.apcCompanionDedupeMinimalVisible = Object.freeze({
+    marker: BH_MARKER,
+    apply: applyDedupeMinimalVisible,
+    dedupeVisibleMessages,
+    hideRemainingChrome,
+  });
+
+  runBoundedCleanup();
+})();
diff --git a/frontend/wrapper-ui/styles.css b/frontend/wrapper-ui/styles.css
index e4dac0a..656dc2c 100644
--- a/frontend/wrapper-ui/styles.css
+++ b/frontend/wrapper-ui/styles.css
@@ -3108,3 +3108,16 @@ body[data-current-route="/support"] .public-feature-gate .summary-box {
   opacity: 0.9;
 }
 
+
+
+/* Stage 16 FC-O45-E-BH Companion dedupe minimal visible CSS. */
+.companion-dedupe-minimal-hidden,
+[data-stage16-fc-o45-e-bh-hidden],
+[hidden][data-stage16-fc-o45-e-bh-hidden] {
+  display: none !important;
+}
+
+[data-stage16-fc-o45-e-bh-message-kept="true"] {
+  display: block;
+}
+

=== syntax and marker checks ===
15201: * Stage 16 FC-O45-E-BH Companion dedupe minimal visible source.
15387:  window.apcCompanionDedupeMinimalVisible = Object.freeze({
15336:  function dedupeVisibleMessages(root) {
15366:    dedupeVisibleMessages(root);
15390:    dedupeVisibleMessages,
15284:  function hideRemainingChrome(root) {
15365:    hideRemainingChrome(root);
15391:    hideRemainingChrome,
frontend/wrapper-ui/app.js:15233:    node.classList.add("companion-dedupe-minimal-hidden");
frontend/wrapper-ui/app.js:15245:      node.classList.contains("companion-dedupe-minimal-hidden") ||
frontend/wrapper-ui/styles.css:3114:.companion-dedupe-minimal-hidden,
3113:/* Stage 16 FC-O45-E-BH Companion dedupe minimal visible CSS. */
source_patch=PASS
```
