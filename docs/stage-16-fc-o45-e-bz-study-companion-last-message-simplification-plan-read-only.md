# Stage 16 FC-O45-E-BZ — Study Companion Last-Message Simplification Plan Read-Only

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `064859d`
- Prior deploy tag: `controller-stage-16-fc-o45-e-by-deploy-companion-final-render-wins-over-restricted-static-path-2026-06-24`

## User direction

The public website is still glitchy. The chosen product direction is to simplify:

```
Set up the Companion to work with the Study tools and show the last message to the user, then focus later on cleaning up the website.
```

## Purpose

BZ is read-only. It records the current source/public/backend state and defines the next safer target: a stable Study Companion last-message MVP instead of continuing to fight the full chat SPA behavior.

## Scope

Read-only source/public/DB diagnostic plus repo docs/smoke commit/tag only.

Explicitly not allowed and not performed:

- NO source patch.
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

## Recommendation

```
SHIFT_TO_STUDY_COMPANION_LAST_MESSAGE_MVP
```

Target behavior:

- Companion page becomes stable, boring, and useful.
- It shows a "Last AI answer" panel from localStorage and/or latest completed Companion job.
- It shows one simple message box.
- It avoids long boot timers, repeated route poking, and complicated restore loops.
- It can include Study action buttons as non-destructive UI placeholders:
  - Copy answer
  - Use in Study
  - Make flashcards
  - Quiz me
- Until a persistent worker exists, the page should honestly show "Queued — worker not running yet" instead of constantly trying to reload.

## Proposed next phases

```
FC-O45-E-CA — source patch: stable Study Companion last-message MVP, no runtime
FC-O45-E-CB — deploy static app.js/styles.css over restricted VM200 path after approval
FC-O45-E-CC — browser validation and closure checkpoint
```

## Output

```
=== Stage 16 FC-O45-E-BZ Study Companion last-message simplification plan read-only ===
MUTATION_SCOPE=read_only_source_public_db_diagnostic_plus_repo_doc_smoke_commit_tag_push
USER_DIRECTION=simplify_companion_show_last_message_integrate_with_study_tools_then_clean_website_later
NO source patch
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
expected_head=064859d
head_now=064859d
origin_main_now=064859d
git_preflight=PASS

=== public deployed static markers read-only ===
public_root_http=200
public_app_js_http=200
/app.js?v=20260624fc045eby
1:/* APC_STUDY_FULL_WORKSPACE_FC_O45_C_N_R2: disable early duplicate Study tools before route code runs. */
2:window.__apcStudySingleOwnerDisableEarlyToolsFcO45CL = true;
3:window.__apcStudyCanonicalFullWorkspaceFcO45CNR2 = true;
8: * Runs before the older wrapper code so Study cleanup is registered even if later
9: * modules fail. Public-safe: API data is requested only from authenticated Study
33:  function looksLikeStudy() {
35:    return t.includes("Study session") || t.includes("Deck selector") || t.includes(LEGACY_PHRASE);
47:    /* APC_STUDY_TOOLS_AUTH_CLEANUP_FC_O45_C_K: prefer wrapper api() so signed-in Study calls carry auth headers. */
60:          data: { detail: error?.message || "Study API unavailable" },
87:      const isWholeShell = t.includes("Study session") && t.includes("Deck selector") && t.includes(LEGACY_PHRASE);
111:        if (t.includes("Study session") && t.includes("Deck selector")) break;
123:    if (window.__apcStudySingleOwnerDisableEarlyToolsFcO45CL) {
124:      let scratch = document.getElementById("apcStudyEarlyToolsScratchFcO45CL");
127:        scratch.id = "apcStudyEarlyToolsScratchFcO45CL";
140:      || anchors.find((el) => textOf(el).includes("Study session"));
146:      if (t.includes("Study session") && t.length < 2600) break;
155:      <h2>Study tools</h2>
156:      <p class="muted">Decks, cards, stats, and review queue are loaded from your signed-in Study account.</p>
158:        <section class="mini-summary" id="apcStudyEarlyDecks"><strong>Decks</strong><p class="muted">Loading decks…</p></section>
159:        <section class="mini-summary" id="apcStudyEarlyStats"><strong>Stats</strong><p class="muted">Loading progress…</p></section>
162:        <section class="mini-summary" id="apcStudyEarlyCards"><strong>Cards</strong><p class="muted">Choose a deck to load cards.</p></section>
163:        <section class="mini-summary" id="apcStudyEarlyReview"><strong>Review queue</strong><p class="muted">Choose a deck to load the review queue.</p></section>
176:    const panel = document.getElementById("apcStudyEarlyDecks");
202:    const panel = document.getElementById("apcStudyEarlyStats");
218:    const panel = document.getElementById("apcStudyEarlyCards");
234:    const panel = document.getElementById("apcStudyEarlyReview");
271:      const stats = document.getElementById("apcStudyEarlyStats");
279:      const p = document.getElementById("apcStudyEarlyCards");
285:      const p = document.getElementById("apcStudyEarlyReview");
291:    if (!document.body || !looksLikeStudy()) return;
296:      if (panel) panel.innerHTML = `<h2>Study tools</h2><p class="muted">Study tools could not load yet.</p>`;
297:      console.warn(`[${MARKER}] Study tools load skipped`, error);
306:  window.apcStudyEarlyRepairFcO45CG = { marker: MARKER, repair: runRepair };
320:      if (document.body && looksLikeStudy()) schedule();
380:  token: localStorage.getItem("edgeStudyToken") || "",
448:      `edgeStudyToken=<redacted> Path=/; Max-Age=2592000; SameSite=Lax${secure}`;
451:      `edgeStudyToken=<redacted> Path=/; Max-Age=0; SameSite=Lax${secure}`;
487:      ["Study", "Create decks, review cards, track progress, and focus on cards that need more practice.", "/study"],
502:    title: "Study Wrapper Preview",
503:    subtitle: "Preview of the Study dashboard inside the shared wrapper layout. Study behavior is not wired here yet.",
509:    title: "Study",
511:      "Study helps users create decks, add cards, review material, track progress, and prioritize what needs more practice.",
528:      ["Study-aware direction", "Future stages will add study session controls, deck/card tools, and answer checking."],
541:      ["Study helper", "Future stages will let Companion start study sessions, select decks, read questions, and grade answers."],
642: * - /api/study/* = CT203/controller-owned Study API
1256:      name: "Study API",
2116:        <p>Study, Companion, Profile, Calendar, Images, and related APIs.</p>
2861:            <li>Study summaries</li>
3032:function setStudyWrapperPreviewReadOnly() {
3064:    el.title = "Preview only. Use the live Study page for editing and review actions.";
3074:      <p>This shared-layout preview is read-only. Use <a href="/study">the live Study page</a> to create decks, add cards, or review cards.</p>
3133:function renderStudyWrapperPreviewDeckSummary(deck) {
3154:async function createStudyWrapperPreviewDeck(event) {
3188:    await hydrateStudyWrapperPreview(newDeckId);
3207:async function submitStudyWrapperPreviewReview(cardId, wasCorrect) {
3234:      await hydrateStudyWrapperPreview(deckId);
3237:    renderStudyWrapperPreviewReviewCard();
3248:function renderStudyWrapperPreviewReviewCard() {
3298:    renderStudyWrapperPreviewReviewCard();
3304:    renderStudyWrapperPreviewReviewCard();
3308:    submitStudyWrapperPreviewReview(card.id, false);
3312:    submitStudyWrapperPreviewReview(card.id, true);
3316:async function loadStudyWrapperPreviewReviewQueue() {
3353:    renderStudyWrapperPreviewReviewCard();
3363:function bindStudyWrapperPreviewReviewQueue() {
3377:    button.onclick = loadStudyWrapperPreviewReviewQueue;
3382:async function createStudyWrapperPreviewCard(event) {
3427:    await hydrateStudyWrapperPreview(deckId);
3437:function bindStudyWrapperPreviewCreateCard() {
3456:  form.onsubmit = createStudyWrapperPreviewCard;
3460:function bindStudyWrapperPreviewCreateDeck() {
3481:  form.onsubmit = createStudyWrapperPreviewDeck;
3485:function bindStudyWrapperPreviewDeckSwitch(decks) {
3495:    renderStudyWrapperPreviewDeckSummary(selected);
3496:    hydrateStudyWrapperPreviewDeck(deckSelect.value);
3501:async function hydrateStudyWrapperPreviewDeck(deckId) {
3565:async function hydrateStudyWrapperPreview(preferredDeckId = null) {
3570:    if (statusText) statusText.textContent = "Loading Study data...";
3610:    renderStudyWrapperPreviewDeckSummary(selectedDeck);
3611:    bindStudyWrapperPreviewDeckSwitch(decks);
3612:    bindStudyWrapperPreviewCreateDeck();
3613:    bindStudyWrapperPreviewCreateCard();
3614:    bindStudyWrapperPreviewReviewQueue();
3630:      hydrateStudyWrapperPreviewDeck(selectedDeck.id);
3633:    if (statusText) statusText.textContent = "Study data loaded";
3637:    if (statusText) statusText.textContent = "Could not load Study data";
3643:async function loadStudyWrapperPreview() {
3646:  const isLiveStudyRoute = window.location.pathname === "/study";
3665:        <p class="eyebrow">${isLiveStudyRoute ? "Study" : "Candidate route"}</p>
3666:        <h1>${isLiveStudyRoute ? "Study" : "Study Wrapper Preview"}</h1>
3668:          ${isLiveStudyRoute
3670:            : "Shared-wrapper candidate route for Study. Use this to verify behavior before removing the standalone fallback."}
3672:        ${isLiveStudyRoute ? "" : `
3674:            <a class="primary-btn" href="/study">Open Live Study</a>
3684:    hydrateStudyWrapperPreview();
3689:        <h1>Study Wrapper Preview</h1>
3690:        <p class="subtitle">Could not load the Study partial.</p>
3739:function renderQueuedChatPage() {
3788:      || window.localStorage.getItem("edgeStudyToken")
3987:function stage5p11iNormalizeStudyPhrase(value) {
3998:function stage5p11iLooksLikeStudyCommand(message) {
3999:  const text = stage5p11iNormalizeStudyPhrase(message);
4049:  const hasStudy = /\bstudy\b/.test(text);
4061:  if (hasStudy && hasSession && hasLifecycle) return true;
4071:    return String(window.localStorage.getItem("stage5p9aSelectedStudyDeckId") || "").trim();
4079:  return "stage5p11qSelectedStudyReviewStyle";
4118:  const text = stage5p11iNormalizeStudyPhrase(message);
4128:  const prefix = deckLabel ? "Selected Study deck: " + deckLabel + ".\n\n" : "";
4140:  const text = stage5p11iNormalizeStudyPhrase(message);
4163:      reply: "Review style selected: " + label + ".\n\nNow choose a Study deck. Say “List my decks” or “Select my math deck.”"
4169:    reply: "Review style selected: " + label + ".\n\nSay “Study session start” when you are ready."
4180:    window.localStorage.setItem("stage5p9aSelectedStudyDeckId", clean);
4196:  return stage5p11iNormalizeStudyPhrase(stage5p11pDeckTitle(deck));
4232:    const detail = data.detail || data.message || "Could not list Study decks.";
4244:    return "You do not have any Study decks yet. Create a deck in Study first.";
4257:  let reply = "Your Study decks:\n" + lines.join("\n");
4264:  let text = stage5p11iNormalizeStudyPhrase(message);
4295:  const normalized = stage5p11iNormalizeStudyPhrase(message);
4348:  const text = stage5p11iNormalizeStudyPhrase(message);
4354:  const text = stage5p11iNormalizeStudyPhrase(message);
4389:  const normalized = stage5p11iNormalizeStudyPhrase(message);
4403:        ? "Selected Study deck: " + title + " — deck " + deckId + ".\n\nReview style selected: " + stage5p11qReviewStyleLabel(reviewMode) + ".\n\nSay “Study session start” when you are ready."
4428:      message: "Study session start",
4437:    const detail = data.detail || data.message || "Could not start Study session.";
4443:    reply: "Selected Study deck: " + title + " — deck " + deckId + ".\nReview style: " + stage5p11qReviewStyleLabel(reviewMode) + ".\n\n" + stage5p11iAssistantSummary(data)
4464:    if (question) return "Study session is active. Current question: " + question;
4465:    return "Study session is active. Continue with Read answer, Correct, Wrong, or Skip.";
4468:  if (status === "completed") return "Study session completed. Nice work.";
4469:  if (status === "paused") return "Study session paused. Say “Study session resume” when you are ready.";
4470:  if (status === "stopped") return "Study session stopped.";
4476:  return "Study command handled.";
4479:async function stage5p11iRouteCompanionStudyCommand(message) {
4503:  const normalized = stage5p11iNormalizeStudyPhrase(message);
4531:    const detail = data.detail || data.message || "Study command failed.";
4766:  const normalized = stage5p11iNormalizeStudyPhrase(text);
4779:async function stage5p11jFetchStudyStatus() {
4796:async function stage5p11jSendStudyCommand(message) {
4807:    const detail = data.detail || data.message || "Study command failed.";
4831:async function stage5p11jRouteCompanionStudyAnswer(message) {
4836:  const session = await stage5p11jFetchStudyStatus();
4850:    const data = await stage5p11jSendStudyCommand("Correct");
4858:    const data = await stage5p11jSendStudyCommand("Wrong");
4887:  if (stage5p11iLooksLikeStudyCommand(message)) {
4894:    queuedChatSetStatus("Handling Study command...");
4897:      const routed = await stage5p11iRouteCompanionStudyCommand(message);
4901:        detail: "Study session command"
4903:      queuedChatSetStatus("Study command complete");
4907:        content: "I could not complete that Study command.",
4910:      queuedChatSetStatus("Study command failed");
4924:    queuedChatSetStatus("Checking Study answer...");
4927:      const answerAttempt = await stage5p11jRouteCompanionStudyAnswer(message);
4940:          detail: "Study answer check"
4943:        queuedChatSetStatus("Study answer checked");
4953:        content: "I could not check that Study answer.",
4957:      queuedChatSetStatus("Study answer check failed");
5126:    eyebrow: "Study",
5127:    title: "Study smarter with decks, cards, and adaptive review.",
5141:      ["Study context", "Future companion features can use allowed study context."],
5264:    ["Study language", prefs.study_language],
5442:        ${renderProfilePreferenceSelect("study_language", "Study language", prefs.study_language, [
5474:        ${renderProfilePreferenceSelect("study_session_default_mode", "Study mode", prefs.study_session_default_mode, [
5482:          ["study_coach", "Study coach"],
5695:          <p>Choose what Study, Companion, Calendar providers, and future tools may use as context.</p>
5714: * Real /study must not mount the old Study wrapper preview mini-app. That
5715: * legacy preview includes its own banner/nav shell, causing two Study pages on
5723: * - signed-out users get exactly one public Study page;
5724: * - signed-in users get the durable Study session/deck selector plus one Study tools panel;
5727:window.__apcStudySingleOwnerDisableEarlyToolsFcO45CL = true;
5729:function apcStudySingleOwnerIsStudyRouteFcO45CL() {
5739:function apcStudySingleOwnerHasSessionFcO45CL() {
5747:    if (window.localStorage && (localStorage.getItem("edgeStudyToken") || localStorage.getItem("edgeAuthToken"))) return true;
5752:function apcStudySingleOwnerStudyToolPanelsFcO45CL() {
5756:    "#apcStudyEarlyToolsPanel",
5757:    "#apcStudyToolsPanel",
5758:    "#apcStudyEarlyToolsScratchFcO45CL",
5769:      if ((heading.textContent || "").trim() !== "Study tools") return;
5778:function apcStudySingleOwnerCleanupFcO45CL() {
5779:  if (!apcStudySingleOwnerIsStudyRouteFcO45CL()) return;
5781:  const panels = apcStudySingleOwnerStudyToolPanelsFcO45CL();
5782:  const signedIn = apcStudySingleOwnerHasSessionFcO45CL();
5787:    const visiblePanels = panels.filter((panel) => panel.id !== "apcStudyEarlyToolsScratchFcO45CL");
5788:    const keep = visiblePanels.find((panel) => panel.id === "apcStudyFullWorkspacePanelFcO45CNR2")
5802:    document.querySelectorAll("#apcStudyEarlyToolsScratchFcO45CL").forEach((node) => node.remove());
5806:function apcStudySingleOwnerScheduleCleanupFcO45CL() {
5810:        apcStudySingleOwnerCleanupFcO45CL();
5818:function apcStudySingleOwnerArmObserverFcO45CL() {
5819:  if (window.__apcStudySingleOwnerObserverFcO45CL) return;
5822:      if (!apcStudySingleOwnerIsStudyRouteFcO45CL()) return;
5823:      if (window.__apcStudySingleOwnerCleanupQueuedFcO45CL) return;
5824:      window.__apcStudySingleOwnerCleanupQueuedFcO45CL = true;
5826:        window.__apcStudySingleOwnerCleanupQueuedFcO45CL = false;
5827:        apcStudySingleOwnerCleanupFcO45CL();
5834:    window.__apcStudySingleOwnerObserverFcO45CL = observer;
5838:apcStudySingleOwnerArmObserverFcO45CL();
5844: * Canonical signed-in Study workspace. This restores deck/card CRUD controls,
5846: * one Study tools panel without reintroducing duplicate Study renderers.
5848:window.apcStudyFullWorkspaceFcO45CNR2 = (function () {
5850:  const PANEL_ID = "apcStudyFullWorkspacePanelFcO45CNR2";
5913:      "#apcStudyWorkspaceStatusFcO45CNR2{padding:.7rem .9rem;border-radius:12px;background:rgba(34,197,94,.12);border:1px solid rgba(34,197,94,.22);}",
5940:    try { if (typeof apcStudySingleOwnerHasSessionFcO45CL === "function" && apcStudySingleOwnerHasSessionFcO45CL()) return true; } catch (_) {}
5946:  function isStudyRoute() {
5969:      return { ok: false, status: Number(error && error.status) || 0, data: { detail: (error && error.message) || "Study API unavailable" } };
5984:      return { ok: false, status: 0, data: { detail: (error && error.message) || "Study API unavailable" } };
6006:  function removeOtherStudyTools() {
6008:    ["#apcStudyEarlyToolsPanel", "#apcStudyToolsPanel", "#apcStudyEarlyToolsScratchFcO45CL", "[data-apc-study-tools-panel]", "[data-apc-study-tools-auth-cleanup]"].forEach(function (selector) {
6013:        if ((heading.textContent || "").trim() !== "Study tools") return;
6028:    const sessionHeading = headings.find(function (node) { return (node.textContent || "").trim() === "Study session"; });
6035:    removeOtherStudyTools();
6060:      "<h2>Study tools</h2>",
6061:      "<p class=\"muted\">Decks, cards, stats, progress, and review queue are loaded from your signed-in Study account.</p>",
6063:      "<form id=\"apcStudyCreateDeckFormFcO45CNR2\" class=\"inline-form\"><label>New deck name <input id=\"apcStudyCreateDeckNameFcO45CNR2\" name=\"name\" placeholder=\"Example: Math 316 Review\" autocomplete=\"off\" /></label><button type=\"submit\">Create deck</button></form>",
6064:      "<form id=\"apcStudyCreateCardFormFcO45CNR2\" class=\"inline-form\"><label>Card front <input id=\"apcStudyCreateCardFrontFcO45CNR2\" name=\"front\" placeholder=\"Question or prompt\" autocomplete=\"off\" /></label><label>Card back <input id=\"apcStudyCreateCardBackFcO45CNR2\" name=\"back\" placeholder=\"Answer\" autocomplete=\"off\" /></label><button type=\"submit\">Add card</button></form>",
6066:      "<section class=\"mini-summary\" id=\"apcStudyOverallProgressFcO45CNR2\"><strong>Overall progress</strong><p class=\"muted\">Loading overall progress...</p></section>",
6067:      "<section class=\"mini-summary\" id=\"apcStudyWeeklyProgressFcO45CNR2\"><strong>Weekly progress</strong><p class=\"muted\">Loading weekly progress...</p></section>",
6068:      "<section class=\"mini-summary\" id=\"apcStudyDecksPanelFcO45CNR2\"><strong>Decks</strong><p class=\"muted\">Loading decks...</p></section>",
6069:      "<section class=\"mini-summary\" id=\"apcStudyDeckStatsPanelFcO45CNR2\"><strong>Deck/card statistics</strong><p class=\"muted\">Loading deck and card statistics...</p></section>",
6070:      "<section class=\"mini-summary\" id=\"apcStudyCardsPanelFcO45CNR2\"><strong>Cards</strong><p class=\"muted\">Loading cards...</p></section>",
6071:      "<section class=\"mini-summary\" id=\"apcStudyQueuePanelFcO45CNR2\"><strong>Review queue</strong><p class=\"muted\">Loading review queue...</p></section>",
6072:      "<p class=\"muted\" id=\"apcStudyWorkspaceStatusFcO45CNR2\">Ready.</p>"
6077:    const node = document.getElementById("apcStudyWorkspaceStatusFcO45CNR2");
6082:    const node = document.getElementById("apcStudyOverallProgressFcO45CNR2");
6093:    const node = document.getElementById("apcStudyWeeklyProgressFcO45CNR2");
6111:    const node = document.getElementById("apcStudyDecksPanelFcO45CNR2");
6130:    const node = document.getElementById("apcStudyDeckStatsPanelFcO45CNR2");
6147:    const node = document.getElementById("apcStudyCardsPanelFcO45CNR2");
6168:    const node = document.getElementById("apcStudyQueuePanelFcO45CNR2");
6185:    if (!isStudyRoute() || !signedIn()) return;
6188:    setStatus("Loading Study workspace...");
6192:      panel.innerHTML = "<h2>Study tools</h2><p class=\"muted\">Study workspace could not load (" + esc(decksResult.status) + "). Try refreshing after sign-in.</p>";
6215:    setStatus("Study workspace loaded.");
6216:    try { if (typeof apcStudySingleOwnerScheduleCleanupFcO45CL === "function") apcStudySingleOwnerScheduleCleanupFcO45CL(); } catch (_) {}
6220:    const deckForm = document.getElementById("apcStudyCreateDeckFormFcO45CNR2");
6225:        const name = (document.getElementById("apcStudyCreateDeckNameFcO45CNR2").value || "").trim();
6234:    const cardForm = document.getElementById("apcStudyCreateCardFormFcO45CNR2");
6240:        const front = (document.getElementById("apcStudyCreateCardFrontFcO45CNR2").value || "").trim();
6241:        const back = (document.getElementById("apcStudyCreateCardBackFcO45CNR2").value || "").trim();
6312:    if (!isStudyRoute()) return;
6314:      removeOtherStudyTools();
6323:function renderCleanStudyRouteFcO45CJ() {
6327:  if (!apcStudySingleOwnerHasSessionFcO45CL()) {
6334:            <p class="eyebrow">Study</p>
6335:            <h1>Study</h1>
6336:            <p>Sign in to load your Study deck, durable session, cards, stats, and review queue.</p>
6341:    apcStudySingleOwnerScheduleCleanupFcO45CL();
6357:      if (window.apcStudyFullWorkspaceFcO45CNR2 && typeof window.apcStudyFullWorkspaceFcO45CNR2.mount === "function") {
6358:        window.apcStudyFullWorkspaceFcO45CNR2.mount();
6360:      apcStudySingleOwnerScheduleCleanupFcO45CL();
6362:      console.warn("[APC_STUDY_FULL_WORKSPACE_FC_O45_C_N_R2] Study workspace mount skipped", error);
6363:      apcStudySingleOwnerScheduleCleanupFcO45CL();
6408:  const isStudyWrapperRoute = path === "/study-wrapper-preview";
6415:    // Study content may use its own content stylesheet, but the shared
6417:    studyPreviewStyle.disabled = !isStudyWrapperRoute;
6421:    renderCleanStudyRouteFcO45CJ();
6425:  if (isStudyWrapperRoute) {
6430:    loadStudyWrapperPreview();
6440:    $("app").innerHTML = renderQueuedChatPage();
7025:    localStorage.setItem("edgeStudyToken", token);
7070:  localStorage.removeItem("edgeStudyToken");
7090:    localStorage.removeItem("edgeStudyToken");
7547:          <span>Study and companion</span>

=== source map: companion + study hooks ===
frontend/wrapper-ui/app.js:14:  const PANEL_ID = "apc-study-early-tools-fc-o45-c-g";
frontend/wrapper-ui/app.js:91:        item.el.setAttribute("data-apc-study-legacy-hidden", MARKER);
frontend/wrapper-ui/app.js:113:          el.setAttribute("data-apc-study-legacy-hidden", MARKER);
frontend/wrapper-ui/app.js:130:        scratch.setAttribute("data-apc-study-single-owner", "APC_STUDY_SINGLE_OWNER_FC_O45_C_L");
frontend/wrapper-ui/app.js:152:    panel.className = "card apc-study-tools";
frontend/wrapper-ui/app.js:261:    const decksResult = await apiJson("/api/study/decks");
frontend/wrapper-ui/app.js:263:      panel.setAttribute("data-apc-study-tools-auth-cleanup", "APC_STUDY_TOOLS_AUTH_CLEANUP_FC_O45_C_K");
frontend/wrapper-ui/app.js:268:    const progress = await apiJson("/api/study/progress");
frontend/wrapper-ui/app.js:276:    const cards = await apiJson(`/api/study/decks/${encodeURIComponent(deckId)}/cards`);
frontend/wrapper-ui/app.js:282:    const review = await apiJson(`/api/study/decks/${encodeURIComponent(deckId)}/review-queue`);
frontend/wrapper-ui/app.js:340:function cleanCompanionErrorMessage(value) {
frontend/wrapper-ui/app.js:386:// can decide whether /study, /chat, /companion, /calendar, and /profile should proxy
frontend/wrapper-ui/app.js:392:  if (typeof cleanCompanionErrorMessage === "function") {
frontend/wrapper-ui/app.js:393:    return cleanCompanionErrorMessage(text);
frontend/wrapper-ui/app.js:459:const PRIVATE_APP_ROUTE_SET = new Set(["/study-wrapper-preview", "/study", "/chat", "/companion", "/calendar", "/profile"]);
frontend/wrapper-ui/app.js:485:      "Practice smarter with study tools, guided review, and an AI companion designed to help you focus on what matters most.",
frontend/wrapper-ui/app.js:487:      ["Study", "Create decks, review cards, track progress, and focus on cards that need more practice.", "/study"],
frontend/wrapper-ui/app.js:488:      ["Companion", "Use Companion for general conversation, study help, explanations, and supportive conversation.", "/companion"],
frontend/wrapper-ui/app.js:494:      ["AI support", "The companion can eventually use study history, profile settings, and calendar context to support learning."],
frontend/wrapper-ui/app.js:500:  "/study-wrapper-preview": {
frontend/wrapper-ui/app.js:507:  "/study": {
frontend/wrapper-ui/app.js:513:      ["Decks and cards", "Create study decks and add questions, answers, and explanations."],
frontend/wrapper-ui/app.js:523:    title: "Companion",
frontend/wrapper-ui/app.js:525:      "Chat remains a compatibility alias while Companion becomes the main AI surface for conversation, study help, explanations, and supportive support.",
frontend/wrapper-ui/app.js:527:      ["Companion", "General local-first AI conversation through the existing queued worker path."],
frontend/wrapper-ui/app.js:528:      ["Study-aware direction", "Future stages will add study session controls, deck/card tools, and answer checking."],
frontend/wrapper-ui/app.js:536:    title: "Companion",
frontend/wrapper-ui/app.js:538:      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
frontend/wrapper-ui/app.js:540:      ["General conversation", "Use Companion for normal local-first AI conversation."],
frontend/wrapper-ui/app.js:541:      ["Study helper", "Future stages will let Companion start study sessions, select decks, read questions, and grade answers."],
frontend/wrapper-ui/app.js:542:      ["Context aware", "Future versions can use profile, calendar, study, and file context with permission."],
frontend/wrapper-ui/app.js:543:      ["Helpful boundaries", "Companion should stay supportive, ask when unsure, and use safety-aware boundaries."],
frontend/wrapper-ui/app.js:642: * - /api/study/* = CT203/controller-owned Study API
frontend/wrapper-ui/app.js:643: * - /api/companion/* = CT203/controller-owned Companion API
frontend/wrapper-ui/app.js:1251:  const study = serviceById("study-api");
frontend/wrapper-ui/app.js:1255:      id: "study-api",
frontend/wrapper-ui/app.js:1257:      state: normalizeApiState(study, "online"),
frontend/wrapper-ui/app.js:1258:      detail: normalizeApiDetail(study, "Decks, cards, reviews, stats, and study progress are active."),
frontend/wrapper-ui/app.js:1262:      name: "Companion API",
frontend/wrapper-ui/app.js:1264:      detail: "Companion chat, study grading, and context support are active.",
frontend/wrapper-ui/app.js:2116:        <p>Study, Companion, Profile, Calendar, Images, and related APIs.</p>
frontend/wrapper-ui/app.js:2870:          <p>For regular study and companion use.</p>
frontend/wrapper-ui/app.js:3033:  const root = document.querySelector(".study-wrapper-preview");
frontend/wrapper-ui/app.js:3068:  if (firstPanel && !root.querySelector("[data-study-preview-notice]")) {
frontend/wrapper-ui/app.js:3071:    notice.setAttribute("data-study-preview-notice", "true");
frontend/wrapper-ui/app.js:3074:      <p>This shared-layout preview is read-only. Use <a href="/study">the live Study page</a> to create decks, add cards, or review cards.</p>
frontend/wrapper-ui/app.js:3081:function studyPreviewSetText(id, value) {
frontend/wrapper-ui/app.js:3086:function studyPreviewEscape(value) {
frontend/wrapper-ui/app.js:3096:function studyPreviewNormalizeDifficulty(card) {
frontend/wrapper-ui/app.js:3120:function studyPreviewPercent(value) {
frontend/wrapper-ui/app.js:3124:function studyPreviewCardArray(data) {
frontend/wrapper-ui/app.js:3133:function renderStudyWrapperPreviewDeckSummary(deck) {
frontend/wrapper-ui/app.js:3147:    <strong>${studyPreviewEscape(deck.title)}</strong>
frontend/wrapper-ui/app.js:3148:    <p>${studyPreviewEscape(deck.description || "")}</p>
frontend/wrapper-ui/app.js:3172:    const res = await fetch("/api/study/decks", {
frontend/wrapper-ui/app.js:3180:    if (!res.ok) throw new Error(`/api/study/decks HTTP ${res.status}: ${text.slice(0, 160)}`);
frontend/wrapper-ui/app.js:3192:    console.error("[study-wrapper-preview] create deck failed", error);
frontend/wrapper-ui/app.js:3200:const studyPreviewReviewState = {
frontend/wrapper-ui/app.js:3215:    const res = await fetch(`/api/study/cards/${encodeURIComponent(cardId)}/reviews`, {
frontend/wrapper-ui/app.js:3227:      throw new Error(`/api/study/cards/${cardId}/reviews HTTP ${res.status}: ${text.slice(0, 160)}`);
frontend/wrapper-ui/app.js:3230:    studyPreviewReviewState.currentIndex += 1;
frontend/wrapper-ui/app.js:3231:    studyPreviewReviewState.showingAnswer = false;
frontend/wrapper-ui/app.js:3237:    renderStudyWrapperPreviewReviewCard();
frontend/wrapper-ui/app.js:3241:    console.error("[study-wrapper-preview] review submit failed", error);
frontend/wrapper-ui/app.js:3248:function renderStudyWrapperPreviewReviewCard() {
frontend/wrapper-ui/app.js:3252:  const card = studyPreviewReviewState.queue[studyPreviewReviewState.currentIndex];
frontend/wrapper-ui/app.js:3263:  const answerBlock = studyPreviewReviewState.showingAnswer
frontend/wrapper-ui/app.js:3267:        <p>${studyPreviewEscape(card.answer || "No answer saved.")}</p>
frontend/wrapper-ui/app.js:3268:        ${card.explanation ? `<p class="muted">${studyPreviewEscape(card.explanation)}</p>` : ""}
frontend/wrapper-ui/app.js:3275:      <strong>${studyPreviewEscape(card.question || "Untitled card")}</strong>
frontend/wrapper-ui/app.js:3277:        ${studyPreviewEscape(card.performance_bucket || card.difficulty || "new")}
frontend/wrapper-ui/app.js:3286:      ${studyPreviewReviewState.showingAnswer ? `
frontend/wrapper-ui/app.js:3287:        <button class="secondary" type="button" id="studyPreviewWrongBtn">Wrong</button>
frontend/wrapper-ui/app.js:3288:        <button class="primary-btn" type="button" id="studyPreviewCorrectBtn">Correct</button>
frontend/wrapper-ui/app.js:3290:        <button class="primary-btn" type="button" id="studyPreviewShowAnswerBtn">Show Answer</button>
frontend/wrapper-ui/app.js:3292:      <button class="secondary" type="button" id="studyPreviewSkipCardBtn">Skip</button>
frontend/wrapper-ui/app.js:3296:  document.getElementById("studyPreviewShowAnswerBtn")?.addEventListener("click", () => {
frontend/wrapper-ui/app.js:3297:    studyPreviewReviewState.showingAnswer = true;
frontend/wrapper-ui/app.js:3298:    renderStudyWrapperPreviewReviewCard();
frontend/wrapper-ui/app.js:3301:  document.getElementById("studyPreviewSkipCardBtn")?.addEventListener("click", () => {
frontend/wrapper-ui/app.js:3302:    studyPreviewReviewState.currentIndex += 1;
frontend/wrapper-ui/app.js:3303:    studyPreviewReviewState.showingAnswer = false;
frontend/wrapper-ui/app.js:3304:    renderStudyWrapperPreviewReviewCard();
frontend/wrapper-ui/app.js:3307:  document.getElementById("studyPreviewWrongBtn")?.addEventListener("click", () => {
frontend/wrapper-ui/app.js:3311:  document.getElementById("studyPreviewCorrectBtn")?.addEventListener("click", () => {
frontend/wrapper-ui/app.js:3332:    const res = await fetch(`/api/study/decks/${encodeURIComponent(deckId)}/review-queue?mode=${encodeURIComponent(mode)}&limit=10`, {
frontend/wrapper-ui/app.js:3339:      throw new Error(`/api/study/decks/${deckId}/review-queue HTTP ${res.status}: ${text.slice(0, 160)}`);
frontend/wrapper-ui/app.js:3343:    studyPreviewReviewState.queue = Array.isArray(data.cards) ? data.cards : [];
frontend/wrapper-ui/app.js:3344:    studyPreviewReviewState.currentIndex = 0;
frontend/wrapper-ui/app.js:3345:    studyPreviewReviewState.showingAnswer = false;
frontend/wrapper-ui/app.js:3348:    studyPreviewSetText("bucketNew", String(buckets.new || 0));
frontend/wrapper-ui/app.js:3349:    studyPreviewSetText("bucketHard", String(buckets.hard || 0));
frontend/wrapper-ui/app.js:3350:    studyPreviewSetText("bucketMedium", String(buckets.medium || 0));
frontend/wrapper-ui/app.js:3351:    studyPreviewSetText("bucketEasy", String(buckets.easy || 0));
frontend/wrapper-ui/app.js:3353:    renderStudyWrapperPreviewReviewCard();
frontend/wrapper-ui/app.js:3357:    console.error("[study-wrapper-preview] review queue failed", error);
frontend/wrapper-ui/app.js:3410:    const res = await fetch(`/api/study/decks/${encodeURIComponent(deckId)}/cards`, {
frontend/wrapper-ui/app.js:3419:      throw new Error(`/api/study/decks/${deckId}/cards HTTP ${res.status}: ${text.slice(0, 160)}`);
frontend/wrapper-ui/app.js:3431:    console.error("[study-wrapper-preview] add card failed", error);
frontend/wrapper-ui/app.js:3495:    renderStudyWrapperPreviewDeckSummary(selected);
frontend/wrapper-ui/app.js:3507:    const res = await fetch(`/api/study/decks/${encodeURIComponent(deckId)}/card-stats`, {
frontend/wrapper-ui/app.js:3513:    if (!res.ok) throw new Error(`/api/study/decks/${deckId}/card-stats HTTP ${res.status}: ${text.slice(0, 120)}`);
frontend/wrapper-ui/app.js:3516:    const cards = studyPreviewCardArray(data);
frontend/wrapper-ui/app.js:3521:      const difficulty = studyPreviewNormalizeDifficulty(card);
frontend/wrapper-ui/app.js:3526:    studyPreviewSetText("bucketNew", String(buckets.new));
frontend/wrapper-ui/app.js:3527:    studyPreviewSetText("bucketHard", String(buckets.hard));
frontend/wrapper-ui/app.js:3528:    studyPreviewSetText("bucketMedium", String(buckets.medium));
frontend/wrapper-ui/app.js:3529:    studyPreviewSetText("bucketEasy", String(buckets.easy));
frontend/wrapper-ui/app.js:3536:          const difficulty = studyPreviewNormalizeDifficulty(card);
frontend/wrapper-ui/app.js:3538:          const accuracy = studyPreviewPercent(card.accuracy);
frontend/wrapper-ui/app.js:3545:              <strong>${studyPreviewEscape(question)}</strong>
frontend/wrapper-ui/app.js:3547:                ${studyPreviewEscape(difficulty)} · ${Number(reviews || 0)} reviews · ${accuracy} accuracy
frontend/wrapper-ui/app.js:3548:                · Wrong streak: ${studyPreviewEscape(wrongStreak)}
frontend/wrapper-ui/app.js:3549:                · Confidence: ${studyPreviewEscape(confidence)}
frontend/wrapper-ui/app.js:3557:    console.error("[study-wrapper-preview] card stats hydrate failed", error);
frontend/wrapper-ui/app.js:3574:      fetch("/api/study/progress", { credentials: "include", cache: "no-store" }),
frontend/wrapper-ui/app.js:3575:      fetch("/api/study/decks", { credentials: "include", cache: "no-store" })
frontend/wrapper-ui/app.js:3581:    if (!progressRes.ok) throw new Error(`/api/study/progress HTTP ${progressRes.status}: ${progressText.slice(0, 120)}`);
frontend/wrapper-ui/app.js:3582:    if (!decksRes.ok) throw new Error(`/api/study/decks HTTP ${decksRes.status}: ${decksText.slice(0, 120)}`);
frontend/wrapper-ui/app.js:3590:    studyPreviewSetText("deckCount", String(overall.deck_count ?? decks.length ?? 0));
frontend/wrapper-ui/app.js:3591:    studyPreviewSetText("cardCount", String(overall.card_count ?? 0));
frontend/wrapper-ui/app.js:3592:    studyPreviewSetText("reviewCount", String(overall.review_count ?? 0));
frontend/wrapper-ui/app.js:3595:    studyPreviewSetText(
frontend/wrapper-ui/app.js:3603:        `<option value="${studyPreviewEscape(deck.id)}">${studyPreviewEscape(deck.title)}</option>`
frontend/wrapper-ui/app.js:3610:    renderStudyWrapperPreviewDeckSummary(selectedDeck);
frontend/wrapper-ui/app.js:3622:            <strong>${studyPreviewEscape(deck.title)}</strong>
frontend/wrapper-ui/app.js:3636:    console.error("[study-wrapper-preview] hydrate failed", error);
frontend/wrapper-ui/app.js:3645:  const style = document.getElementById("studyPreviewStyles");
frontend/wrapper-ui/app.js:3646:  const isLiveStudyRoute = window.location.pathname === "/study";
frontend/wrapper-ui/app.js:3652:    const res = await fetch("/study/study-dashboard.partial.html", {
frontend/wrapper-ui/app.js:3674:            <a class="primary-btn" href="/study">Open Live Study</a>
frontend/wrapper-ui/app.js:3675:            <a class="secondary" href="/study-standalone">Open Standalone Fallback</a>
frontend/wrapper-ui/app.js:3678:        <div class="study-wrapper-preview">
frontend/wrapper-ui/app.js:3701:const queuedChatUiState = {
frontend/wrapper-ui/app.js:3707:function queuedChatEscape(value) {
frontend/wrapper-ui/app.js:3716:function queuedChatSetStatus(text) {
frontend/wrapper-ui/app.js:3717:  const el = document.getElementById("queuedChatStatus");
frontend/wrapper-ui/app.js:3721:function queuedChatRenderMessages() {
frontend/wrapper-ui/app.js:3722:  const el = document.getElementById("queuedChatMessages");
frontend/wrapper-ui/app.js:3725:  if (!queuedChatUiState.messages.length) {
frontend/wrapper-ui/app.js:3730:  el.innerHTML = queuedChatUiState.messages.map((msg) => `
frontend/wrapper-ui/app.js:3732:      <span>${queuedChatEscape(msg.role)}</span>
frontend/wrapper-ui/app.js:3733:      <strong>${queuedChatEscape(msg.content)}</strong>
frontend/wrapper-ui/app.js:3734:      ${msg.detail ? `<p>${queuedChatEscape(msg.detail)}</p>` : ""}
frontend/wrapper-ui/app.js:3739:function renderQueuedChatPage() {
frontend/wrapper-ui/app.js:3740:  /* Stage 16 FC-O45-E-BJ-R4 Companion structural minimal source.
frontend/wrapper-ui/app.js:3741:   * Signed-in Companion renders the minimal chat DOM directly.
frontend/wrapper-ui/app.js:3748:        <p class="eyebrow">Companion</p>
frontend/wrapper-ui/app.js:3749:        <h1>A queued local AI companion for study and support.</h1>
frontend/wrapper-ui/app.js:3751:          Sign in to use the local queued Companion surface. Logged-out users stay on the public summary path.
frontend/wrapper-ui/app.js:3758:    <section class="stage5p8h-companion-page stage16-fc-o45-e-bj-companion-minimal" data-stage5p8h-canonical-companion="true" data-stage16-fc-o45-e-bj="structural-minimal" aria-label="Companion workspace">
frontend/wrapper-ui/app.js:3759:      <section class="stage5p8h-conversation-card" aria-label="Companion conversation">
frontend/wrapper-ui/app.js:3763:          <div id="queuedChatMessages" class="stage5p8h-message-list"></div>
frontend/wrapper-ui/app.js:3766:        <form id="queuedChatForm" class="stage5p8h-message-form">
frontend/wrapper-ui/app.js:3767:          <label for="queuedChatInput">Message</label>
frontend/wrapper-ui/app.js:3768:          <textarea id="queuedChatInput" rows="5" placeholder="Message Companion..."></textarea>
frontend/wrapper-ui/app.js:3771:            <button class="stage5p8h-send-button" type="submit" id="queuedChatSendBtn">Send message</button>
frontend/wrapper-ui/app.js:3772:            <button class="stage5p8h-clear-button" type="button" id="queuedChatClearBtn">Clear</button>
frontend/wrapper-ui/app.js:3784:function queuedChatSessionToken() {
frontend/wrapper-ui/app.js:3796:function queuedChatAuthHeaders() {
frontend/wrapper-ui/app.js:3798:  const token = queuedChatSessionToken();
frontend/wrapper-ui/app.js:3841:      stage5p10fSetText("queuedChatQueueSummary", "Queued");
frontend/wrapper-ui/app.js:3848:      stage5p10fSetText("queuedChatQueueSummary", `${job.position} / ${Math.max(denominator, job.position)}`);
frontend/wrapper-ui/app.js:3854:      stage5p10fSetText("queuedChatQueueSummary", "Running");
frontend/wrapper-ui/app.js:3859:      stage5p10fSetText("queuedChatQueueSummary", "Done");
frontend/wrapper-ui/app.js:3864:      stage5p10fSetText("queuedChatQueueSummary", "Failed");
frontend/wrapper-ui/app.js:3869:      stage5p10fSetText("queuedChatQueueSummary", "Cancelled");
frontend/wrapper-ui/app.js:3876:    stage5p10fSetText("queuedChatQueueSummary", `— / ${total}`);
frontend/wrapper-ui/app.js:3878:    stage5p10fSetText("queuedChatQueueSummary", "0 / 0");
frontend/wrapper-ui/app.js:3893:      headers: queuedChatAuthHeaders()
frontend/wrapper-ui/app.js:3935:async function queuedChatPollJob(jobId) {
frontend/wrapper-ui/app.js:3937:    queuedChatSetStatus(`Waiting for worker... poll ${i + 1}`);
frontend/wrapper-ui/app.js:3942:      headers: queuedChatAuthHeaders()
frontend/wrapper-ui/app.js:4008:    "study session start",
frontend/wrapper-ui/app.js:4009:    "start study session",
frontend/wrapper-ui/app.js:4010:    "start a study session",
frontend/wrapper-ui/app.js:4011:    "study session pause",
frontend/wrapper-ui/app.js:4012:    "pause study session",
frontend/wrapper-ui/app.js:4013:    "study session resume",
frontend/wrapper-ui/app.js:4014:    "resume study session",
frontend/wrapper-ui/app.js:4015:    "study session stop",
frontend/wrapper-ui/app.js:4016:    "stop study session",
frontend/wrapper-ui/app.js:4017:    "end study session",
frontend/wrapper-ui/app.js:4018:    "end the study session",
frontend/wrapper-ui/app.js:4049:  const hasStudy = /\bstudy\b/.test(text);
frontend/wrapper-ui/app.js:4147:function stage5p11qRouteCompanionReviewStyleCommand(message) {
frontend/wrapper-ui/app.js:4222:  const response = await fetch("/api/study/decks", {
frontend/wrapper-ui/app.js:4226:    headers: queuedChatAuthHeaders()
frontend/wrapper-ui/app.js:4276:    .replace(/\bstudy\b/g, " ")
frontend/wrapper-ui/app.js:4360:async function stage5p11pRouteCompanionDeckCommand(message) {
frontend/wrapper-ui/app.js:4417:    text: "study_command_shadow_observation",
frontend/wrapper-ui/app.js:4418:    source: "study",
frontend/wrapper-ui/app.js:4419:    surface: "study_session",
frontend/wrapper-ui/app.js:4420:    activePage: "study",
frontend/wrapper-ui/app.js:4423:  const response = await fetch("/api/study/session/command", {
frontend/wrapper-ui/app.js:4426:    headers: queuedChatAuthHeaders(),
frontend/wrapper-ui/app.js:4479:async function stage5p11iRouteCompanionStudyCommand(message) {
frontend/wrapper-ui/app.js:4481:  const styleRoute = stage5p11qRouteCompanionReviewStyleCommand(message);
frontend/wrapper-ui/app.js:4492:  const deckRoute = await stage5p11pRouteCompanionDeckCommand(message);
frontend/wrapper-ui/app.js:4506:  if (/\bstart\b/.test(normalized) && /\bstudy\b/.test(normalized) && deckId) {
frontend/wrapper-ui/app.js:4521:  const response = await fetch("/api/study/session/command", {
frontend/wrapper-ui/app.js:4524:    headers: queuedChatAuthHeaders(),
frontend/wrapper-ui/app.js:4780:  const response = await fetch("/api/study/session/status", {
frontend/wrapper-ui/app.js:4784:    headers: queuedChatAuthHeaders()
frontend/wrapper-ui/app.js:4797:  const response = await fetch("/api/study/session/command", {
frontend/wrapper-ui/app.js:4800:    headers: queuedChatAuthHeaders(),
frontend/wrapper-ui/app.js:4831:async function stage5p11jRouteCompanionStudyAnswer(message) {
frontend/wrapper-ui/app.js:4872:async function queuedChatSubmit(event) {
frontend/wrapper-ui/app.js:4875:  if (queuedChatUiState.busy) return;
frontend/wrapper-ui/app.js:4877:  const input = document.getElementById("queuedChatInput");
frontend/wrapper-ui/app.js:4878:  const button = document.getElementById("queuedChatSendBtn");
frontend/wrapper-ui/app.js:4882:    queuedChatSetStatus("Enter a message first.");
frontend/wrapper-ui/app.js:4888:    queuedChatUiState.messages.push({ role: "You", content: message });
frontend/wrapper-ui/app.js:4889:    queuedChatRenderMessages();
frontend/wrapper-ui/app.js:4892:    queuedChatUiState.busy = true;
frontend/wrapper-ui/app.js:4894:    queuedChatSetStatus("Handling Study command...");
frontend/wrapper-ui/app.js:4897:      const routed = await stage5p11iRouteCompanionStudyCommand(message);
frontend/wrapper-ui/app.js:4898:      queuedChatUiState.messages.push({
frontend/wrapper-ui/app.js:4903:      queuedChatSetStatus("Study command complete");
frontend/wrapper-ui/app.js:4905:      queuedChatUiState.messages.push({
frontend/wrapper-ui/app.js:4910:      queuedChatSetStatus("Study command failed");
frontend/wrapper-ui/app.js:4912:      queuedChatUiState.busy = false;
frontend/wrapper-ui/app.js:4914:      queuedChatRenderMessages();
frontend/wrapper-ui/app.js:4924:    queuedChatSetStatus("Checking Study answer...");
frontend/wrapper-ui/app.js:4927:      const answerAttempt = await stage5p11jRouteCompanionStudyAnswer(message);
frontend/wrapper-ui/app.js:4930:        queuedChatUiState.messages.push({ role: "You", content: message });
frontend/wrapper-ui/app.js:4931:        queuedChatRenderMessages();
frontend/wrapper-ui/app.js:4934:        queuedChatUiState.busy = true;
frontend/wrapper-ui/app.js:4937:        queuedChatUiState.messages.push({
frontend/wrapper-ui/app.js:4943:        queuedChatSetStatus("Study answer checked");
frontend/wrapper-ui/app.js:4944:        queuedChatUiState.busy = false;
frontend/wrapper-ui/app.js:4946:        queuedChatRenderMessages();
frontend/wrapper-ui/app.js:4950:      queuedChatUiState.messages.push({ role: "You", content: message });
frontend/wrapper-ui/app.js:4951:      queuedChatUiState.messages.push({
frontend/wrapper-ui/app.js:4957:      queuedChatSetStatus("Study answer check failed");
frontend/wrapper-ui/app.js:4958:      queuedChatRenderMessages();
frontend/wrapper-ui/app.js:4962:    queuedChatSetStatus("Ready");
frontend/wrapper-ui/app.js:4966:  queuedChatUiState.busy = true;
frontend/wrapper-ui/app.js:4969:  queuedChatUiState.messages.push({ role: "You", content: message });
frontend/wrapper-ui/app.js:4970:  queuedChatRenderMessages();
frontend/wrapper-ui/app.js:4975:    queuedChatSetStatus("Creating queued job...");
frontend/wrapper-ui/app.js:4980:      headers: queuedChatAuthHeaders(),
frontend/wrapper-ui/app.js:5004:    queuedChatUiState.lastJobId = jobId;
frontend/wrapper-ui/app.js:5006:    if (typeof window.apcCompanionResultReaderSetJobId === "function") {
frontend/wrapper-ui/app.js:5007:      window.apcCompanionResultReaderSetJobId(jobId, {
frontend/wrapper-ui/app.js:5008:        source: "queuedChatSubmit",
frontend/wrapper-ui/app.js:5013:    queuedChatUiState.messages.push({
frontend/wrapper-ui/app.js:5018:    queuedChatRenderMessages();
frontend/wrapper-ui/app.js:5026:    const final = await queuedChatPollJob(jobId);
frontend/wrapper-ui/app.js:5028:    queuedChatUiState.messages.push({
frontend/wrapper-ui/app.js:5033:    queuedChatSetStatus("Complete");
frontend/wrapper-ui/app.js:5037:    queuedChatRenderMessages();
frontend/wrapper-ui/app.js:5039:    queuedChatUiState.messages.push({
frontend/wrapper-ui/app.js:5043:    queuedChatSetStatus("Error");
frontend/wrapper-ui/app.js:5044:    queuedChatRenderMessages();
frontend/wrapper-ui/app.js:5046:    queuedChatUiState.busy = false;
frontend/wrapper-ui/app.js:5052:  queuedChatRenderMessages();
frontend/wrapper-ui/app.js:5054:  const form = document.getElementById("queuedChatForm");
frontend/wrapper-ui/app.js:5056:    form.onsubmit = queuedChatSubmit;
frontend/wrapper-ui/app.js:5059:  const clearBtn = document.getElementById("queuedChatClearBtn");
frontend/wrapper-ui/app.js:5062:      queuedChatUiState.messages = [];
frontend/wrapper-ui/app.js:5063:      queuedChatSetStatus("Ready");
frontend/wrapper-ui/app.js:5064:      queuedChatRenderMessages();
frontend/wrapper-ui/app.js:5103:      path === "/study" ||
frontend/wrapper-ui/app.js:5125:  "/study": {
frontend/wrapper-ui/app.js:5128:    body: "Build decks, add cards, review by difficulty, and track progress over time. Once signed in, this page becomes your personal study dashboard.",
frontend/wrapper-ui/app.js:5136:    eyebrow: "Companion",
frontend/wrapper-ui/app.js:5137:    title: "A queued local AI companion for study and support.",
frontend/wrapper-ui/app.js:5141:      ["Study context", "Future companion features can use allowed study context."],
frontend/wrapper-ui/app.js:5264:    ["Study language", prefs.study_language],
frontend/wrapper-ui/app.js:5266:    ["Explanation depth", prefs.study_explanation_depth],
frontend/wrapper-ui/app.js:5267:    ["Answer strictness", prefs.study_answer_strictness],
frontend/wrapper-ui/app.js:5268:    ["Companion behavior", prefs.companion_behavior],
frontend/wrapper-ui/app.js:5269:    ["Companion tone", prefs.companion_tone],
frontend/wrapper-ui/app.js:5442:        ${renderProfilePreferenceSelect("study_language", "Study language", prefs.study_language, [
frontend/wrapper-ui/app.js:5462:        ${renderProfilePreferenceSelect("study_explanation_depth", "Explanation depth", prefs.study_explanation_depth, [
frontend/wrapper-ui/app.js:5468:        ${renderProfilePreferenceSelect("study_answer_strictness", "Answer strictness", prefs.study_answer_strictness, [
frontend/wrapper-ui/app.js:5474:        ${renderProfilePreferenceSelect("study_session_default_mode", "Study mode", prefs.study_session_default_mode, [
frontend/wrapper-ui/app.js:5479:        ${renderProfilePreferenceSelect("companion_behavior", "Companion behavior", prefs.companion_behavior, [
frontend/wrapper-ui/app.js:5482:          ["study_coach", "Study coach"],
frontend/wrapper-ui/app.js:5485:        ${renderProfilePreferenceSelect("companion_tone", "Companion tone", prefs.companion_tone, [
frontend/wrapper-ui/app.js:5491:        ${renderProfilePreferenceSelect("companion_memory_scope", "Companion memory scope", prefs.companion_memory_scope, [
frontend/wrapper-ui/app.js:5540:    "study_language",
frontend/wrapper-ui/app.js:5542:    "study_explanation_depth",
frontend/wrapper-ui/app.js:5543:    "study_answer_strictness",
frontend/wrapper-ui/app.js:5544:    "study_session_default_mode",
frontend/wrapper-ui/app.js:5695:          <p>Choose what Study, Companion, Calendar providers, and future tools may use as context.</p>
frontend/wrapper-ui/app.js:5714: * Real /study must not mount the old Study wrapper preview mini-app. That
frontend/wrapper-ui/app.js:5716: * one page. Keep the old preview available only at /study-wrapper-preview.
frontend/wrapper-ui/app.js:5722: * /study is a single-owner surface:
frontend/wrapper-ui/app.js:5733:    return path === "/study" || path.endsWith("/study") || hash.includes("study");
frontend/wrapper-ui/app.js:5759:    "[data-apc-study-tools-panel]",
frontend/wrapper-ui/app.js:5760:    "[data-apc-study-tools-auth-cleanup]"
frontend/wrapper-ui/app.js:5795:      keep.setAttribute("data-apc-study-single-owner", "APC_STUDY_SINGLE_OWNER_FC_O45_C_L");
frontend/wrapper-ui/app.js:5798:    panels[0].setAttribute("data-apc-study-single-owner", "APC_STUDY_SINGLE_OWNER_FC_O45_C_L");
frontend/wrapper-ui/app.js:5889:    const styleId = "apc-study-workspace-polish-fc-o45-c-o";
frontend/wrapper-ui/app.js:5893:    style.setAttribute("data-apc-study-workspace-polish", "APC_STUDY_WORKSPACE_POLISH_FC_O45_C_O");
frontend/wrapper-ui/app.js:5895:      ".study-workspace-card{display:grid;gap:1rem;margin-top:1.25rem;}",
frontend/wrapper-ui/app.js:5896:      ".study-workspace-card h2{margin:0;font-size:1.35rem;}",
frontend/wrapper-ui/app.js:5897:      ".study-workspace-card>.muted{margin-top:-.5rem;}",
frontend/wrapper-ui/app.js:5898:      ".study-workspace-actions{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:1rem;align-items:start;}",
frontend/wrapper-ui/app.js:5899:      ".study-workspace-actions .inline-form{display:grid;gap:.65rem;padding:1rem;border:1px solid rgba(148,163,184,.28);border-radius:14px;background:rgba(15,23,42,.28);}",
frontend/wrapper-ui/app.js:5900:      ".study-workspace-actions label{display:grid;gap:.35rem;font-weight:700;}",
frontend/wrapper-ui/app.js:5901:      ".study-workspace-actions input{width:100%;box-sizing:border-box;border-radius:10px;border:1px solid rgba(148,163,184,.35);padding:.7rem .8rem;background:rgba(15,23,42,.32);color:inherit;}",
frontend/wrapper-ui/app.js:5902:      ".study-workspace-actions button,.study-workspace-card .inline-actions button{border:1px solid rgba(148,163,184,.35);border-radius:999px;padding:.55rem .85rem;font-weight:700;cursor:pointer;background:rgba(59,130,246,.16);color:inherit;}",
frontend/wrapper-ui/app.js:5903:      ".study-workspace-card .mini-summary{display:grid;gap:.7rem;padding:1rem;border:1px solid rgba(148,163,184,.22);border-radius:14px;background:rgba(15,23,42,.18);}",
frontend/wrapper-ui/app.js:5904:      ".study-workspace-card .mini-summary>strong{font-size:1rem;letter-spacing:.01em;}",
frontend/wrapper-ui/app.js:5905:      ".study-workspace-card .metric-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(120px,1fr));gap:.75rem;margin:0;}",
frontend/wrapper-ui/app.js:5906:      ".study-workspace-card .metric-grid dt{font-size:.78rem;text-transform:uppercase;letter-spacing:.06em;opacity:.75;}",
frontend/wrapper-ui/app.js:5907:      ".study-workspace-card .metric-grid dd{margin:0;font-size:1.25rem;font-weight:800;}",
frontend/wrapper-ui/app.js:5908:      ".study-workspace-card .compact-list{display:grid;gap:.65rem;list-style:none;padding:0;margin:0;}",
frontend/wrapper-ui/app.js:5909:      ".study-workspace-card .compact-list li{display:grid;grid-template-columns:minmax(0,1fr) auto;gap:.75rem;align-items:center;padding:.8rem;border:1px solid rgba(148,163,184,.18);border-radius:12px;background:rgba(2,6,23,.16);}",
frontend/wrapper-ui/app.js:5910:      ".study-workspace-card .compact-list strong{display:block;line-height:1.25;}",
frontend/wrapper-ui/app.js:5911:      ".study-workspace-card .compact-list span{display:block;margin-top:.2rem;opacity:.78;line-height:1.35;}",
frontend/wrapper-ui/app.js:5912:      ".study-workspace-card .inline-actions{display:flex;flex-wrap:wrap;gap:.4rem;justify-content:flex-end;}",
frontend/wrapper-ui/app.js:5914:      "@media (max-width:720px){.study-workspace-card .compact-list li{grid-template-columns:1fr;}.study-workspace-card .inline-actions{justify-content:flex-start;}}"
frontend/wrapper-ui/app.js:5948:      return window.location.pathname === "/study" || String(window.location.hash || "").includes("study");
frontend/wrapper-ui/app.js:6008:    ["#apcStudyEarlyToolsPanel", "#apcStudyToolsPanel", "#apcStudyEarlyToolsScratchFcO45CL", "[data-apc-study-tools-panel]", "[data-apc-study-tools-auth-cleanup]"].forEach(function (selector) {
frontend/wrapper-ui/app.js:6040:      panel.className = "card study-tools-card study-workspace-card";
frontend/wrapper-ui/app.js:6041:      panel.setAttribute("data-apc-study-single-owner", MARKER);
frontend/wrapper-ui/app.js:6042:      panel.setAttribute("data-apc-study-tools-panel", "canonical-full-workspace");
frontend/wrapper-ui/app.js:6062:      "<div class=\"study-workspace-actions\">",
frontend/wrapper-ui/app.js:6123:      const actions = "<button type=\"button\" data-study-action=\"select-deck\" data-deck-id=\"" + esc(id) + "\">Select</button><button type=\"button\" data-study-action=\"edit-deck\" data-deck-id=\"" + esc(id) + "\" data-deck-name=\"" + esc(name) + "\">Edit</button><button type=\"button\" data-study-action=\"delete-deck\" data-deck-id=\"" + esc(id) + "\">Delete</button>";
frontend/wrapper-ui/app.js:6161:      const actions = "<button type=\"button\" data-study-action=\"edit-card\" data-card-id=\"" + esc(id) + "\" data-front=\"" + esc(front) + "\" data-back=\"" + esc(back) + "\">Edit</button><button type=\"button\" data-study-action=\"delete-card\" data-card-id=\"" + esc(id) + "\">Delete</button>";
frontend/wrapper-ui/app.js:6190:    const decksResult = await request("/api/study/decks");
frontend/wrapper-ui/app.js:6198:    const progressResult = await request("/api/study/progress");
frontend/wrapper-ui/app.js:6199:    const cardsResult = selectedDeckId ? await request("/api/study/decks/" + encodeURIComponent(selectedDeckId) + "/cards") : { ok: true, data: [] };
frontend/wrapper-ui/app.js:6200:    const statsResult = selectedDeckId ? await request("/api/study/decks/" + encodeURIComponent(selectedDeckId) + "/card-stats") : { ok: true, data: {} };
frontend/wrapper-ui/app.js:6201:    const queueResult = selectedDeckId ? await request("/api/study/decks/" + encodeURIComponent(selectedDeckId) + "/review-queue") : { ok: true, data: [] };
frontend/wrapper-ui/app.js:6228:        const result = await request("/api/study/decks", { method: "POST", body: { name: name } });
frontend/wrapper-ui/app.js:6244:        const result = await request("/api/study/decks/" + encodeURIComponent(selectedDeckId) + "/cards", { method: "POST", body: { front: front, back: back } });
frontend/wrapper-ui/app.js:6253:        const button = event.target.closest("button[data-study-action]");
frontend/wrapper-ui/app.js:6255:        const action = button.dataset.studyAction;
frontend/wrapper-ui/app.js:6265:          let result = await request("/api/study/decks/" + encodeURIComponent(deckId), { method: "PUT", body: { name: name } });
frontend/wrapper-ui/app.js:6266:          if (!result.ok) result = await request("/api/study/decks/" + encodeURIComponent(deckId), { method: "PATCH", body: { name: name } });
frontend/wrapper-ui/app.js:6276:          const result = await request("/api/study/decks/" + encodeURIComponent(deckId), { method: "DELETE" });
frontend/wrapper-ui/app.js:6292:          let result = await request("/api/study/cards/" + encodeURIComponent(cardId), { method: "PUT", body: { front: front.trim(), back: back.trim() } });
frontend/wrapper-ui/app.js:6293:          if (!result.ok) result = await request("/api/study/cards/" + encodeURIComponent(cardId), { method: "PATCH", body: { front: front.trim(), back: back.trim() } });
frontend/wrapper-ui/app.js:6303:          const result = await request("/api/study/cards/" + encodeURIComponent(cardId), { method: "DELETE" });
frontend/wrapper-ui/app.js:6329:      renderPublicFeatureGate("/study");
frontend/wrapper-ui/app.js:6332:        <main class="page" data-apc-study-single-owner="APC_STUDY_SINGLE_OWNER_FC_O45_C_L">
frontend/wrapper-ui/app.js:6347:      class="page clean-study-route"
frontend/wrapper-ui/app.js:6348:      data-apc-study-route-cleanup="APC_STUDY_ROUTE_CLEANUP_FC_O45_C_J"
frontend/wrapper-ui/app.js:6349:      data-apc-study-tools-auth-cleanup="APC_STUDY_TOOLS_AUTH_CLEANUP_FC_O45_C_K"
frontend/wrapper-ui/app.js:6377:      path === "/study" ||
frontend/wrapper-ui/app.js:6408:  const isStudyWrapperRoute = path === "/study-wrapper-preview";
frontend/wrapper-ui/app.js:6412:  const studyPreviewStyle = document.getElementById("studyPreviewStyles");
frontend/wrapper-ui/app.js:6413:  if (studyPreviewStyle) {
frontend/wrapper-ui/app.js:6417:    studyPreviewStyle.disabled = !isStudyWrapperRoute;
frontend/wrapper-ui/app.js:6420:  if (path === "/study") {
frontend/wrapper-ui/app.js:6427:      renderPublicFeatureGate("/study");
frontend/wrapper-ui/app.js:6440:    $("app").innerHTML = renderQueuedChatPage();
frontend/wrapper-ui/app.js:7605:      <p>Send a message if you need account, credit, billing, study, companion, or platform help.</p>
frontend/wrapper-ui/app.js:8355:// requests such as presence, public-status, credits, or study previews fail.
frontend/wrapper-ui/app.js:9242:    if (!helper || typeof helper.queuedChatBuildStatusView !== "function") {
frontend/wrapper-ui/app.js:9278:    const view = helper.queuedChatBuildStatusView(job, elapsedMs);
frontend/wrapper-ui/app.js:9327:    if (!helper || typeof helper.queuedChatBuildStatusView !== "function") {
frontend/wrapper-ui/app.js:9335:    const view = helper.queuedChatBuildStatusView(job || {}, elapsedMs);
frontend/wrapper-ui/app.js:9996:    "/study",
frontend/wrapper-ui/app.js:10010:    if (route === "/study-wrapper-preview") return "/study";
frontend/wrapper-ui/app.js:10280:    if (route === "/study-wrapper-preview") return "/study";
frontend/wrapper-ui/app.js:10369:  const snapshotKey = "stage5o35CompanionQueueSnapshot";
frontend/wrapper-ui/app.js:10377:  function stageRouteLooksCompanion() {
frontend/wrapper-ui/app.js:10391:  function stageNodeMentionsCompanion(root) {
frontend/wrapper-ui/app.js:10406:  function stageHasInteractiveCompanion(root) {
frontend/wrapper-ui/app.js:10412:    return stageNodeMentionsCompanion(root) && (hasMessageControl || hasButton);
frontend/wrapper-ui/app.js:10473:    if (window.__stage5o35CompanionFetchObserver || typeof window.fetch !== "function") return;
frontend/wrapper-ui/app.js:10482:    window.__stage5o35CompanionFetchObserver = true;
frontend/wrapper-ui/app.js:10521:    // Prevent Companion card text mutations from retriggering the enhancer in a rapid loop.
frontend/wrapper-ui/app.js:10554:        input.setAttribute("placeholder", "Message Companion...");
frontend/wrapper-ui/app.js:10573:  function stageEnhanceCompanion() {
frontend/wrapper-ui/app.js:10574:    if (!stageRouteLooksCompanion()) return;
frontend/wrapper-ui/app.js:10577:    // The Companion page now renders the polished layout directly in renderQueuedChatPage.
frontend/wrapper-ui/app.js:10588:    // Throttle enhancement so Companion does not appear to constantly refresh.
frontend/wrapper-ui/app.js:10595:    if (!stageHasInteractiveCompanion(root)) return;
frontend/wrapper-ui/app.js:10611:    shell.setAttribute("aria-label", "Companion workspace");
frontend/wrapper-ui/app.js:10617:      '<p class="stage5o35-eyebrow">Companion</p>',
frontend/wrapper-ui/app.js:10619:      '<p>Talk with your local Companion while the queue handles work safely behind the scenes.</p>',
frontend/wrapper-ui/app.js:10657:      '<div class="stage5o35-card-title-row"><h2>Companion status</h2><span class="stage5o35-live-dot"></span></div>',
frontend/wrapper-ui/app.js:10678:      '<p>Use the Study phrases above to control sessions through Companion.</p>',
frontend/wrapper-ui/app.js:10700:      stageEnhanceCompanion();
frontend/wrapper-ui/app.js:10725:  const cardId = "stage5p8a-study-session-status-card";
frontend/wrapper-ui/app.js:10732:    return path === "/study" || path.endsWith("/study") || hash.includes("study");
frontend/wrapper-ui/app.js:10864:    card.className = "stage5p8a-study-session-card";
frontend/wrapper-ui/app.js:10867:      '<div class="stage5p8a-study-session-head">',
frontend/wrapper-ui/app.js:10875:      '<div class="stage5p8a-study-session-grid">',
frontend/wrapper-ui/app.js:10889:      '<p class="stage5p8a-study-session-note">Use the session actions below, or use natural Study phrases in Companion.</p>'
frontend/wrapper-ui/app.js:10917:      const response = await fetch("/api/study/session/status", {
frontend/wrapper-ui/app.js:11034:  const cardId = "stage5p8a-study-session-status-card";
frontend/wrapper-ui/app.js:11035:  const controlsClass = "stage5p8c-study-session-controls";
frontend/wrapper-ui/app.js:11044:    return path === "/study" || path.endsWith("/study") || hash.includes("study");
frontend/wrapper-ui/app.js:11181:      const response = await fetch("/api/study/session/status", {
frontend/wrapper-ui/app.js:11261:      const response = await fetch("/api/study/session/start", {
frontend/wrapper-ui/app.js:11294:      const response = await fetch("/api/study/session/command", {
frontend/wrapper-ui/app.js:11340:    const note = card.querySelector(".stage5p8a-study-session-note");
frontend/wrapper-ui/app.js:11408:  const statusCardId = "stage5p8a-study-session-status-card";
frontend/wrapper-ui/app.js:11409:  const selectorClass = "stage5p9a-study-deck-selector";
frontend/wrapper-ui/app.js:11416:    return path === "/study" || path.endsWith("/study") || hash.includes("study");
frontend/wrapper-ui/app.js:11515:      data.study_decks,
frontend/wrapper-ui/app.js:11516:      data.studyDecks
frontend/wrapper-ui/app.js:11628:      const response = await fetch("/api/study/decks", {
frontend/wrapper-ui/app.js:11770:    "study-card-action"
frontend/wrapper-ui/app.js:12097:        panel.setAttribute("data-apc-public-study-hidden", "true");
frontend/wrapper-ui/app.js:12108:        panel.setAttribute("data-apc-public-study-hidden", "true");
frontend/wrapper-ui/app.js:12151:  const PANEL_ID = "apc-study-signed-in-tools-fc-o45-c-c";
frontend/wrapper-ui/app.js:12226:      const isLargePageShell = t.includes("Companion") && t.includes("Profile") && t.includes("System") && t.length > 600;
frontend/wrapper-ui/app.js:12229:        el.setAttribute("data-apc-study-legacy-hidden", MARKER);
frontend/wrapper-ui/app.js:12254:    panel.className = "card apc-study-tools";
frontend/wrapper-ui/app.js:12303:      return `<li><button type="button" class="secondary apc-study-deck-choice${active}" data-apc-study-deck-id="${esc(deck.id)}">${title}</button> <span class="muted">${esc(count)} cards</span></li>`;
frontend/wrapper-ui/app.js:12312:    panel.querySelectorAll("[data-apc-study-deck-id]").forEach((btn) => {
frontend/wrapper-ui/app.js:12314:        lastDeckId = btn.getAttribute("data-apc-study-deck-id");
frontend/wrapper-ui/app.js:12402:    const decksResult = await apiJson("/api/study/decks");
frontend/wrapper-ui/app.js:12412:    const progress = await apiJson("/api/study/progress");
frontend/wrapper-ui/app.js:12423:    const cards = await apiJson(`/api/study/decks/${encodeURIComponent(deckId)}/cards`);
frontend/wrapper-ui/app.js:12430:    const review = await apiJson(`/api/study/decks/${encodeURIComponent(deckId)}/review-queue`);
frontend/wrapper-ui/app.js:13512: * Signed-in Companion auth validation test path.
frontend/wrapper-ui/app.js:13515: * It also removes the direct Study tools box from the Companion page; the
frontend/wrapper-ui/app.js:13516: * Companion should use Study tools internally, not expose setup controls here.
frontend/wrapper-ui/app.js:13518:(function apcCompanionAuthValidateFcO45ES() {
frontend/wrapper-ui/app.js:13523:  const HEADER_NAME = "X-APC-Companion-Auth-Validate-Only";
frontend/wrapper-ui/app.js:13531:  function isCompanionPage() {
frontend/wrapper-ui/app.js:13533:    return bodyText.includes("Companion") &&
frontend/wrapper-ui/app.js:13535:       bodyText.includes("Chat with your Companion"));
frontend/wrapper-ui/app.js:13539:    if (!isCompanionPage()) return;
frontend/wrapper-ui/app.js:13554:          text.includes("Companion status") ||
frontend/wrapper-ui/app.js:13555:          text.includes("Chat with your Companion") ||
frontend/wrapper-ui/app.js:13628:      result.textContent = "Checking signed-in Companion auth without queue write...";
frontend/wrapper-ui/app.js:13652:          ? "PASS: signed-in Companion auth validated; queue_write=false."
frontend/wrapper-ui/app.js:13665:    if (!isCompanionPage()) return;
frontend/wrapper-ui/app.js:13679:    title.textContent = "Companion auth test";
frontend/wrapper-ui/app.js:13683:    text.textContent = "Checks your signed-in Companion connection without creating a queue job.";
frontend/wrapper-ui/app.js:13687:    button.textContent = "Run Companion auth test";
frontend/wrapper-ui/app.js:13701:    const companionHeading = anchors.find((h) => visibleText(h).trim() === "Companion");
frontend/wrapper-ui/app.js:13702:    const statusHeading = anchors.find((h) => visibleText(h).includes("Companion status"));
frontend/wrapper-ui/app.js:13741:  function isCompanionPage() {
frontend/wrapper-ui/app.js:13743:    return bodyText.includes("Companion") &&
frontend/wrapper-ui/app.js:13745:       bodyText.includes("Chat with your Companion"));
frontend/wrapper-ui/app.js:13802:    const companionHeading = anchors.find((h) => visibleText(h).trim() === "Companion");
frontend/wrapper-ui/app.js:13803:    const statusHeading = anchors.find((h) => visibleText(h).includes("Companion status"));
frontend/wrapper-ui/app.js:13813:    lines.push("PASS: Companion result read path returned a result.");
frontend/wrapper-ui/app.js:13849:        "Latest submitted Companion job id: " + value +
frontend/wrapper-ui/app.js:13855:  window.apcCompanionResultReaderSetJobId = setReaderJobId;
frontend/wrapper-ui/app.js:13856:  window.apcCompanionResultReaderLatestJobId = readLatestSubmittedJobId;
frontend/wrapper-ui/app.js:13863:      output.textContent = "Enter a positive Companion job id.";
frontend/wrapper-ui/app.js:13869:    output.textContent = "Reading Companion result for job " + jobId + "...";
frontend/wrapper-ui/app.js:13876:          "X-APC-Companion-Result-Read-Only": "FC-O45-E-AA"
frontend/wrapper-ui/app.js:13880:          message: "FC-O45-E-AC read Companion job result by job id.",
frontend/wrapper-ui/app.js:13915:    if (!isCompanionPage()) return;
frontend/wrapper-ui/app.js:13925:    title.textContent = "Companion result reader";
frontend/wrapper-ui/app.js:13929:    desc.textContent = "Read a completed Companion job result by job id. This is signed-in, owner-scoped, read-only, and does not create jobs or run models.";
frontend/wrapper-ui/app.js:13958:      ? "Latest submitted Companion job id: " + latestSubmittedJobId + "\nClick Read result to check this job without creating another job."
frontend/wrapper-ui/app.js:13959:      : "Enter a Companion job id, then click Read result.";
frontend/wrapper-ui/app.js:13999: * Stage 16 FC-O45-E-AS Companion Immersion Mode scaffold.
frontend/wrapper-ui/app.js:14002: * models, and does not create jobs. It gives the Companion UI a small
frontend/wrapper-ui/app.js:14096:function renderCompanionImmersionPanel(context = {}) {
frontend/wrapper-ui/app.js:14126:  window.apcCompanionImmersion = Object.freeze({
frontend/wrapper-ui/app.js:14132:    renderPanel: renderCompanionImmersionPanel,
frontend/wrapper-ui/app.js:14138: * Stage 16 FC-O45-E-AT Companion Immersion visible panel source wiring.
frontend/wrapper-ui/app.js:14142: * it observes the existing Companion queued-chat flow and renders a lightweight
frontend/wrapper-ui/app.js:14153:/* Stage 16 FC-O45-E-BJ-R4 Companion structural minimal early flag.
frontend/wrapper-ui/app.js:14154: * Must be defined before old Companion runtime IIFEs so they skip before mutating the DOM.
frontend/wrapper-ui/app.js:14157:  window.__apcCompanionStructuralMinimalMode = true;
frontend/wrapper-ui/app.js:14160:(function stage16FcO45EAtWireCompanionImmersionPanel() {
frontend/wrapper-ui/app.js:14161:  if (window.__apcCompanionStructuralMinimalMode) {
frontend/wrapper-ui/app.js:14162:    window.__stage16FcO45EAtWireCompanionImmersionPanelSkippedForStructuralMinimalMode = true;
frontend/wrapper-ui/app.js:14166:  if (typeof window === "undefined" || window.__apcCompanionImmersionVisiblePanelInstalled) return;
frontend/wrapper-ui/app.js:14167:  window.__apcCompanionImmersionVisiblePanelInstalled = true;
frontend/wrapper-ui/app.js:14177:    worker: "Companion queue worker",
frontend/wrapper-ui/app.js:14180:  function companionImmersionIsCompanionRoute() {
frontend/wrapper-ui/app.js:14198:    if (!companionImmersionIsCompanionRoute()) return null;
frontend/wrapper-ui/app.js:14207:    const anchorCard = anchor?.closest?.("section,.summary-box,.feature-card,.clean-card,.study-card,.companion-card,.route-card,.panel,div");
frontend/wrapper-ui/app.js:14245:    if (!companionImmersionIsCompanionRoute()) return;
frontend/wrapper-ui/app.js:14247:    const api = window.apcCompanionImmersion;
frontend/wrapper-ui/app.js:14339:    const api = window.apcCompanionImmersion;
frontend/wrapper-ui/app.js:14362:    if (window.__apcCompanionImmersionFetchObserverInstalled) return;
frontend/wrapper-ui/app.js:14363:    window.__apcCompanionImmersionFetchObserverInstalled = true;
frontend/wrapper-ui/app.js:14368:    window.fetch = async function apcCompanionImmersionObservedFetch(input, init = {}) {
frontend/wrapper-ui/app.js:14416:  window.apcCompanionImmersionRuntime = Object.freeze({
frontend/wrapper-ui/app.js:14427: * Stage 16 FC-O45-E-AZ Companion Immersion primary workspace placement.
frontend/wrapper-ui/app.js:14430: * - Move the visible Immersion panel into the main Companion workspace instead of leaving it above the page.
frontend/wrapper-ui/app.js:14436:(function stage16FcO45EAzCompanionImmersionPrimaryWorkspace() {
frontend/wrapper-ui/app.js:14437:  if (window.__apcCompanionStructuralMinimalMode) {
frontend/wrapper-ui/app.js:14438:    window.__stage16FcO45EAzCompanionImmersionPrimaryWorkspaceSkippedForStructuralMinimalMode = true;
frontend/wrapper-ui/app.js:14442:  if (window.__stage16FcO45EAzCompanionImmersionPrimaryWorkspaceInstalled) {
frontend/wrapper-ui/app.js:14445:  window.__stage16FcO45EAzCompanionImmersionPrimaryWorkspaceInstalled = true;
frontend/wrapper-ui/app.js:14447:  const AZ_MARKER = "stage16FcO45EAzCompanionImmersionPrimaryWorkspace";
frontend/wrapper-ui/app.js:14464:  function findCompanionWorkspace() {
frontend/wrapper-ui/app.js:14499:    const workspace = findCompanionWorkspace();
frontend/wrapper-ui/app.js:14510:      primaryHost.setAttribute("aria-label", "Companion Immersion");
frontend/wrapper-ui/app.js:14539:    const workspace = findCompanionWorkspace();
frontend/wrapper-ui/app.js:14544:      if (text === "Companion status" || text === "How this works" || text === "Study phrases") {
frontend/wrapper-ui/app.js:14561:  function applyCompanionImmersionPrimaryWorkspace() {
frontend/wrapper-ui/app.js:14573:      applyCompanionImmersionPrimaryWorkspace();
frontend/wrapper-ui/app.js:14585:  window.apcCompanionImmersionPrimaryWorkspace = Object.freeze({
frontend/wrapper-ui/app.js:14587:    apply: applyCompanionImmersionPrimaryWorkspace,
frontend/wrapper-ui/app.js:14596: * Stage 16 FC-O45-E-BB Companion clean chat workspace.
frontend/wrapper-ui/app.js:14599: * - Hide Companion auth test, Companion status, How this works, Study phrases, and Companion result reader from the primary user flow.
frontend/wrapper-ui/app.js:14600: * - Remove the debug/product header feel from the Companion page.
frontend/wrapper-ui/app.js:14601: * - Rename the chat card to "Chat with your Companion".
frontend/wrapper-ui/app.js:14602: * - Add Enter-to-send for the Companion message box while preserving Shift+Enter for a newline.
frontend/wrapper-ui/app.js:14605:(function stage16FcO45EBbCompanionCleanChatWorkspace() {
frontend/wrapper-ui/app.js:14606:  if (window.__apcCompanionStructuralMinimalMode) {
frontend/wrapper-ui/app.js:14607:    window.__stage16FcO45EBbCompanionCleanChatWorkspaceSkippedForStructuralMinimalMode = true;
frontend/wrapper-ui/app.js:14611:  if (window.__stage16FcO45EBbCompanionCleanChatWorkspaceInstalled) {
frontend/wrapper-ui/app.js:14614:  window.__stage16FcO45EBbCompanionCleanChatWorkspaceInstalled = true;
frontend/wrapper-ui/app.js:14616:  const BB_MARKER = "stage16FcO45EBbCompanionCleanChatWorkspace";
frontend/wrapper-ui/app.js:14669:  function cleanCompanionChrome() {
frontend/wrapper-ui/app.js:14670:    hideBlockByContent("Checks your signed-in Companion connection without creating a queue job.", "companion-auth-test");
frontend/wrapper-ui/app.js:14671:    hideBlockByContent("Read a completed Companion job result by job id.", "companion-result-reader");
frontend/wrapper-ui/app.js:14673:    hideBlockByContent("Use natural phrases with Companion to control Study sessions.", "study-phrases");
frontend/wrapper-ui/app.js:14674:    hideBlockByContent("Companion status Status Ready Queue", "companion-status");
frontend/wrapper-ui/app.js:14677:    hideExactTextElement("Talk with your local Companion while the queue handles work safely behind the scenes.", "supportive-chat-description");
frontend/wrapper-ui/app.js:14680:    renameText("Start a Companion conversation", "Chat with your Companion");
frontend/wrapper-ui/app.js:14681:    renameText("Start a companion conversation", "Chat with your Companion");
frontend/wrapper-ui/app.js:14696:  function findCompanionMessageField() {
frontend/wrapper-ui/app.js:14718:    const field = findCompanionMessageField();
frontend/wrapper-ui/app.js:14747:    cleanCompanionChrome();
frontend/wrapper-ui/app.js:14769:  window.apcCompanionCleanChatWorkspace = Object.freeze({
frontend/wrapper-ui/app.js:14780: * Stage 16 FC-O45-E-BD Companion hard-clean visible workspace.
frontend/wrapper-ui/app.js:14787: * - Chat with your Companion
frontend/wrapper-ui/app.js:14794: * - Companion auth test
frontend/wrapper-ui/app.js:14796: * - Companion status
frontend/wrapper-ui/app.js:14799: * - Companion result reader
frontend/wrapper-ui/app.js:14801:(function stage16FcO45EBdCompanionHardCleanVisibleWorkspace() {
frontend/wrapper-ui/app.js:14802:  if (window.__apcCompanionStructuralMinimalMode) {
frontend/wrapper-ui/app.js:14803:    window.__stage16FcO45EBdCompanionHardCleanVisibleWorkspaceSkippedForStructuralMinimalMode = true;
frontend/wrapper-ui/app.js:14807:  if (window.__stage16FcO45EBdCompanionHardCleanVisibleWorkspaceInstalled) {
frontend/wrapper-ui/app.js:14810:  window.__stage16FcO45EBdCompanionHardCleanVisibleWorkspaceInstalled = true;
frontend/wrapper-ui/app.js:14812:  const BD_MARKER = "stage16FcO45EBdCompanionHardCleanVisibleWorkspace";
frontend/wrapper-ui/app.js:14818:        "Companion auth test",
frontend/wrapper-ui/app.js:14819:        "Checks your signed-in Companion connection without creating a queue job."
frontend/wrapper-ui/app.js:14826:        "Talk with your local Companion while the queue handles work safely behind the scenes.",
frontend/wrapper-ui/app.js:14839:        "Companion status",
frontend/wrapper-ui/app.js:14840:        "Worker Companion queue worker Model fallback: qwen2.5:0.5b"
frontend/wrapper-ui/app.js:14851:      reason: "study-phrases",
frontend/wrapper-ui/app.js:14854:        "Use natural phrases with Companion to control Study sessions."
frontend/wrapper-ui/app.js:14860:        "Companion result reader",
frontend/wrapper-ui/app.js:14861:        "Read a completed Companion job result by job id.",
frontend/wrapper-ui/app.js:14862:        "Latest submitted Companion job id"
frontend/wrapper-ui/app.js:14873:    return text.includes("Chat with your Companion") ||
frontend/wrapper-ui/app.js:14942:        "Companion auth test",
frontend/wrapper-ui/app.js:14944:        "Talk with your local Companion while the queue handles work safely behind the scenes.",
frontend/wrapper-ui/app.js:14948:        "Companion result reader"
frontend/wrapper-ui/app.js:14961:      if (text === "Start a Companion conversation" || text === "Start a companion conversation") {
frontend/wrapper-ui/app.js:14962:        node.textContent = "Chat with your Companion";
frontend/wrapper-ui/app.js:14973:    if (window.apcCompanionCleanChatWorkspace && typeof window.apcCompanionCleanChatWorkspace.installEnterToSend === "function") {
frontend/wrapper-ui/app.js:14974:      window.apcCompanionCleanChatWorkspace.installEnterToSend();
frontend/wrapper-ui/app.js:15003:  window.apcCompanionHardCleanWorkspace = Object.freeze({
frontend/wrapper-ui/app.js:15014: * Stage 16 FC-O45-E-BF Companion minimal chat source.
frontend/wrapper-ui/app.js:15017: * - Remove the remaining "Listening / Debug details / Companion" chrome from the primary Companion flow.
frontend/wrapper-ui/app.js:15018: * - Remove the extra "Chat with your Companion" heading from the card.
frontend/wrapper-ui/app.js:15029:(function stage16FcO45EBfCompanionMinimalChatSource() {
frontend/wrapper-ui/app.js:15030:  if (window.__apcCompanionStructuralMinimalMode) {
frontend/wrapper-ui/app.js:15031:    window.__stage16FcO45EBfCompanionMinimalChatSourceSkippedForStructuralMinimalMode = true;
frontend/wrapper-ui/app.js:15035:  if (window.__stage16FcO45EBfCompanionMinimalChatSourceInstalled) {
frontend/wrapper-ui/app.js:15038:  window.__stage16FcO45EBfCompanionMinimalChatSourceInstalled = true;
frontend/wrapper-ui/app.js:15040:  const BF_MARKER = "stage16FcO45EBfCompanionMinimalChatSource";
frontend/wrapper-ui/app.js:15104:  function hideCompanionPageHeaderChrome() {
frontend/wrapper-ui/app.js:15105:    hideExactLooseText("Companion", "page-companion-heading");
frontend/wrapper-ui/app.js:15107:    hideExactLooseText("Talk with your local Companion while the queue handles work safely behind the scenes.", "supportive-chat-description");
frontend/wrapper-ui/app.js:15112:    hideExactLooseText("Chat with your Companion", "extra-chat-heading");
frontend/wrapper-ui/app.js:15128:    if (window.apcCompanionCleanChatWorkspace && typeof window.apcCompanionCleanChatWorkspace.installEnterToSend === "function") {
frontend/wrapper-ui/app.js:15129:      window.apcCompanionCleanChatWorkspace.installEnterToSend();
frontend/wrapper-ui/app.js:15135:    hideCompanionPageHeaderChrome();
frontend/wrapper-ui/app.js:15158:  window.apcCompanionMinimalChatWorkspace = Object.freeze({
frontend/wrapper-ui/app.js:15168: * Stage 16 FC-O45-E-BH Companion dedupe minimal visible source.
frontend/wrapper-ui/app.js:15184:(function stage16FcO45EBhCompanionDedupeMinimalVisibleSource() {
frontend/wrapper-ui/app.js:15185:  if (window.__apcCompanionStructuralMinimalMode) {
frontend/wrapper-ui/app.js:15186:    window.__stage16FcO45EBhCompanionDedupeMinimalVisibleSourceSkippedForStructuralMinimalMode = true;
frontend/wrapper-ui/app.js:15190:  if (window.__stage16FcO45EBhCompanionDedupeMinimalVisibleSourceInstalled) {
frontend/wrapper-ui/app.js:15193:  window.__stage16FcO45EBhCompanionDedupeMinimalVisibleSourceInstalled = true;
frontend/wrapper-ui/app.js:15195:  const BH_MARKER = "stage16FcO45EBhCompanionDedupeMinimalVisibleSource";
frontend/wrapper-ui/app.js:15262:      "Companion",
frontend/wrapper-ui/app.js:15264:      "Use natural phrases with Companion to control Study sessions.",
frontend/wrapper-ui/app.js:15265:      "Start: “Study session start” or “Start a study session.”",
frontend/wrapper-ui/app.js:15275:      "Use natural phrases with Companion to control Study sessions.",
frontend/wrapper-ui/app.js:15276:      "Start: “Study session start” or “Start a study session.”",
frontend/wrapper-ui/app.js:15280:      if (panel) hideNode(panel, "study-phrases-panel");
frontend/wrapper-ui/app.js:15330:    if (window.apcCompanionCleanChatWorkspace && typeof window.apcCompanionCleanChatWorkspace.installEnterToSend === "function") {
frontend/wrapper-ui/app.js:15331:      window.apcCompanionCleanChatWorkspace.installEnterToSend();
frontend/wrapper-ui/app.js:15359:  window.apcCompanionDedupeMinimalVisible = Object.freeze({
frontend/wrapper-ui/app.js:15371: * Stage 16 FC-O45-E-BJ-R4 Companion structural minimal runtime.
frontend/wrapper-ui/app.js:15373: * The Companion route renders minimal chat DOM directly. This runtime only installs
frontend/wrapper-ui/app.js:15376:(function stage16FcO45EBjR4CompanionStructuralMinimalRuntime() {
frontend/wrapper-ui/app.js:15377:  if (window.__stage16FcO45EBjR4CompanionStructuralMinimalRuntimeInstalled) {
frontend/wrapper-ui/app.js:15380:  window.__stage16FcO45EBjR4CompanionStructuralMinimalRuntimeInstalled = true;
frontend/wrapper-ui/app.js:15383:    const form = document.getElementById("queuedChatForm");
frontend/wrapper-ui/app.js:15384:    const textarea = document.getElementById("queuedChatInput");
frontend/wrapper-ui/app.js:15411:  window.apcCompanionStructuralMinimalWorkspace = Object.freeze({
frontend/wrapper-ui/app.js:15412:    marker: "stage16FcO45EBjR4CompanionStructuralMinimalRuntime",
frontend/wrapper-ui/app.js:15423: * Stage 16 FC-O45-E-BL Companion delegated Enter-to-send source.
frontend/wrapper-ui/app.js:15425: * Fixes route-timing where the Companion tab can render after helper setup.
frontend/wrapper-ui/app.js:15426: * This is delegated on document, so it works for future #queuedChatInput nodes.
frontend/wrapper-ui/app.js:15429:(function stage16FcO45EBlCompanionDelegatedEnterToSend() {
frontend/wrapper-ui/app.js:15430:  if (window.__stage16FcO45EBlCompanionDelegatedEnterToSendInstalled) {
frontend/wrapper-ui/app.js:15433:  window.__stage16FcO45EBlCompanionDelegatedEnterToSendInstalled = true;
frontend/wrapper-ui/app.js:15437:    if (!target || target.id !== "queuedChatInput") {
frontend/wrapper-ui/app.js:15444:    const form = document.getElementById("queuedChatForm");
frontend/wrapper-ui/app.js:15454:      const submit = document.getElementById("queuedChatSendBtn");
frontend/wrapper-ui/app.js:15463:  window.apcCompanionDelegatedEnterToSend = Object.freeze({
frontend/wrapper-ui/app.js:15464:    marker: "stage16FcO45EBlCompanionDelegatedEnterToSend",
frontend/wrapper-ui/app.js:15465:    inputId: "queuedChatInput",
frontend/wrapper-ui/app.js:15466:    formId: "queuedChatForm",
frontend/wrapper-ui/app.js:15467:    sendButtonId: "queuedChatSendBtn",
frontend/wrapper-ui/app.js:15473: * Stage 16 FC-O45-E-BS: Companion result-reader hard-refresh restore.
frontend/wrapper-ui/app.js:15476: * It restores the last queued Companion job id after hard refresh, polls the
frontend/wrapper-ui/app.js:15479:(function stage16FcO45EBsCompanionResultReaderRefreshRestore() {
frontend/wrapper-ui/app.js:15481:  const marker = "stage16FcO45EBsCompanionResultReaderRefreshRestore";
frontend/wrapper-ui/app.js:15485:    jobId: "apcCompanionQueuedChatLastJobId",
frontend/wrapper-ui/app.js:15486:    prompt: "apcCompanionQueuedChatLastPrompt",
frontend/wrapper-ui/app.js:15487:    reply: "apcCompanionQueuedChatLastReply",
frontend/wrapper-ui/app.js:15488:    status: "apcCompanionQueuedChatLastStatus",
frontend/wrapper-ui/app.js:15489:    updatedAt: "apcCompanionQueuedChatLastUpdatedAt"
frontend/wrapper-ui/app.js:15502:  root.stage16FcO45EBvCompanionStableResultPoller = {
frontend/wrapper-ui/app.js:15506:  root.stage16FcO45EBxCompanionFinalRenderWins = {
frontend/wrapper-ui/app.js:15569:    const messagesEl = document.getElementById("queuedChatMessages");
frontend/wrapper-ui/app.js:15636:      document.getElementById("queuedChatMessages") &&
frontend/wrapper-ui/app.js:15637:      document.getElementById("queuedChatForm")
frontend/wrapper-ui/app.js:15642:    const statusEl = document.getElementById("queuedChatStatus");
frontend/wrapper-ui/app.js:15647:    const messagesEl = document.getElementById("queuedChatMessages");
frontend/wrapper-ui/app.js:15667:        role: view.status === "failed" ? "System" : "Companion",
frontend/wrapper-ui/app.js:15840:    const input = document.getElementById("queuedChatInput");
frontend/wrapper-ui/app.js:15902:    if (form && form.id === "queuedChatForm") {
frontend/wrapper-ui/app.js:15909:    const target = event.target && event.target.closest ? event.target.closest("#queuedChatClearBtn, a, button") : null;
frontend/wrapper-ui/app.js:15911:    if (target.id === "queuedChatClearBtn") {
frontend/wrapper-ui/app.js:15941:        if (document.getElementById("queuedChatForm")) {
frontend/wrapper-ui/app.js:15946:      root.stage16FcO45EBvCompanionStableResultPoller.observer = true;
frontend/wrapper-ui/app.js:15949:    root.stage16FcO45EBvCompanionStableResultPoller.observer = false;
edge_controller.py:7247:# Public study decks/cards/progress foundation
edge_controller.py:7249:def _study_init_tables():
edge_controller.py:7255:            CREATE TABLE IF NOT EXISTS study_decks (
edge_controller.py:7270:            CREATE TABLE IF NOT EXISTS study_cards (
edge_controller.py:7283:                FOREIGN KEY(deck_id) REFERENCES study_decks(id)
edge_controller.py:7290:            CREATE TABLE IF NOT EXISTS study_reviews (
edge_controller.py:7301:                FOREIGN KEY(deck_id) REFERENCES study_decks(id),
edge_controller.py:7302:                FOREIGN KEY(card_id) REFERENCES study_cards(id)
edge_controller.py:7308:def _study_current_user_id(request: Request) -> int:
edge_controller.py:7313:def _study_parse_tags(value):
edge_controller.py:7333:def _study_deck_for_user(deck_id: int, user_id: int):
edge_controller.py:7334:    _study_init_tables()
edge_controller.py:7340:            FROM study_decks
edge_controller.py:7352:def _study_card_for_user(card_id: int, user_id: int):
edge_controller.py:7353:    _study_init_tables()
edge_controller.py:7359:            FROM study_cards
edge_controller.py:7371:def _study_card_to_public(row):
edge_controller.py:7398:def _study_init_session_tables():
edge_controller.py:7399:    _study_init_tables()
edge_controller.py:7402:            "CREATE TABLE IF NOT EXISTS study_sessions ("
edge_controller.py:7418:            "FOREIGN KEY(deck_id) REFERENCES study_decks(id), "
edge_controller.py:7419:            "FOREIGN KEY(current_card_id) REFERENCES study_cards(id)"
edge_controller.py:7423:            "CREATE INDEX IF NOT EXISTS idx_study_sessions_user_status "
edge_controller.py:7424:            "ON study_sessions(user_id, status, updated_at)"
edge_controller.py:7428:            "CREATE TABLE IF NOT EXISTS study_session_events ("
edge_controller.py:7438:            "FOREIGN KEY(session_id) REFERENCES study_sessions(id), "
edge_controller.py:7440:            "FOREIGN KEY(deck_id) REFERENCES study_decks(id), "
edge_controller.py:7441:            "FOREIGN KEY(card_id) REFERENCES study_cards(id)"
edge_controller.py:7445:            "CREATE INDEX IF NOT EXISTS idx_study_session_events_session "
edge_controller.py:7446:            "ON study_session_events(session_id, created_at)"
edge_controller.py:7449:            "CREATE INDEX IF NOT EXISTS idx_study_session_events_user "
edge_controller.py:7450:            "ON study_session_events(user_id, created_at)"
edge_controller.py:7456:            "CREATE TABLE IF NOT EXISTS study_user_totals ("
edge_controller.py:7463:            "total_study_seconds INTEGER NOT NULL DEFAULT 0, "
edge_controller.py:7469:            "CREATE TABLE IF NOT EXISTS study_deck_totals ("
edge_controller.py:7477:            "total_study_seconds INTEGER NOT NULL DEFAULT 0, "
edge_controller.py:7481:            "FOREIGN KEY(deck_id) REFERENCES study_decks(id)"
edge_controller.py:7485:            "CREATE INDEX IF NOT EXISTS idx_study_deck_totals_user "
edge_controller.py:7486:            "ON study_deck_totals(user_id, updated_at)"
edge_controller.py:7495:def _study_parse_elapsed_seconds(started_at, ended_at):
edge_controller.py:7513:def _study_blank_total():
edge_controller.py:7520:        "total_study_seconds": 0,
edge_controller.py:7524:def _study_rebuild_cumulative_totals(user_id=None):
edge_controller.py:7528:    Correct/wrong come from study_reviews.
edge_controller.py:7529:    Skipped comes from study_session_events.
edge_controller.py:7530:    Study time comes from completed/stopped study_sessions.
edge_controller.py:7534:    _study_init_session_tables()
edge_controller.py:7550:            user_totals[uid] = _study_blank_total()
edge_controller.py:7558:            deck_totals[key] = _study_blank_total()
edge_controller.py:7573:            FROM study_reviews
edge_controller.py:7606:            FROM study_session_events
edge_controller.py:7631:            FROM study_sessions
edge_controller.py:7642:            seconds = _study_parse_elapsed_seconds(row["started_at"], row["ended_at"])
edge_controller.py:7645:            ut["total_study_seconds"] += seconds
edge_controller.py:7649:                dt["total_study_seconds"] += seconds
edge_controller.py:7652:            conn.execute("DELETE FROM study_user_totals WHERE user_id = ?", (int(user_id),))
edge_controller.py:7653:            conn.execute("DELETE FROM study_deck_totals WHERE user_id = ?", (int(user_id),))
edge_controller.py:7655:            conn.execute("DELETE FROM study_user_totals")
edge_controller.py:7656:            conn.execute("DELETE FROM study_deck_totals")
edge_controller.py:7661:                INSERT INTO study_user_totals (
edge_controller.py:7668:                    total_study_seconds,
edge_controller.py:7680:                    int(total["total_study_seconds"]),
edge_controller.py:7688:                INSERT INTO study_deck_totals (
edge_controller.py:7696:                    total_study_seconds,
edge_controller.py:7709:                    int(total["total_study_seconds"]),
edge_controller.py:7725:def _study_get_cumulative_totals_for_user(user_id):
edge_controller.py:7726:    _study_init_session_tables()
edge_controller.py:7728:    _study_rebuild_cumulative_totals(user_id=int(user_id))
edge_controller.py:7736:            FROM study_user_totals
edge_controller.py:7747:            FROM study_deck_totals t
edge_controller.py:7748:            LEFT JOIN study_decks d
edge_controller.py:7765:            "total_study_seconds": 0,

=== backend DB last completed companion jobs read-only ===
recent_companion_with_results_json=[{"id": 572, "user_id": 16, "job_type": "companion.chat", "prompt": "ask how my day was in 1 sentence", "requested_model": "qwen2.5:0.5b", "status": "completed", "attempts": 1, "last_error": null, "created_at": "2026-06-25T02:59:22.911717+00:00", "updated_at": "2026-06-25T03:04:03.558939+00:00", "result_model": "qwen2.5:0.5b", "response_text": "As an AI language model, I don't have personal experiences or memories like\nlike humans do. However, I'm here to assist you with any questions or infor\ninformation you might need! If you'd like, feel free to ask about your day \nor anything else you want to know.", "result_error": null, "result_created_at": "2026-06-25T03:04:03.558939+00:00"}, {"id": 571, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence after BP2.", "requested_model": "qwen2.5:0.5b", "status": "completed", "attempts": 2, "last_error": null, "created_at": "2026-06-25T02:29:36.806186+00:00", "updated_at": "2026-06-25T02:43:17.792838+00:00", "result_model": "qwen2.5:0.5b", "response_text": "Hello! I'm a text-based AI and don't have an immediate physical form like a\na human can. However, I'm always here to answer your questions or offer ass\nassistance as needed. Please feel free to ask me anything you'd like to kno\nknow.", "result_error": null, "result_created_at": "2026-06-25T02:43:17.792838+00:00"}, {"id": 570, "user_id": 16, "job_type": "companion.chat", "prompt": "ask me how my day is in 1 sentence.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T02:16:12.718709+00:00", "updated_at": "2026-06-25T02:16:12.718709+00:00", "result_model": null, "response_text": null, "result_error": null, "result_created_at": null}, {"id": 569, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:43:16.805622+00:00", "updated_at": "2026-06-25T01:43:16.805622+00:00", "result_model": null, "response_text": null, "result_error": null, "result_created_at": null}, {"id": 568, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello i 1 sentence", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:36:29.420762+00:00", "updated_at": "2026-06-25T01:36:29.420762+00:00", "result_model": null, "response_text": null, "result_error": null, "result_created_at": null}, {"id": 567, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence to me.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.603874+00:00", "updated_at": "2026-06-25T01:15:17.603874+00:00", "result_model": null, "response_text": null, "result_error": null, "result_created_at": null}, {"id": 566, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence to me.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.592859+00:00", "updated_at": "2026-06-25T01:15:17.592859+00:00", "result_model": null, "response_text": null, "result_error": null, "result_created_at": null}, {"id": 565, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence to me.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.580188+00:00", "updated_at": "2026-06-25T01:15:17.580188+00:00", "result_model": null, "response_text": null, "result_error": null, "result_created_at": null}, {"id": 564, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence to me.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.568611+00:00", "updated_at": "2026-06-25T01:15:17.568611+00:00", "result_model": null, "response_text": null, "result_error": null, "result_created_at": null}, {"id": 563, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence to me.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.557061+00:00", "updated_at": "2026-06-25T01:15:17.557061+00:00", "result_model": null, "response_text": null, "result_error": null, "result_created_at": null}, {"id": 562, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence to me.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.544947+00:00", "updated_at": "2026-06-25T01:15:17.544947+00:00", "result_model": null, "response_text": null, "result_error": null, "result_created_at": null}, {"id": 561, "user_id": 16, "job_type": "companion.chat", "prompt": "Say hello in 1 sentence to me.", "requested_model": "mock/no-model", "status": "queued", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:15:17.532838+00:00", "updated_at": "2026-06-25T01:15:17.532838+00:00", "result_model": null, "response_text": null, "result_error": null, "result_created_at": null}]

=== recommended simplification ===
RECOMMENDATION=SHIFT_TO_STUDY_COMPANION_LAST_MESSAGE_MVP

Target behavior:
- Companion page becomes stable, boring, and useful.
- It shows a "Last AI answer" panel from localStorage and/or latest completed Companion job.
- It shows one simple message box.
- It avoids long boot timers, repeated route poking, and complicated restore loops.
- It can include Study action buttons as non-destructive UI placeholders:
  1. Copy answer
  2. Use in Study
  3. Make flashcards
  4. Quiz me
- Until a persistent worker exists, the page should honestly show "Queued — worker not running yet" instead of constantly trying to reload.

Implementation plan:
- CA source patch:
  - Add a stable Study Companion panel.
  - Disable or bypass aggressive restoration/poller behavior.
  - Keep last completed response visible from localStorage.
  - Keep the send form.
  - On submit, store prompt/job id and show queued status.
  - Do not try to auto-refresh the whole page.
- CB deploy:
  - Deploy static app.js + styles.css over restricted VM200 path.
- CC manual validation:
  - Hard refresh: last completed answer stays visible.
  - Send a new message: queued state is stable.
  - No constant reload/disappearing conversation.
```
