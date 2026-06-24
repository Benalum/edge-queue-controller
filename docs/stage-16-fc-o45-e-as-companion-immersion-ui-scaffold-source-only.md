# Stage 16 FC-O45-E-AS — Companion Immersion UI Scaffold Source-Only

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `9d6a297`
- Prior tag: `controller-stage-16-fc-o45-e-ar-companion-immersion-state-ui-contract-2026-06-24`

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

Added source-only markers and helpers:

- `Companion Immersion Mode`
- `COMPANION_IMMERSION_STATES`
- `listening`
- `thinking`
- `speaking`
- `needs_attention`
- `companionImmersionStateFromJob`
- `companionImmersionExtractResultText`
- `companionImmersionDebugDetails`
- `renderCompanionImmersionPanel`
- `window.apcCompanionImmersion`
- `.companion-immersion-panel`

## Behavior contract

This scaffold does not deploy or change the live UI yet.

The helper layer supports the next visible UI implementation:

```
last user message
+ Companion state
+ last response when available
+ optional debug details
```

State mapping:

| State | Meaning |
|---|---|
| `listening` | ready for user input |
| `thinking` | queued/running/processing |
| `speaking` | completed with result |
| `needs_attention` | failed/error/unauthorized/malformed |

## Next recommended phase

Next phase should be a source-only wiring step:

```
FC-O45-E-AT — wire Companion Immersion panel into visible Companion page source only
```

AT should keep the existing queue/result-reader code and only change the main visible panel presentation in repo source. Deploy remains a separate approval gate.

## Live output

```
=== Stage 16 FC-O45-E-AS Companion Immersion UI scaffold source-only ===
MUTATION_SCOPE=repo_source_docs_smoke_commit_tag_push_only
ALLOWED: modify repo source files only
ALLOWED: add Companion Immersion Mode helper/state scaffold
ALLOWED: add non-live source CSS scaffold
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
expected_head=9d6a297
head_now=9d6a297
origin_main_now=9d6a297
git_preflight=PASS

=== source patch: Companion Immersion Mode scaffold ===
patched=frontend/wrapper-ui/app.js
patched=frontend/wrapper-ui/styles.css

=== patch markers ===
14065: * Stage 16 FC-O45-E-AS Companion Immersion Mode scaffold.
14078:const COMPANION_IMMERSION_STATES = Object.freeze({
14087:  if (normalized === COMPANION_IMMERSION_STATES.THINKING) return "Thinking";
14088:  if (normalized === COMPANION_IMMERSION_STATES.SPEAKING) return "Speaking";
14089:  if (normalized === COMPANION_IMMERSION_STATES.NEEDS_ATTENTION) return "Needs attention";
14105:    return COMPANION_IMMERSION_STATES.NEEDS_ATTENTION;
14109:    return COMPANION_IMMERSION_STATES.SPEAKING;
14119:    return COMPANION_IMMERSION_STATES.THINKING;
14122:  return COMPANION_IMMERSION_STATES.LISTENING;
14193:    states: COMPANION_IMMERSION_STATES,
14162:function renderCompanionImmersionPanel(context = {}) {
14198:    renderPanel: renderCompanionImmersionPanel,
2948:/* Stage 16 FC-O45-E-AS Companion Immersion Mode CSS scaffold. */
2949:.companion-immersion-panel {

=== git diff summary ===
diff --git a/frontend/wrapper-ui/app.js b/frontend/wrapper-ui/app.js
index 790374c..66c17ea 100644
--- a/frontend/wrapper-ui/app.js
+++ b/frontend/wrapper-ui/app.js
@@ -14059,3 +14059,143 @@ function stage8lObserveRouterShadowReadDisabled(payload) {
   window.addEventListener("popstate", schedule);
 })();
 /* APC_COMPANION_RESULT_READER_UI_FC_O45_E_AC END */
+
+
+/**
+ * Stage 16 FC-O45-E-AS Companion Immersion Mode scaffold.
+ *
+ * Source-only helper layer. This does not change backend behavior, does not run
+ * models, and does not create jobs. It gives the Companion UI a small
+ * assistant-like state vocabulary that can be wired into the visible panel:
+ *
+ * - listening
+ * - thinking
+ * - speaking
+ * - needs_attention
+ *
+ * Debug details remain available separately from the primary user experience.
+ */
+const COMPANION_IMMERSION_STATES = Object.freeze({
+  LISTENING: "listening",
+  THINKING: "thinking",
+  SPEAKING: "speaking",
+  NEEDS_ATTENTION: "needs_attention",
+});
+
+function companionImmersionLabel(state) {
+  const normalized = String(state || "").toLowerCase();
+  if (normalized === COMPANION_IMMERSION_STATES.THINKING) return "Thinking";
+  if (normalized === COMPANION_IMMERSION_STATES.SPEAKING) return "Speaking";
+  if (normalized === COMPANION_IMMERSION_STATES.NEEDS_ATTENTION) return "Needs attention";
+  return "Listening";
+}
+
+function companionImmersionStateFromJob(job, resultPayload) {
+  const status = String(job?.status || resultPayload?.status || "").toLowerCase();
+  const hasResult = Boolean(
+    resultPayload?.result ||
+    resultPayload?.response ||
+    resultPayload?.text ||
+    resultPayload?.message ||
+    resultPayload?.content ||
+    resultPayload?.result_text
+  );
+
+  if (status === "failed" || status === "error" || resultPayload?.error) {
+    return COMPANION_IMMERSION_STATES.NEEDS_ATTENTION;
+  }
+
+  if ((status === "completed" || status === "complete") && hasResult) {
+    return COMPANION_IMMERSION_STATES.SPEAKING;
+  }
+
+  if (
+    status === "queued" ||
+    status === "running" ||
+    status === "processing" ||
+    status === "pending" ||
+    status === "claimed"
+  ) {
+    return COMPANION_IMMERSION_STATES.THINKING;
+  }
+
+  return COMPANION_IMMERSION_STATES.LISTENING;
+}
+
+function companionImmersionExtractResultText(resultPayload) {
+  const candidates = [
+    resultPayload?.result,
+    resultPayload?.result_text,
+    resultPayload?.response,
+    resultPayload?.text,
+    resultPayload?.message,
+    resultPayload?.content,
+  ];
+
+  for (const value of candidates) {
+    if (typeof value === "string" && value.trim()) return value.trim();
+  }
+
+  if (resultPayload?.result && typeof resultPayload.result === "object") {
+    for (const key of ["text", "message", "response", "content", "result_text"]) {
+      const value = resultPayload.result[key];
+      if (typeof value === "string" && value.trim()) return value.trim();
+    }
+  }
+
+  return "";
+}
+
+function companionImmersionDebugDetails(context = {}) {
+  const lines = [];
+  if (context.job_id || context.jobId) lines.push(`job_id: ${context.job_id || context.jobId}`);
+  if (context.status) lines.push(`status: ${context.status}`);
+  if (context.job_type || context.jobType) lines.push(`job_type: ${context.job_type || context.jobType}`);
+  if (context.requested_model || context.requestedModel) {
+    lines.push(`requested_model: ${context.requested_model || context.requestedModel}`);
+  }
+  if (typeof context.queue_write !== "undefined") lines.push(`queue_write: ${String(context.queue_write)}`);
+  if (context.worker) lines.push(`worker: ${context.worker}`);
+  return lines;
+}
+
+function renderCompanionImmersionPanel(context = {}) {
+  const lastUserMessage = String(context.lastUserMessage || context.message || "").trim();
+  const resultText = companionImmersionExtractResultText(context.resultPayload || context);
+  const state = context.state || companionImmersionStateFromJob(context.job || context, context.resultPayload || context);
+  const label = companionImmersionLabel(state);
+  const debugLines = companionImmersionDebugDetails(context);
+
+  const userMessageMarkup = lastUserMessage
+    ? `<p class="companion-immersion-user-message"><strong>You:</strong> ${safeText(lastUserMessage)}</p>`
+    : "";
+
+  const responseMarkup = resultText
+    ? `<p class="companion-immersion-response">${safeText(resultText)}</p>`
+    : "";
+
+  const debugMarkup = debugLines.length
+    ? `<details class="companion-immersion-debug"><summary>Debug details</summary><pre>${safeText(debugLines.join("\n"))}</pre></details>`
+    : "";
+
+  return `
+    <section class="companion-immersion-panel" data-companion-immersion-state="${safeText(state)}">
+      <div class="companion-immersion-state companion-immersion-state-${safeText(state)}">${safeText(label)}</div>
+      ${userMessageMarkup}
+      ${responseMarkup}
+      ${debugMarkup}
+    </section>
+  `;
+}
+
+if (typeof window !== "undefined") {
+  window.apcCompanionImmersion = Object.freeze({
+    states: COMPANION_IMMERSION_STATES,
+    label: companionImmersionLabel,
+    stateFromJob: companionImmersionStateFromJob,
+    extractResultText: companionImmersionExtractResultText,
+    debugDetails: companionImmersionDebugDetails,
+    renderPanel: renderCompanionImmersionPanel,
+  });
+}
+
diff --git a/frontend/wrapper-ui/styles.css b/frontend/wrapper-ui/styles.css
index fa7c06d..2edffb2 100644
--- a/frontend/wrapper-ui/styles.css
+++ b/frontend/wrapper-ui/styles.css
@@ -2943,3 +2943,57 @@ body[data-current-route="/support"] .public-feature-gate .summary-box {
     grid-template-columns: 1fr;
   }
 }
+
+
+/* Stage 16 FC-O45-E-AS Companion Immersion Mode CSS scaffold. */
+.companion-immersion-panel {
+  border: 1px solid rgba(148, 163, 184, 0.35);
+  border-radius: 18px;
+  padding: 1rem;
+  margin: 1rem 0;
+  background: rgba(15, 23, 42, 0.04);
+}
+
+.companion-immersion-state {
+  display: inline-flex;
+  align-items: center;
+  gap: 0.4rem;
+  font-weight: 700;
+  letter-spacing: 0.02em;
+  margin-bottom: 0.75rem;
+}
+
+.companion-immersion-state-listening::before {
+  content: "●";
+}
+
+.companion-immersion-state-thinking::before {
+  content: "…";
+}
+
+.companion-immersion-state-speaking::before {
+  content: "▶";
+}
+
+.companion-immersion-state-needs_attention::before {
+  content: "!";
+}
+
+.companion-immersion-user-message,
+.companion-immersion-response {
+  margin: 0.45rem 0;
+  line-height: 1.5;
+}
+
+.companion-immersion-debug {
+  margin-top: 0.75rem;
+  font-size: 0.875rem;
+  opacity: 0.85;
+}
+
+.companion-immersion-debug pre {
+  white-space: pre-wrap;
+  overflow-wrap: anywhere;
+  margin: 0.5rem 0 0;
+}
+
```
