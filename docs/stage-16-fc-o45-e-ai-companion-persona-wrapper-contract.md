# Stage 16 FC-O45-E-AI — Companion Persona Wrapper Contract

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `b779e4c`
- Prior tag: `controller-stage-16-fc-o45-e-ah-job127-result-reader-quality-contract-2026-06-24`
- Runtime proof carried forward: job `127`

## Scope

This phase is repo/docs/smoke only.

Allowed:

- Fix the AH smoke shell quoting defect that printed `127: command not found`.
- Record the no-runtime Companion persona/prompt wrapper contract.
- Commit, tag, and push the documentation/smoke checkpoint.

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
- NO service restart/reload/start/stop/enable/disable.
- NO CT/VM restart.
- NO nginx/cloudflared/storage mutation.
- NO file deletion.

## Problem statement

AG-R3 proved the exact-one real-model runtime path:

- target job: `127`
- `user_id=16`
- `job_type=companion.chat`
- `requested_model=qwen2.5:0.5b`
- `attempts=1`
- `result_rows=1`

The model output was:

```
I am Qwen, a powerful AI platform control companion created by Alibaba Cloud.
```

This proves the runtime chain, but not product-quality Companion behavior.

Quality flags from AH:

- `model_identity_leakage_qwen`
- `vendor_identity_leakage_alibaba`
- `did_not_follow_companion_product_prompt`

## Companion persona wrapper contract

The next productization repair should normalize the Companion prompt layer before more user-facing runtime proof.

The wrapper should instruct the model:

```
You are the AI Platform Control Companion for Alex's platform.
Answer as the product assistant, not as the base model.
Do not identify yourself as Qwen, Alibaba, Ollama, or any vendor/model.
Do not mention internal infrastructure unless the user asks.
Keep the response concise, friendly, and directly useful.
For proof prompts, acknowledge the proof in natural user-facing language.
If asked unsafe or impossible requests, refuse briefly and safely.
```

## Output acceptance criteria

A product-quality Companion proof response should:

- avoid vendor/model identity,
- avoid “I am Qwen,” “Alibaba,” or equivalent base-model branding,
- refer to itself only as the Companion or assistant,
- answer the user’s message directly,
- stay short for simple messages,
- keep safe refusal behavior intact,
- preserve owner-scoped result reading through the existing result-reader path.

## Next runtime proof contract

Next phase should be `FC-O45-E-AJ` and must require explicit approval before runtime.

Suggested approval phrase:

```
APPROVE_FC_O45_E_AJ_EXACT_ONE_COMPANION_PERSONA_MODEL_JOB
```

Allowed only after approval:

- create exactly one new `companion.chat` job owned by `user_id=16`,
- use already-installed `qwen2.5:0.5b`,
- run one bounded foreground model generation using the persona wrapper,
- insert exactly one result row for only that target job,
- verify DB integrity, final job state, and result quality flags,
- verify the result-reader can read that job.

Still forbidden unless separately approved:

- scheduler activation,
- timer activation,
- persistent worker activation,
- broad queue draining,
- old job mutation,
- backend/frontend deploy,
- service restart/reload/enable/disable,
- CT/VM restart,
- model pull/download,
- nginx/cloudflared/storage mutation,
- deletion.

## Live read-only/source output

```
=== Stage 16 FC-O45-E-AI Companion persona wrapper contract ===
MUTATION_SCOPE=repo_docs_smoke_only
ALLOWED: fix AH smoke shell quoting defect
ALLOWED: add no-runtime Companion persona/prompt wrapper contract
NO DB write
NO job mutation
NO result insert
NO model/helper/Ollama call
NO model generation
NO scheduler activation
NO timer activation
NO persistent worker activation
NO backend/frontend deploy
NO service restart/reload/start/stop/enable/disable
NO CT/VM restart
NO nginx/cloudflared/storage mutation
NO file deletion

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=b779e4c
head_now=b779e4c
origin_main_now=b779e4c
git_preflight=PASS

=== source prompt/persona inventory, read-only ===
frontend/study-ui/app.js:597:   Companion study mode
frontend/study-ui/app.js:622:function syncCompanionDeckSelect() {
frontend/study-ui/app.js:643:const originalLoadDecksForCompanion = loadDecks;
frontend/study-ui/app.js:644:loadDecks = async function patchedLoadDecksForCompanion() {
frontend/study-ui/app.js:645:  await originalLoadDecksForCompanion();
frontend/study-ui/app.js:646:  syncCompanionDeckSelect();
frontend/study-ui/app.js:788:      notes: "Companion user-confirmed review."
frontend/study-ui/app.js:832:/* === Companion + local calendar patch === */
frontend/study-ui/app.js:834:  const CHAT_KEY = "aiStudyCompanionChat:v1";
frontend/study-ui/app.js:1055:        addCompanionMessage("system", "The companion is still thinking. I am waiting for the queued response instead of showing a gateway error.");
frontend/study-ui/app.js:1064:  function buildCompanionPrompt(message) {
frontend/study-ui/app.js:1099:  async function sendCompanionToApi(message) {
frontend/study-ui/app.js:1101:    const prompt = buildCompanionPrompt(message);
frontend/study-ui/app.js:1107:        body: { message: prompt, requested_model: "gemma4:e4b" },
frontend/study-ui/app.js:1115:        body: { job_type: "ollama_chat", prompt, requested_model: "gemma4:e4b" },
frontend/study-ui/app.js:1145:            addCompanionMessage("system", `Queued with Gemma E4B as job ${jobId}. Waiting for the worker...`);
frontend/study-ui/app.js:1164:  function getCompanionMessages() {
frontend/study-ui/app.js:1173:  function setCompanionMessages(messages) {
frontend/study-ui/app.js:1177:  function renderCompanionMessages() {
frontend/study-ui/app.js:1181:    const messages = getCompanionMessages();
frontend/study-ui/app.js:1189:  function addCompanionMessage(role, text) {
frontend/study-ui/app.js:1190:    const messages = getCompanionMessages();
frontend/study-ui/app.js:1192:    setCompanionMessages(messages);
frontend/study-ui/app.js:1193:    renderCompanionMessages();
frontend/study-ui/app.js:1196:  async function handleCompanionSubmit(message) {
frontend/study-ui/app.js:1205:    addCompanionMessage("user", clean);
frontend/study-ui/app.js:1211:      const answer = await sendCompanionToApi(clean);
frontend/study-ui/app.js:1212:      addCompanionMessage("assistant", answer || "I got a response, but it did not include readable text.");
frontend/study-ui/app.js:1220:      addCompanionMessage(
frontend/study-ui/app.js:1224:      if (status) status.textContent = err.transient ? "Companion is still pending after a gateway timeout." : "Companion API route failed.";
frontend/study-ui/app.js:1230:  function setupCompanion() {
frontend/study-ui/app.js:1231:    renderCompanionMessages();
frontend/study-ui/app.js:1241:        handleCompanionSubmit();
frontend/study-ui/app.js:1249:        renderCompanionMessages();
frontend/study-ui/app.js:1256:        handleCompanionSubmit("What should I study right now based on my cards?");
frontend/study-ui/app.js:1346:        setupCompanion();
frontend/study-ui/app.js:1353:    setupCompanion();
frontend/study-ui/styles.css:510:   Companion page
frontend/study-ui/styles.css:588:/* === Companion + local calendar patch === */
frontend/study-ui/study-content.partial.html:25:            <h2>Your personal AI learning platform</h2>
frontend/study-ui/study-content.partial.html:37:            <button class="secondary" type="button" data-page-link="companion">Open Companion</button>
frontend/study-ui/study-content.partial.html:51:            <p>Study cards are active. Companion now uses the worker proxy and Gemma E4B queue path when available.</p>
frontend/study-ui/study-content.partial.html:55:            <p>Use the Companion tab and ask: “What should I study right now based on my cards?”</p>
frontend/study-ui/study-content.partial.html:63:            <p class="eyebrow">Companion</p>
frontend/study-ui/study-content.partial.html:64:            <h2>AI Companion</h2>
frontend/study-ui/study-content.partial.html:71:        <a class="primary" href="https://alexhartel.com/companion">Open Full Companion</a>
frontend/study-ui/study-content.partial.html:97:          Companion, Calendar, and Profile can use the same account.
frontend/study-ui/index.html:25:        <a class="app-shell-link nav-link" href="https://alexhartel.com/companion">Companion</a>
frontend/study-ui/index.html:55:            <h2>Your personal AI learning platform</h2>
frontend/study-ui/index.html:67:            <button class="secondary" type="button" data-page-link="companion">Open Companion</button>
frontend/study-ui/index.html:81:            <p>Study cards are active. Companion now uses the worker proxy and Gemma E4B queue path when available.</p>
frontend/study-ui/index.html:85:            <p>Use the Companion tab and ask: “What should I study right now based on my cards?”</p>
frontend/study-ui/index.html:93:            <p class="eyebrow">Companion</p>
frontend/study-ui/index.html:94:            <h2>AI Companion</h2>
frontend/study-ui/index.html:101:        <a class="primary" href="https://alexhartel.com/companion">Open Full Companion</a>
frontend/study-ui/index.html:127:          Companion, Calendar, and Profile can use the same account.
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:14:      <span class="brand-mark helper-logo" title="Study Companion Helper">
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:15:        <svg viewBox="0 0 64 64" role="img" aria-label="Study Companion Helper logo">
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:26:      <a href="/companion" data-route="/companion">Companion</a>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:15:function cleanCompanionErrorMessage(value) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:62:  if (typeof cleanCompanionErrorMessage === "function") {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:63:    return cleanCompanionErrorMessage(text);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:158:      ["Companion", "Use Companion for general conversation, study help, explanations, and supportive conversation.", "/companion"],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:159:      ["Profile", "Manage preferences, permissions, account settings, and future companion personalization.", "/profile"],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:193:    title: "Companion",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:195:      "Chat remains a compatibility alias while Companion becomes the main AI surface for conversation, study help, explanations, and supportive support.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:197:      ["Companion", "General local-first AI conversation through the existing queued worker path."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:206:    title: "Companion",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:208:      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:210:      ["General conversation", "Use Companion for normal local-first AI conversation."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:211:      ["Study helper", "Future stages will let Companion start study sessions, select decks, read questions, and grade answers."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:213:      ["Helpful boundaries", "Companion should stay supportive, ask when unsure, and use safety-aware boundaries."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:236:      "Profile will manage account settings, preferences, permissions, and personalization for the platform.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:313: * - /api/companion/* = laptop controller-owned Companion API
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:884:      name: "Companion API",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:886:      detail: "Companion chat, study grading, and context support are active.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1738:        <p>Study, Companion, Profile, Calendar, Images, and related APIs.</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3298:      <p class="eyebrow">Companion</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3299:      <h1>Companion</h1>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3301:        Send a message through the existing laptop-owned queued AI path. CT101 processes one Ollama job at a time while the UI presents one main Companion surface.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3313:            <strong>Companion queue worker</strong>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3321:            <textarea id="queuedChatInput" rows="5" placeholder="Ask Companion something..."></textarea>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3337:          <strong>Please log in to use Companion.</strong>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3338:          <p>Companion uses your active account session to create real-user queue jobs.</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3371:        detail: `job ${jobId} · ${result.model || job.requested_model || "model unknown"}`
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3416:        requested_model: "gemma4:e4b",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3535:    body: "Build decks, add cards, review by difficulty, and track progress over time. Once signed in, this page becomes your personal study dashboard.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3543:    eyebrow: "Companion",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:3555:    body: "Profile centralizes account details, preferences, permissions, and future personalization settings.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6323:    if (payload && payload.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6324:      cleanPayload.requested_model = String(payload.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6327:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6404:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6572:        hasModel: Boolean(context && context.requested_model),
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6621:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6622:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6663: * - builds only message, chat_id, and requested_model
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6694:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:6695:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/index.html.bak-stage5o24-study-format-cleanup-2026-06-11-121612:14:      <span class="brand-mark helper-logo" title="Study Companion Helper">
frontend/wrapper-ui/index.html.bak-stage5o24-study-format-cleanup-2026-06-11-121612:15:        <svg viewBox="0 0 64 64" role="img" aria-label="Study Companion Helper logo">
frontend/wrapper-ui/index.html.bak-stage5o24-study-format-cleanup-2026-06-11-121612:26:      <a href="/companion" data-route="/companion">Companion</a>
frontend/wrapper-ui/index.html.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:14:      <span class="brand-mark helper-logo" title="Study Companion Helper">
frontend/wrapper-ui/index.html.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:15:        <svg viewBox="0 0 64 64" role="img" aria-label="Study Companion Helper logo">
frontend/wrapper-ui/index.html.bak-stage5o27b-public-gate-blank-fix-2026-06-11-122012:26:      <a href="/companion" data-route="/companion">Companion</a>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:15:function cleanCompanionErrorMessage(value) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:62:  if (typeof cleanCompanionErrorMessage === "function") {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:63:    return cleanCompanionErrorMessage(text);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:158:      ["Companion", "Use Companion for general conversation, study help, explanations, and supportive conversation.", "/companion"],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:159:      ["Profile", "Manage preferences, permissions, account settings, and future companion personalization.", "/profile"],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:193:    title: "Companion",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:195:      "Chat remains a compatibility alias while Companion becomes the main AI surface for conversation, study help, explanations, and supportive support.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:197:      ["Companion", "General local-first AI conversation through the existing queued worker path."],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:206:    title: "Companion",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:208:      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:210:      ["General conversation", "Use Companion for normal local-first AI conversation."],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:211:      ["Study helper", "Future stages will let Companion start study sessions, select decks, read questions, and grade answers."],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:213:      ["Helpful boundaries", "Companion should stay supportive, ask when unsure, and use safety-aware boundaries."],
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:236:      "Profile will manage account settings, preferences, permissions, and personalization for the platform.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:313: * - /api/companion/* = laptop controller-owned Companion API
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:884:      name: "Companion API",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:886:      detail: "Companion chat, study grading, and context support are active.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:1738:        <p>Study, Companion, Profile, Calendar, Images, and related APIs.</p>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3253:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3298:      <p class="eyebrow">Companion</p>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3299:      <h1>Companion</h1>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3301:        Send a message through the existing laptop-owned queued AI path. CT101 processes one Ollama job at a time while the UI presents one main Companion surface.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3313:            <strong>Companion queue worker</strong>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3321:            <textarea id="queuedChatInput" rows="5" placeholder="Ask Companion something..."></textarea>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3337:          <strong>Please log in to use Companion.</strong>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3338:          <p>Companion uses your active account session to create real-user queue jobs.</p>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3352:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3371:        detail: `job ${jobId} · ${result.model || job.requested_model || "model unknown"}`
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3410:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3416:        requested_model: "gemma4:e4b",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3535:    body: "Build decks, add cards, review by difficulty, and track progress over time. Once signed in, this page becomes your personal study dashboard.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3543:    eyebrow: "Companion",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3555:    body: "Profile explains how account settings, privacy controls, permissions, and personalization will work after you sign in.",
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3670:        <strong>Account and personalization</strong>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3673:          personalization settings for the platform.
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:3710:          <p>Choose what Study, Companion, Calendar providers, and future tools may use as context.</p>
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6432:    if (payload && payload.requested_model) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6433:      cleanPayload.requested_model = String(payload.requested_model);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6436:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6513:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6681:        hasModel: Boolean(context && context.requested_model),
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6730:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6731:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6772: * - builds only message, chat_id, and requested_model
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6803:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage-5o35-2026-06-11-134447:6804:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/dev_server.py:83:    if path == "/api/chat/queued" or path.startswith("/api/chat/queued/"):
frontend/wrapper-ui/dev_server.py:290:        # session endpoint so direct /api/chat/queued can receive trusted
frontend/wrapper-ui/dev_server.py:425:            auth_source_path == "/api/chat/queued"
frontend/wrapper-ui/dev_server.py:426:            or auth_source_path.startswith("/api/chat/queued/")
frontend/wrapper-ui/dev_server.py:433:        # Direct browser queued-chat calls use /api/chat/queued, not the older
frontend/wrapper-ui/dev_server.py:438:            auth_source_path == "/api/chat/queued"
frontend/wrapper-ui/dev_server.py:439:            or auth_source_path.startswith("/api/chat/queued/")
frontend/wrapper-ui/dev_server.py:532:    #   POST /api/chat/queued
frontend/wrapper-ui/dev_server.py:533:    #   GET  /api/chat/queued/{job_id}
frontend/wrapper-ui/dev_server.py:578:            "/api/chat/queued",
frontend/wrapper-ui/dev_server.py:611:            if str(upstream_path or "").startswith("/api/chat/queued") and EDGE_TRUSTED_PROXY_SECRET:
frontend/wrapper-ui/dev_server.py:741:                laptop_payload["requested_model"] = str(ct101_payload.get("model"))
frontend/wrapper-ui/dev_server.py:755:                "/api/chat/queued",
frontend/wrapper-ui/dev_server.py:776:                f"/api/chat/queued/{job_id}",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:15:function cleanCompanionErrorMessage(value) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:62:  if (typeof cleanCompanionErrorMessage === "function") {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:63:    return cleanCompanionErrorMessage(text);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:153:      ["Companion", "Use Companion for general conversation, study help, explanations, and supportive conversation.", "/companion"],
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:154:      ["Profile", "Manage preferences, permissions, account settings, and future companion personalization.", "/profile"],
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:188:    title: "Companion",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:190:      "Chat remains a compatibility alias while Companion becomes the main AI surface for conversation, study help, explanations, and supportive support.",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:192:      ["Companion", "General local-first AI conversation through the existing queued worker path."],
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:201:    title: "Companion",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:203:      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:205:      ["General conversation", "Use Companion for normal local-first AI conversation."],
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:206:      ["Study helper", "Future stages will let Companion start study sessions, select decks, read questions, and grade answers."],
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:208:      ["Helpful boundaries", "Companion should stay supportive, ask when unsure, and use safety-aware boundaries."],
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:231:      "Profile will manage account settings, preferences, permissions, and personalization for the platform.",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:308: * - /api/companion/* = laptop controller-owned Companion API
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:879:      name: "Companion API",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:881:      detail: "Companion chat, study grading, and context support are active.",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:1733:        <p>Study, Companion, Profile, Calendar, Images, and related APIs.</p>
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3249:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3294:      <p class="eyebrow">Companion</p>
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3295:      <h1>Companion</h1>
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3297:        Send a message through the existing laptop-owned queued AI path. CT101 processes one Ollama job at a time while the UI presents one main Companion surface.
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3309:            <strong>Companion queue worker</strong>
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3317:            <textarea id="queuedChatInput" rows="5" placeholder="Ask Companion something..."></textarea>
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3333:          <strong>Please log in to use Companion.</strong>
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3334:          <p>Companion uses your active account session to create real-user queue jobs.</p>
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3348:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3367:        detail: `job ${jobId} · ${result.model || job.requested_model || "model unknown"}`
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3406:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:3412:        requested_model: "gemma4:e4b",
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6052:    if (payload && payload.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6053:      cleanPayload.requested_model = String(payload.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6056:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6133:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6301:        hasModel: Boolean(context && context.requested_model),
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6350:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6351:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6392: * - builds only message, chat_id, and requested_model
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6423:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o8-header-active-2026-06-11-110049:6424:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/index.html.bak-stage5o29-support-public-summary-2026-06-11-122711:14:      <span class="brand-mark helper-logo" title="Study Companion Helper">
frontend/wrapper-ui/index.html.bak-stage5o29-support-public-summary-2026-06-11-122711:15:        <svg viewBox="0 0 64 64" role="img" aria-label="Study Companion Helper logo">
frontend/wrapper-ui/index.html.bak-stage5o29-support-public-summary-2026-06-11-122711:26:      <a href="/companion" data-route="/companion">Companion</a>
frontend/wrapper-ui/index.html.bak-stage5o30-support-public-override-2026-06-11-122836:14:      <span class="brand-mark helper-logo" title="Study Companion Helper">
frontend/wrapper-ui/index.html.bak-stage5o30-support-public-override-2026-06-11-122836:15:        <svg viewBox="0 0 64 64" role="img" aria-label="Study Companion Helper logo">
frontend/wrapper-ui/index.html.bak-stage5o30-support-public-override-2026-06-11-122836:26:      <a href="/companion" data-route="/companion">Companion</a>
frontend/wrapper-ui/index.html.bak-stage7q-2026-06-12-135105:14:      <span class="brand-mark helper-logo" title="Study Companion Helper">
frontend/wrapper-ui/index.html.bak-stage7q-2026-06-12-135105:15:        <svg viewBox="0 0 64 64" role="img" aria-label="Study Companion Helper logo">
frontend/wrapper-ui/index.html.bak-stage7q-2026-06-12-135105:26:      <a href="/companion" data-route="/companion">Companion</a>
frontend/wrapper-ui/index.html.bak-stage5o31-force-support-public-summary-2026-06-11-122923:14:      <span class="brand-mark helper-logo" title="Study Companion Helper">
frontend/wrapper-ui/index.html.bak-stage5o31-force-support-public-summary-2026-06-11-122923:15:        <svg viewBox="0 0 64 64" role="img" aria-label="Study Companion Helper logo">
frontend/wrapper-ui/index.html.bak-stage5o31-force-support-public-summary-2026-06-11-122923:26:      <a href="/companion" data-route="/companion">Companion</a>
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:15:function cleanCompanionErrorMessage(value) {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:62:  if (typeof cleanCompanionErrorMessage === "function") {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:63:    return cleanCompanionErrorMessage(text);
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:158:      ["Companion", "Use Companion for general conversation, study help, explanations, and supportive conversation.", "/companion"],
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:159:      ["Profile", "Manage preferences, permissions, account settings, and future companion personalization.", "/profile"],
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:193:    title: "Companion",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:195:      "Chat remains a compatibility alias while Companion becomes the main AI surface for conversation, study help, explanations, and supportive support.",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:197:      ["Companion", "General local-first AI conversation through the existing queued worker path."],
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:206:    title: "Companion",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:208:      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:210:      ["General conversation", "Use Companion for normal local-first AI conversation."],
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:211:      ["Study helper", "Future stages will let Companion start study sessions, select decks, read questions, and grade answers."],
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:213:      ["Helpful boundaries", "Companion should stay supportive, ask when unsure, and use safety-aware boundaries."],
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:236:      "Profile will manage account settings, preferences, permissions, and personalization for the platform.",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:313: * - /api/companion/* = laptop controller-owned Companion API
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:884:      name: "Companion API",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:886:      detail: "Companion chat, study grading, and context support are active.",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:1738:        <p>Study, Companion, Profile, Calendar, Images, and related APIs.</p>
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3254:// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3299:      <p class="eyebrow">Companion</p>
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3300:      <h1>Companion</h1>
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3302:        Send a message through the existing laptop-owned queued AI path. CT101 processes one Ollama job at a time while the UI presents one main Companion surface.
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3314:            <strong>Companion queue worker</strong>
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3322:            <textarea id="queuedChatInput" rows="5" placeholder="Ask Companion something..."></textarea>
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3338:          <strong>Please log in to use Companion.</strong>
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3339:          <p>Companion uses your active account session to create real-user queue jobs.</p>
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3353:    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3372:        detail: `job ${jobId} · ${result.model || job.requested_model || "model unknown"}`
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3411:    const res = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3417:        requested_model: "gemma4:e4b",
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:3501:    // nav, panels, and spacing match Companion/Profile/Admin/System.
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6083:    if (payload && payload.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6084:      cleanPayload.requested_model = String(payload.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6087:    const response = await fetch("/api/chat/queued", {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6164:    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6332:        hasModel: Boolean(context && context.requested_model),
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6381:    if (context && context.requested_model) {
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6382:      payload.requested_model = String(context.requested_model);
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6423: * - builds only message, chat_id, and requested_model
frontend/wrapper-ui/app.js.bak-stage5o18-study-style-reenable-2026-06-11-120520:6454:    if (context && context.requested_model) {

=== rewrite AH smoke to remove shell backtick command-substitution defect ===
=== run corrected AH smoke ===
PASS: Stage 16 FC-O45-E-AH job127 result-reader quality contract doc smoke

=== AI conclusion ===
Job127 proved runtime, but Qwen/Alibaba identity leakage requires prompt/persona wrapper repair before more product-quality Companion runtime.
Next runtime phase should be approval-gated exact-one-job only.
```
