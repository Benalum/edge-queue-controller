# Stage 16 FC-O45-E-BX — Companion Final Render Wins Source No-Runtime

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `1431fe4`
- Prior deploy tag: `controller-stage-16-fc-o45-e-bw-deploy-companion-stable-result-poller-over-restricted-static-path-2026-06-24`

## User-observed behavior

After BW, the browser showed this sequence:

```
public page
conversation with completed response
page without conversation
```

## Diagnosis

The completed conversation can render, but a later normal app route/render pass can overwrite the chat area with the empty placeholder.

The BV dedupe guard was too broad:

```
signature === lastRenderSignature && messagesEl.innerHTML.trim()
```

That could treat the non-empty blank placeholder as if the completed conversation were still rendered.

## Purpose

BX makes the final completed conversation render win over later placeholder rerenders by changing the dedupe condition. It now only skips rendering if the DOM still contains actual Companion message cards and the DOM render signature matches the current conversation signature.

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
stage16FcO45EBxCompanionFinalRenderWins
data-stage16-fc-o45-e-bx-render-signature
hasRenderedConversationRows
```

## Next phase

```
FC-O45-E-BY — deploy final-render-wins patch over the existing restricted VM200 static deploy path
```

BY requires explicit approval because it mutates public static files.

## Output

```
=== Stage 16 FC-O45-E-BX Companion final render wins source no-runtime ===
MUTATION_SCOPE=repo_frontend_source_docs_smoke_commit_tag_push_only
GOAL=prevent_blank_placeholder_from_satisfying_completed_conversation_render_dedupe
OBSERVED=public_page_then_conversation_then_page_without_conversation
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
expected_head=1431fe4
head_now=1431fe4
origin_main_now=1431fe4
git_preflight=PASS

=== source preflight ===
source_preflight=PASS

=== patch dedupe so final completed conversation wins over blank placeholder ===
BX_FINAL_RENDER_WINS_SOURCE_PATCH_APPLIED=PASS

=== source context after patch ===
15500:  let lastRenderSignature = "";
15506:  root.stage16FcO45EBxCompanionFinalRenderWins = {
15568:    lastRenderSignature = "";
15571:      messagesEl.removeAttribute("data-stage16-fc-o45-e-bx-render-signature");
15676:    const domSignature = messagesEl.getAttribute("data-stage16-fc-o45-e-bx-render-signature") || "";
15677:    const hasRenderedConversationRows = Boolean(
15680:    if (signature === lastRenderSignature && signature === domSignature && hasRenderedConversationRows) {
15685:    messagesEl.setAttribute("data-stage16-fc-o45-e-bx-render-signature", signature);

=== syntax check ===
node_syntax_check=PASS

=== git diff summary ===
 frontend/wrapper-ui/app.js | 16 +++++++++++++++-
 1 file changed, 15 insertions(+), 1 deletion(-)
diff --git a/frontend/wrapper-ui/app.js b/frontend/wrapper-ui/app.js
index aaa8727..68c2a5b 100644
--- a/frontend/wrapper-ui/app.js
+++ b/frontend/wrapper-ui/app.js
@@ -15503,6 +15503,10 @@ if (typeof window !== "undefined") {
     installed: true,
     behavior: "single-flight poll until completed/failed, then stop and keep rendered result"
   };
+  root.stage16FcO45EBxCompanionFinalRenderWins = {
+    installed: true,
+    behavior: "completed conversation render must win over later blank placeholder rerenders"
+  };
   const originalFetch = typeof root.fetch === "function" ? root.fetch.bind(root) : null;
 
   function delay(ms) {
@@ -15561,6 +15565,11 @@ if (typeof window !== "undefined") {
     setLast(storage.reply, "");
     setLast(storage.status, "");
     setLast(storage.updatedAt, "");
+    lastRenderSignature = "";
+    const messagesEl = document.getElementById("queuedChatMessages");
+    if (messagesEl) {
+      messagesEl.removeAttribute("data-stage16-fc-o45-e-bx-render-signature");
+    }
   }
 
   function findDeep(value, keys, depth) {
@@ -15664,11 +15673,16 @@ if (typeof window !== "undefined") {
     if (!rows.length) return false;
 
     const signature = JSON.stringify(rows);
-    if (signature === lastRenderSignature && messagesEl.innerHTML.trim()) {
+    const domSignature = messagesEl.getAttribute("data-stage16-fc-o45-e-bx-render-signature") || "";
+    const hasRenderedConversationRows = Boolean(
+      messagesEl.querySelector && messagesEl.querySelector(".queued-chat-message")
+    );
+    if (signature === lastRenderSignature && signature === domSignature && hasRenderedConversationRows) {
       if (view.status) setStatus(view.status === "completed" ? "Complete" : view.status);
       return true;
     }
     lastRenderSignature = signature;
+    messagesEl.setAttribute("data-stage16-fc-o45-e-bx-render-signature", signature);
 
     messagesEl.innerHTML = rows.map((msg) => `
       <article class="summary-card queued-chat-message">

BX_FINAL_RENDER_WINS_SOURCE_PATCH_RECORDED=PASS
PATCHED_FILE=frontend/wrapper-ui/app.js
NEXT_REQUIRED=BY_deploy_final_render_wins_over_restricted_static_path_after_approval
```
