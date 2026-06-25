# Stage 16 FC-O45-E-AZ — Companion Immersion Primary Workspace Source

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `9418e4a`
- Prior live deploy tag: `controller-stage-16-fc-o45-e-ay-deploy-companion-immersion-ui-over-tailscale-restricted-path-2026-06-24`

## Purpose

After AY, the Companion Immersion panel was visible in production, but user observation showed it appeared above the main Companion workspace while the older queue/debug-like Conversation section still dominated the page.

AZ is a source-only UI refinement to make Immersion feel like the primary Companion experience.

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

AZ adds source markers:

- `Stage 16 FC-O45-E-AZ Companion Immersion primary workspace placement`
- `window.apcCompanionImmersionPrimaryWorkspace`
- `companionImmersionPrimaryWorkspace`
- `Stage 16 FC-O45-E-AZ Companion Immersion primary workspace CSS`
- `#companionImmersionPrimaryWorkspace`

Behavior added in source:

1. Move the visible Immersion panel into the main Companion workspace.
2. Place Immersion near the Conversation area instead of above the Companion page.
3. Keep existing queue/message/result-reader behavior intact.
4. Collapse Immersion debug details by default.
5. De-emphasize legacy debug-like sections such as Companion status, How this works, and Study phrases.
6. Replace the stale rendered model label `fallback: gemma4:e4b` with `fallback: qwen2.5:0.5b` when that literal appears.

## Next phase

Recommended next phase:

```
FC-O45-E-BA — deploy AZ source patch over the existing Tailscale restricted path
```

BA should use the already-proven restricted deploy command:

```
cat package.tgz | ssh apcdeploy@website-edge 'deploy sha256=<sha256> bust=<cache-bust-token>'
```

## Output

```
=== Stage 16 FC-O45-E-AZ Companion Immersion primary workspace source patch ===
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
expected_head=9418e4a
head_now=9418e4a
origin_main_now=9418e4a
git_preflight=PASS

=== source marker preflight ===
13991:    title.textContent = "Companion result reader";
14065: * Stage 16 FC-O45-E-AS Companion Immersion Mode scaffold.
14204: * Stage 16 FC-O45-E-AT Companion Immersion visible panel source wiring.
14470:  window.apcCompanionImmersionRuntime = Object.freeze({
14422:    window.fetch = async function apcCompanionImmersionObservedFetch(input, init = {}) {
3001:/* Stage 16 FC-O45-E-AT Companion Immersion visible panel CSS wiring. */
3002:#companionImmersionVisiblePanel {
3006:#companionImmersionVisiblePanel .companion-immersion-panel {
3010:#companionImmersionVisiblePanel .companion-immersion-state {
3015:#companionImmersionVisiblePanel .companion-immersion-response {
3019:#companionImmersionVisiblePanel .companion-immersion-debug summary {

=== apply AZ source patch ===
=== source patch diff summary ===
diff --git a/frontend/wrapper-ui/app.js b/frontend/wrapper-ui/app.js
index e702bd8..8e41f89 100644
--- a/frontend/wrapper-ui/app.js
+++ b/frontend/wrapper-ui/app.js
@@ -3810,7 +3810,7 @@ function renderQueuedChatPage() {
             </div>
             <div class="stage5p8h-status-row">
               <span>Model</span>
-              <strong>fallback: gemma4:e4b</strong>
+              <strong>fallback: qwen2.5:0.5b</strong>
             </div>
           </section>
 
@@ -14475,3 +14475,166 @@ if (typeof window !== "undefined") {
   companionImmersionScheduleRender();
 })();
 
+
+
+/*
+ * Stage 16 FC-O45-E-AZ Companion Immersion primary workspace placement.
+ *
+ * Source-only UI refinement:
+ * - Move the visible Immersion panel into the main Companion workspace instead of leaving it above the page.
+ * - Keep the existing queue/message flow intact.
+ * - Collapse debug-like details by default.
+ * - Preserve result-reader and queued chat behavior.
+ * - Keep the model label aligned with the proven qwen2.5:0.5b queue-worker path when the old fallback text is rendered.
+ */
+(function stage16FcO45EAzCompanionImmersionPrimaryWorkspace() {
+  if (window.__stage16FcO45EAzCompanionImmersionPrimaryWorkspaceInstalled) {
+    return;
+  }
+  window.__stage16FcO45EAzCompanionImmersionPrimaryWorkspaceInstalled = true;
+
+  const AZ_MARKER = "stage16FcO45EAzCompanionImmersionPrimaryWorkspace";
+
+  function safeText(node) {
+    return (node && node.textContent ? node.textContent : "").replace(/\s+/g, " ").trim();
+  }
+
+  function findHeadingByText(root, text) {
+    const expected = String(text || "").toLowerCase();
+    return Array.from(root.querySelectorAll("h1,h2,h3,h4,h5,h6,strong,legend"))
+      .find((node) => safeText(node).toLowerCase() === expected) || null;
+  }
+
+  function candidateContainerFor(node) {
+    if (!node) return null;
+    return node.closest("section, article, main, .card, .panel, .view, .page, .workspace, div") || null;
+  }
+
+  function findCompanionWorkspace() {
+    const root = document.querySelector("main") || document.body;
+    const headings = Array.from(root.querySelectorAll("h1,h2,h3,h4"));
+    const companionHeading = headings.find((heading) => {
+      const text = safeText(heading).toLowerCase();
+      if (text !== "companion") return false;
+      const container = candidateContainerFor(heading);
+      return container && /supportive chat workspace|talk with your local companion|start a companion conversation/i.test(safeText(container));
+    });
+    if (companionHeading) {
+      const section = companionHeading.closest("section, article, .card, .panel, .view, .page, main, div");
+      if (section) return section;
+    }
+    return root;
+  }
+
+  function findConversationAnchor(workspace) {
+    const conversationHeading = findHeadingByText(workspace, "Conversation");
+    if (conversationHeading) {
+      return candidateContainerFor(conversationHeading) || conversationHeading;
+    }
+
+    const startHeading = Array.from(workspace.querySelectorAll("h1,h2,h3,h4,h5,h6,strong"))
+      .find((node) => /start a companion conversation/i.test(safeText(node)));
+    if (startHeading) {
+      return candidateContainerFor(startHeading) || startHeading;
+    }
+
+    return workspace.firstElementChild || workspace;
+  }
+
+  function moveImmersionPanelIntoWorkspace() {
+    const panelHost = document.getElementById("companionImmersionVisiblePanel");
+    if (!panelHost) return false;
+
+    const workspace = findCompanionWorkspace();
+    if (!workspace || panelHost.closest("#companionImmersionPrimaryWorkspace")) {
+      return false;
+    }
+
+    let primaryHost = document.getElementById("companionImmersionPrimaryWorkspace");
+    if (!primaryHost) {
+      primaryHost = document.createElement("section");
+      primaryHost.id = "companionImmersionPrimaryWorkspace";
+      primaryHost.className = "companion-immersion-primary-workspace";
+      primaryHost.setAttribute("data-stage16-fc-o45-e-az", AZ_MARKER);
+      primaryHost.setAttribute("aria-label", "Companion Immersion");
+    }
+
+    if (panelHost.parentElement !== primaryHost) {
+      primaryHost.appendChild(panelHost);
+    }
+
+    const anchor = findConversationAnchor(workspace);
+    if (anchor && primaryHost.parentElement !== workspace) {
+      workspace.insertBefore(primaryHost, anchor);
+    } else if (!primaryHost.parentElement) {
+      workspace.insertBefore(primaryHost, workspace.firstChild);
+    }
+
+    return true;
+  }
+
+  function collapseImmersionDebugByDefault() {
+    const details = document.querySelectorAll(
+      "#companionImmersionPrimaryWorkspace details, #companionImmersionVisiblePanel details, .companion-immersion-debug"
+    );
+    details.forEach((node) => {
+      if (node.tagName && node.tagName.toLowerCase() === "details") {
+        node.open = false;
+      }
+    });
+  }
+
+  function softenLegacyConversationDebug() {
+    const workspace = findCompanionWorkspace();
+
+    Array.from(workspace.querySelectorAll("*")).forEach((node) => {
+      if (node.children && node.children.length > 3) return;
+      const text = safeText(node);
+      if (text === "Companion status" || text === "How this works" || text === "Study phrases") {
+        const block = candidateContainerFor(node);
+        if (block && block !== workspace && !block.closest("#companionImmersionPrimaryWorkspace")) {
+          block.classList.add("companion-legacy-debug-secondary");
+        }
+      }
+    });
+
+    Array.from(workspace.querySelectorAll("*")).forEach((node) => {
+      if (node.childNodes.length !== 1 || node.children.length) return;
+      if (safeText(node) === "fallback: gemma4:e4b") {
+        node.textContent = "fallback: qwen2.5:0.5b";
+        node.setAttribute("data-stage16-fc-o45-e-az-model-label", "qwen2.5:0.5b");
+      }
+    });
+  }
+
+  function applyCompanionImmersionPrimaryWorkspace() {
+    moveImmersionPanelIntoWorkspace();
+    collapseImmersionDebugByDefault();
+    softenLegacyConversationDebug();
+  }
+
+  let scheduled = false;
+  function scheduleApply() {
+    if (scheduled) return;
+    scheduled = true;
+    window.requestAnimationFrame(() => {
+      scheduled = false;
+      applyCompanionImmersionPrimaryWorkspace();
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
+  window.apcCompanionImmersionPrimaryWorkspace = Object.freeze({
+    marker: AZ_MARKER,
+    apply: applyCompanionImmersionPrimaryWorkspace,
+  });
+
+  scheduleApply();
+})();
diff --git a/frontend/wrapper-ui/styles.css b/frontend/wrapper-ui/styles.css
index 3af078c..6404dc8 100644
--- a/frontend/wrapper-ui/styles.css
+++ b/frontend/wrapper-ui/styles.css
@@ -3020,3 +3020,35 @@ body[data-current-route="/support"] .public-feature-gate .summary-box {
   cursor: pointer;
 }
 
+
+
+/* Stage 16 FC-O45-E-AZ Companion Immersion primary workspace CSS. */
+#companionImmersionPrimaryWorkspace {
+  margin: 1rem 0;
+}
+
+#companionImmersionPrimaryWorkspace #companionImmersionVisiblePanel {
+  margin: 0;
+}
+
+#companionImmersionPrimaryWorkspace .companion-immersion-panel {
+  border-width: 1px;
+}
+
+#companionImmersionPrimaryWorkspace .companion-immersion-state {
+  font-size: 1.05rem;
+}
+
+#companionImmersionPrimaryWorkspace .companion-immersion-debug:not([open]) pre {
+  display: none;
+}
+
+.companion-legacy-debug-secondary {
+  opacity: 0.78;
+}
+
+.companion-legacy-debug-secondary pre,
+.companion-legacy-debug-secondary code {
+  font-size: 0.85em;
+}
+

=== syntax and marker checks ===
14481: * Stage 16 FC-O45-E-AZ Companion Immersion primary workspace placement.
14634:  window.apcCompanionImmersionPrimaryWorkspace = Object.freeze({
14549:    if (!workspace || panelHost.closest("#companionImmersionPrimaryWorkspace")) {
14553:    let primaryHost = document.getElementById("companionImmersionPrimaryWorkspace");
14556:      primaryHost.id = "companionImmersionPrimaryWorkspace";
14578:      "#companionImmersionPrimaryWorkspace details, #companionImmersionVisiblePanel details, .companion-immersion-debug"
14595:        if (block && block !== workspace && !block.closest("#companionImmersionPrimaryWorkspace")) {
3813:              <strong>fallback: qwen2.5:0.5b</strong>
14604:        node.textContent = "fallback: qwen2.5:0.5b";
3025:/* Stage 16 FC-O45-E-AZ Companion Immersion primary workspace CSS. */
3026:#companionImmersionPrimaryWorkspace {
3030:#companionImmersionPrimaryWorkspace #companionImmersionVisiblePanel {
3034:#companionImmersionPrimaryWorkspace .companion-immersion-panel {
3038:#companionImmersionPrimaryWorkspace .companion-immersion-state {
3042:#companionImmersionPrimaryWorkspace .companion-immersion-debug:not([open]) pre {
source_patch=PASS
```
