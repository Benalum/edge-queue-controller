# Stage 16 FC-O45-E-AQ — Companion to Study Tools Endpoint Routing Contract

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `b322c80`
- Prior tag: `controller-stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure-2026-06-24`

## Scope

This phase is repo/source inventory plus docs/smoke/commit/tag/push only.

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

## Companion queue-worker state carried forward

The Companion browser-submit queue-worker proof is closed.

Proven by the previous checkpoint:

```
normal browser signed-in submit
-> queued companion.chat job
-> transient exact-one queue worker reads that job
-> persona-wrapped real model completion
-> one product-quality result row
-> result-reader-compatible completed Companion job
```

Latest closure target:

- job: `132`
- status: `completed`
- job_type: `companion.chat`
- requested_model: `qwen2.5:0.5b`
- attempts: `1`
- result_rows: `1`
- quality: `quality_pass=true`, `quality_flags=none`

## Goal of Study Tools routing

Connect Companion phrases to existing Study Tools behavior safely.

Initial command phrases visible in the UI:

| Phrase family | Intended action |
|---|---|
| `Study session start` / `Start a study session` | Start or create active study session |
| `Study session pause` | Pause active study session |
| `Study session resume` | Resume paused active study session |
| `Study session stop` | Stop/end active study session |
| `Read the answer` | Reveal/read current answer |
| `Correct` | Mark current card correct |
| `Wrong` | Mark current card wrong |
| `Skip` | Skip current card |

## Routing contract

The Companion Study Tools bridge must be deterministic and owner-scoped.

Required behavior:

1. Accept only signed-in requests.
2. Resolve the authenticated user id before any Study action.
3. Detect only an allowlist of Study command phrases.
4. Route each command phrase to exactly one Study action.
5. Mutate only the authenticated user's Study session/card state.
6. Return a clear Companion confirmation.
7. Refuse ambiguous or unsupported Study commands without mutation.
8. Record whether a Study action mutated state.
9. Never allow Companion text to choose arbitrary endpoint URLs.
10. Never expose admin/system endpoints through Study phrases.
11. Never activate scheduler/timer/persistent workers as part of Study routing.
12. Preserve the existing queue/result-reader path for normal chat messages.

## Recommended first implementation

Do not wire all Study commands at once.

Recommended next phase:

```
FC-O45-E-AR — repo-only Companion Study command router skeleton
```

AR should be source-only and should add a guarded/disabled router function or module that maps phrases to canonical actions, for example:

```
study_session_start
study_session_pause
study_session_resume
study_session_stop
study_answer_read
study_card_correct
study_card_wrong
study_card_skip
```

The router should return a structured decision object and perform no DB writes in AR.

Example decision shape:

```json
{
  "matched": true,
  "action": "study_session_start",
  "mutates": true,
  "requires_auth": true,
  "confidence": "exact_phrase",
  "source": "companion_study_router"
}
```

## Recommended first runtime proof

After AR source-only wiring, the first runtime Study action should be exact-one and approval-gated.

Suggested runtime phase:

```
FC-O45-E-AS — exact-one Companion Study session start proof
```

Suggested approval phrase:

```
APPROVE_FC_O45_E_AS_EXACT_ONE_COMPANION_STUDY_SESSION_START
```

AS should:

1. require a signed-in owner context,
2. target one Study command phrase,
3. mutate only one owner-scoped Study session state,
4. verify before/after Study state,
5. return a Companion confirmation,
6. avoid model generation unless explicitly needed,
7. avoid queue draining,
8. avoid scheduler/timer/persistent workers,
9. avoid deploy/service restart unless a separate deploy gate is approved.

## Non-goals

This phase does not:

- implement Study routing,
- create a Study session,
- mutate Study state,
- run Companion model generation,
- run a queue worker,
- deploy new frontend/backend code,
- start any service/timer/worker.

## Source inventory

```
=== Stage 16 FC-O45-E-AQ Companion Study Tools endpoint/routing contract ===
MUTATION_SCOPE=repo_source_inventory_docs_smoke_commit_tag_push_only
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
expected_head=b322c80
head_now=b322c80
origin_main_now=b322c80
git_preflight=PASS

=== study endpoint and route inventory ===
frontend/study-ui/.wrangler/cache/pages.json:3:  "project_name": "ai-study-dashboard"
frontend/study-ui/app.js:7:  token: "cookie-session",
frontend/study-ui/app.js:9:  decks: [],
frontend/study-ui/app.js:10:  selectedDeckId: "",
frontend/study-ui/app.js:21:    console.warn(`[study-ui] Missing element #${id}; skipped ${eventName} listener.`);
frontend/study-ui/app.js:28:function safeNavigate(url, reason = "study-ui navigation") {
frontend/study-ui/app.js:36:    console.warn(`[study-ui] Blocked legacy login redirect from ${reason}: ${target}`);
frontend/study-ui/app.js:100:  $("studyGrid").classList.remove("hidden");
frontend/study-ui/app.js:109:  $("studyGrid").classList.add("hidden");
frontend/study-ui/app.js:120:    state.token = "cookie-session";
frontend/study-ui/app.js:124:    state.token = "cookie-session";
frontend/study-ui/app.js:126:    localStorage.removeItem("edgeStudyToken");
frontend/study-ui/app.js:152:    state.token = data.session.access_token;
frontend/study-ui/app.js:154:    localStorage.setItem("edgeStudyToken", state.token);
frontend/study-ui/app.js:178:  state.decks = [];
frontend/study-ui/app.js:179:  state.selectedDeckId = "";
frontend/study-ui/app.js:181:  localStorage.removeItem("edgeStudyToken");
frontend/study-ui/app.js:188:    loadDecks()
frontend/study-ui/app.js:191:  if (state.selectedDeckId) {
frontend/study-ui/app.js:197:  const data = await api("/study/progress", {
frontend/study-ui/app.js:202:  $("deckCount").textContent = overall.deck_count ?? 0;
frontend/study-ui/app.js:211:async function loadDecks() {
frontend/study-ui/app.js:212:  const data = await api("/study/decks", {
frontend/study-ui/app.js:216:  state.decks = data.decks || [];
frontend/study-ui/app.js:218:  const select = $("deckSelect");
frontend/study-ui/app.js:219:  const previous = state.selectedDeckId;
frontend/study-ui/app.js:221:  select.innerHTML = `<option value="">No deck selected</option>`;
frontend/study-ui/app.js:223:  for (const deck of state.decks) {
frontend/study-ui/app.js:225:    option.value = String(deck.id);
frontend/study-ui/app.js:226:    option.textContent = `${deck.title} (${deck.card_count || 0} cards)`;
frontend/study-ui/app.js:230:  if (previous && state.decks.some((deck) => String(deck.id) === String(previous))) {
frontend/study-ui/app.js:232:  } else if (state.decks.length) {
frontend/study-ui/app.js:233:    select.value = String(state.decks[0].id);
frontend/study-ui/app.js:234:    state.selectedDeckId = select.value;
frontend/study-ui/app.js:236:    state.selectedDeckId = "";
frontend/study-ui/app.js:239:  renderDeckSummary();
frontend/study-ui/app.js:242:function renderDeckSummary() {
frontend/study-ui/app.js:243:  const deck = state.decks.find((item) => String(item.id) === String(state.selectedDeckId));
frontend/study-ui/app.js:244:  const el = $("deckSummary");
frontend/study-ui/app.js:246:  if (!deck) {
frontend/study-ui/app.js:247:    el.innerHTML = `<p class="muted">Create or select a deck to begin.</p>`;
frontend/study-ui/app.js:251:  const accuracy = deck.accuracy === null || deck.accuracy === undefined
frontend/study-ui/app.js:253:    : `${Math.round(deck.accuracy * 100)}%`;
frontend/study-ui/app.js:256:    <h3>${escapeHtml(deck.title)}</h3>
frontend/study-ui/app.js:257:    <p class="muted">${escapeHtml(deck.description || "No description")}</p>
frontend/study-ui/app.js:259:      <span class="pill">${deck.card_count || 0} cards</span>
frontend/study-ui/app.js:260:      <span class="pill">${deck.total_reviews || 0} reviews</span>
frontend/study-ui/app.js:266:async function createDeck(event) {
frontend/study-ui/app.js:269:  const title = $("deckTitleInput").value.trim();
frontend/study-ui/app.js:270:  const description = $("deckDescriptionInput").value.trim();
frontend/study-ui/app.js:274:  const data = await api("/study/decks", {
frontend/study-ui/app.js:280:  $("deckTitleInput").value = "";
frontend/study-ui/app.js:281:  $("deckDescriptionInput").value = "";
frontend/study-ui/app.js:283:  state.selectedDeckId = String(data.deck.id);
frontend/study-ui/app.js:290:  if (!state.selectedDeckId) {
frontend/study-ui/app.js:291:    alert("Select or create a deck first.");
frontend/study-ui/app.js:297:    answer: $("answerInput").value.trim(),
frontend/study-ui/app.js:303:  if (!payload.question || !payload.answer) return;
frontend/study-ui/app.js:305:  await api(`/study/decks/${state.selectedDeckId}/cards`, {
frontend/study-ui/app.js:312:  $("answerInput").value = "";
frontend/study-ui/app.js:321:  if (!state.selectedDeckId) return;
frontend/study-ui/app.js:323:  const data = await api(`/study/decks/${state.selectedDeckId}/card-stats`, {
frontend/study-ui/app.js:358:          <span class="pill">Wrong streak: ${card.recent_wrong_streak || 0}</span>
frontend/study-ui/app.js:367:  if (!state.selectedDeckId) {
frontend/study-ui/app.js:368:    alert("Select or create a deck first.");
frontend/study-ui/app.js:373:  const data = await api(`/study/decks/${state.selectedDeckId}/review-queue?mode=${encodeURIComponent(mode)}&limit=10`, {
frontend/study-ui/app.js:395:    el.innerHTML = "No cards available in this deck yet.";
frontend/study-ui/app.js:423:      <div class="review-answer">
frontend/study-ui/app.js:425:        ${escapeHtml(card.answer)}
frontend/study-ui/app.js:434:        <button class="secondary" data-review="wrong">Wrong</button>
frontend/study-ui/app.js:435:        <button class="primary" data-review="correct">Correct</button>
frontend/study-ui/app.js:437:      <button class="secondary" id="skipCardBtn">Skip</button>
frontend/study-ui/app.js:449:  const skipCardBtn = $("skipCardBtn");
frontend/study-ui/app.js:450:  if (skipCardBtn) {
frontend/study-ui/app.js:451:    skipCardBtn.addEventListener("click", () => {
frontend/study-ui/app.js:460:      const correct = button.dataset.review === "correct";
frontend/study-ui/app.js:461:      await submitReview(card.id, correct);
frontend/study-ui/app.js:467:  await api(`/study/cards/${cardId}/reviews`, {
frontend/study-ui/app.js:471:      was_correct: wasCorrect,
frontend/study-ui/app.js:511:on("deckForm", "submit", createDeck);
frontend/study-ui/app.js:513:on("deckSelect", "change", async (event) => {
frontend/study-ui/app.js:514:  state.selectedDeckId = event.target.value;
frontend/study-ui/app.js:515:  renderDeckSummary();
frontend/study-ui/app.js:536:  if (false && page === "study" && !state.token) {
frontend/study-ui/app.js:586:  showPage("study");
frontend/study-ui/app.js:597:   Companion study mode
frontend/study-ui/app.js:622:function syncCompanionDeckSelect() {
frontend/study-ui/app.js:623:  const select = $("companionDeckSelect");
frontend/study-ui/app.js:627:  select.innerHTML = `<option value="">No deck selected</option>`;
frontend/study-ui/app.js:629:  for (const deck of state.decks || []) {
frontend/study-ui/app.js:631:    option.value = String(deck.id);
frontend/study-ui/app.js:632:    option.textContent = `${deck.title} (${deck.card_count || 0} cards)`;
frontend/study-ui/app.js:636:  if (previous && state.decks.some((deck) => String(deck.id) === String(previous))) {
frontend/study-ui/app.js:638:  } else if (state.selectedDeckId) {
frontend/study-ui/app.js:639:    select.value = state.selectedDeckId;
frontend/study-ui/app.js:643:const originalLoadDecksForCompanion = loadDecks;
frontend/study-ui/app.js:644:loadDecks = async function patchedLoadDecksForCompanion() {
frontend/study-ui/app.js:645:  await originalLoadDecksForCompanion();
frontend/study-ui/app.js:646:  syncCompanionDeckSelect();
frontend/study-ui/app.js:655:  const deckId = $("companionDeckSelect").value;
frontend/study-ui/app.js:658:  if (!deckId) {
frontend/study-ui/app.js:660:    companionAddMessage("assistant", "Please select a deck first.");
frontend/study-ui/app.js:668:    const data = await api(`/study/decks/${deckId}/review-queue?mode=${encodeURIComponent(mode)}&limit=10`, {
frontend/study-ui/app.js:679:      companionAddMessage("assistant", "This deck does not have cards yet. Add cards on the Study page first.");
frontend/study-ui/app.js:728:  const answer = $("companionAnswerInput").value.trim();
frontend/study-ui/app.js:729:  if (!answer) return;
frontend/study-ui/app.js:731:  companionAddMessage("user", answer);
frontend/study-ui/app.js:735:    const data = await api("/companion/study/grade", {
frontend/study-ui/app.js:740:        user_answer: answer
frontend/study-ui/app.js:744:    if (data.verdict === "correct") {
frontend/study-ui/app.js:750:    if (data.verdict === "incorrect") {
frontend/study-ui/app.js:753:        `Not quite. ${data.feedback}\n\nStored answer: ${data.card.answer}`
frontend/study-ui/app.js:761:      userAnswer: answer,
frontend/study-ui/app.js:767:      `${data.feedback}\n\nStored answer: ${data.card.answer}\n\nShould I mark your answer correct or wrong?`
frontend/study-ui/app.js:772:    companionAddMessage("assistant", `I could not grade that answer: ${err.message}`);
frontend/study-ui/app.js:782:  await api(`/study/cards/${card.id}/reviews`, {
frontend/study-ui/app.js:786:      was_correct: Boolean(wasCorrect),
frontend/study-ui/app.js:792:  companionAddMessage("assistant", wasCorrect ? "Marked correct." : "Marked wrong.");
frontend/study-ui/app.js:801:  if (state.selectedDeckId) {
frontend/study-ui/app.js:834:  const CHAT_KEY = "aiStudyCompanionChat:v1";
frontend/study-ui/app.js:835:  const CALENDAR_KEY = "aiStudyCalendarReminders:v1";
frontend/study-ui/app.js:844:  function studyUiLegacyJobsFallbackEnabled() {
frontend/study-ui/app.js:857:    const keys = ["authToken", "token", "accessToken", "aiStudyToken"];
frontend/study-ui/app.js:899:      data.answer,
frontend/study-ui/app.js:905:      data.result?.answer,
frontend/study-ui/app.js:911:      data.job?.result?.answer,
frontend/study-ui/app.js:1028:    if (studyUiLegacyJobsFallbackEnabled()) {
frontend/study-ui/app.js:1061:    return `Your message was queued as job ${jobId}, but the browser could not fetch the final answer yet. Refresh in a moment or try again.`;
frontend/study-ui/app.js:1065:    let studyHint = "";
frontend/study-ui/app.js:1069:        const selectedDeck = state.decks?.find?.((d) => String(d.id) === String(state.selectedDeckId));
frontend/study-ui/app.js:1072:        studyHint = JSON.stringify({
frontend/study-ui/app.js:1073:          selected_deck: selectedDeck || null,
frontend/study-ui/app.js:1077:            answer: card.answer,
frontend/study-ui/app.js:1079:            correct_reviews: card.correct_reviews,
frontend/study-ui/app.js:1080:            incorrect_reviews: card.incorrect_reviews,
frontend/study-ui/app.js:1089:      "You are the user's AI study companion.",
frontend/study-ui/app.js:1090:      "Use the user's study-card context when provided.",
frontend/study-ui/app.js:1091:      "Do not invent cards or deck details.",
frontend/study-ui/app.js:1092:      "If the user asks what to study, prioritize hard cards, missed cards, and cards with low accuracy.",
frontend/study-ui/app.js:1093:      "Keep answers short, helpful, and actionable.",
frontend/study-ui/app.js:1094:      studyHint ? `STUDY_CONTEXT_JSON: ${studyHint}` : "STUDY_CONTEXT_JSON: unavailable from this page state.",
frontend/study-ui/app.js:1111:    if (studyUiLegacyJobsFallbackEnabled()) {
frontend/study-ui/app.js:1168:        text: "Hi, I am your study companion. Ask me what to study, paste an answer for me to check, or ask me to help make a card.",
frontend/study-ui/app.js:1211:      const answer = await sendCompanionToApi(clean);
frontend/study-ui/app.js:1212:      addCompanionMessage("assistant", answer || "I got a response, but it did not include readable text.");
frontend/study-ui/app.js:1235:    const suggestBtn = document.getElementById("companionStudySuggestBtn");
frontend/study-ui/app.js:1256:        handleCompanionSubmit("What should I study right now based on my cards?");
frontend/study-ui/app.js:1463:/* === Disable old Study auth panel and normalize Home/Study routing === */
frontend/study-ui/app.js:1472:  function hasOldStudyToken() {
frontend/study-ui/app.js:1493:  function showStudyOrAccountLogin() {
frontend/study-ui/app.js:1494:    showPage("study");
frontend/study-ui/app.js:1495:    document.body.dataset.currentPage = "study";
frontend/study-ui/app.js:1529:    if (path === "/study" || path.startsWith("/study/") || hash === "#study") {
frontend/study-ui/app.js:1530:      showStudyOrAccountLogin();
frontend/study-ui/app.js:1563:    if (href.endsWith("#study") || pageLink === "study" || text === "study") {
frontend/study-ui/app.js:1566:      history.pushState(null, "", "#study");
frontend/study-ui/app.js:1567:      showStudyOrAccountLogin();
frontend/study-ui/app.js:1583:    if (window.location.pathname === "/study" || window.location.pathname.startsWith("/study/")) {
frontend/study-ui/app.js:1584:      history.replaceState(null, "", "/study#study");
frontend/study-ui/app.js:1585:      showStudyOrAccountLogin();
frontend/study-ui/app.js:1597:      if (window.location.hash.toLowerCase() === "#study" && !hasOldStudyToken()) {
frontend/study-ui/app.js:1598:        safeNavigate(`${ACCOUNT_LOGIN}?next=${encodeURIComponent("https://alexhartel.com/study")}`, "window.location.href assignment");
frontend/study-ui/app.js:1678:      localStorage.getItem("edgeStudyToken") ||
frontend/study-ui/app.js:1679:      localStorage.getItem("aiStudyToken") ||
frontend/study-ui/app.js:1903:  function forcePrivateStudyPanel() {
frontend/study-ui/app.js:1904:    const onStudyPath =
frontend/study-ui/app.js:1905:      window.location.pathname === "/study" ||
frontend/study-ui/app.js:1906:      window.location.pathname.startsWith("/study/");
frontend/study-ui/app.js:1908:    if (!onStudyPath) return;
frontend/study-ui/app.js:1914:    document.querySelectorAll('[data-page="study"]').forEach((el) => {
frontend/study-ui/app.js:1918:    document.body.dataset.currentPage = "study";
frontend/study-ui/app.js:1921:    if (authLink && localStorage.getItem("edgeStudyToken")) {
frontend/study-ui/app.js:1928:    forcePrivateStudyPanel();
frontend/study-ui/app.js:1929:    setTimeout(forcePrivateStudyPanel, 100);
frontend/study-ui/app.js:1930:    setTimeout(forcePrivateStudyPanel, 500);
frontend/study-ui/app.js:1931:    setTimeout(forcePrivateStudyPanel, 1500);
frontend/study-ui/app.js:1934:  window.addEventListener("load", forcePrivateStudyPanel);
frontend/study-ui/study-dashboard.partial.html:1:<!-- Study dashboard-only partial for wrapper preview. Runtime /study does not use this file yet. -->
frontend/study-ui/study-dashboard.partial.html:2:<section class="panel" data-page="study" data-preview-page="study" id="dashboardPanel">
frontend/study-ui/study-dashboard.partial.html:5:            <p class="eyebrow">Study</p>
frontend/study-ui/study-dashboard.partial.html:12:            <span>Decks</span>
frontend/study-ui/study-dashboard.partial.html:13:            <strong id="deckCount">0</strong>
frontend/study-ui/study-dashboard.partial.html:30:<div class="grid-2" data-page="study" data-preview-page="study" id="studyGrid">
frontend/study-ui/study-dashboard.partial.html:34:              <p class="eyebrow">Decks</p>
frontend/study-ui/study-dashboard.partial.html:35:              <h2>Create / Select Deck</h2>
frontend/study-ui/study-dashboard.partial.html:39:          <form id="deckForm" class="form-grid">
frontend/study-ui/study-dashboard.partial.html:41:              Deck title
frontend/study-ui/study-dashboard.partial.html:42:              <input id="deckTitleInput" type="text" placeholder="Math 316 Review" required />
frontend/study-ui/study-dashboard.partial.html:46:              <textarea id="deckDescriptionInput" placeholder="What is this deck for?"></textarea>
frontend/study-ui/study-dashboard.partial.html:48:            <button class="primary" type="submit">Create Deck</button>
frontend/study-ui/study-dashboard.partial.html:54:            Selected deck
frontend/study-ui/study-dashboard.partial.html:55:            <select id="deckSelect">
frontend/study-ui/study-dashboard.partial.html:56:              <option value="">No deck selected</option>
frontend/study-ui/study-dashboard.partial.html:60:          <div id="deckSummary" class="mini-summary"></div>
frontend/study-ui/study-dashboard.partial.html:79:              <textarea id="answerInput" placeholder="1/s" required></textarea>
frontend/study-ui/study-dashboard.partial.html:107:<section class="panel" data-page="study" data-preview-page="study" id="reviewPanel">
frontend/study-ui/study-dashboard.partial.html:133:          Select a deck and load a review queue.
frontend/study-ui/study-dashboard.partial.html:137:<section class="panel" data-page="study" data-preview-page="study" id="cardsPanel">
frontend/study-ui/study-dashboard.partial.html:140:            <p class="eyebrow">Selected Deck</p>
frontend/study-ui/styles.css:333:.review-answer {
frontend/study-ui/styles.css:563:.companion-answer {
frontend/study-ui/styles.css:577:  .companion-answer {
frontend/study-ui/study-content.partial.html:1:<!-- Study dashboard content partial extracted from standalone Study HTML. Runtime is not using this file yet. -->
frontend/study-ui/study-content.partial.html:5:        <h1>Study Dashboard</h1>
frontend/study-ui/study-content.partial.html:7:          Create decks, add cards, review by difficulty, and track your progress.
frontend/study-ui/study-content.partial.html:31:            <h3>Study smarter</h3>
frontend/study-ui/study-content.partial.html:32:            <p>Create decks, add cards, review by difficulty, and track progress over time.</p>
frontend/study-ui/study-content.partial.html:36:            <p>Chat with your companion, ask what to study, and get help based on your study cards.</p>
frontend/study-ui/study-content.partial.html:41:            <p>Create simple local study reminders while we connect the full backend calendar system.</p>
frontend/study-ui/study-content.partial.html:51:            <p>Study cards are active. Companion now uses the worker proxy and Gemma E4B queue path when available.</p>
frontend/study-ui/study-content.partial.html:55:            <p>Use the Companion tab and ask: “What should I study right now based on my cards?”</p>
frontend/study-ui/study-content.partial.html:69:          emotional support, study help, calendar/reminder help, and safety-aware responses.
frontend/study-ui/study-content.partial.html:96:          Login and registration now happen through the shared account page so Study,
frontend/study-ui/study-content.partial.html:105:      <section class="panel hidden" data-page="study" id="dashboardPanel">
frontend/study-ui/study-content.partial.html:108:            <p class="eyebrow">Study</p>
frontend/study-ui/study-content.partial.html:115:            <span>Decks</span>
frontend/study-ui/study-content.partial.html:116:            <strong id="deckCount">0</strong>
frontend/study-ui/study-content.partial.html:133:      <div class="grid-2 hidden" data-page="study" id="studyGrid">
frontend/study-ui/study-content.partial.html:137:              <p class="eyebrow">Decks</p>
frontend/study-ui/study-content.partial.html:138:              <h2>Create / Select Deck</h2>
frontend/study-ui/study-content.partial.html:142:          <form id="deckForm" class="form-grid">
frontend/study-ui/study-content.partial.html:144:              Deck title
frontend/study-ui/study-content.partial.html:145:              <input id="deckTitleInput" type="text" placeholder="Math 316 Review" required />
frontend/study-ui/study-content.partial.html:149:              <textarea id="deckDescriptionInput" placeholder="What is this deck for?"></textarea>
frontend/study-ui/study-content.partial.html:151:            <button class="primary" type="submit">Create Deck</button>
frontend/study-ui/study-content.partial.html:157:            Selected deck
frontend/study-ui/study-content.partial.html:158:            <select id="deckSelect">
frontend/study-ui/study-content.partial.html:159:              <option value="">No deck selected</option>
frontend/study-ui/study-content.partial.html:163:          <div id="deckSummary" class="mini-summary"></div>
frontend/study-ui/study-content.partial.html:182:              <textarea id="answerInput" placeholder="1/s" required></textarea>
frontend/study-ui/study-content.partial.html:210:      <section class="panel hidden" data-page="study" id="reviewPanel">
frontend/study-ui/study-content.partial.html:236:          Select a deck and load a review queue.
frontend/study-ui/study-content.partial.html:240:      <section class="panel hidden" data-page="study" id="cardsPanel">
frontend/study-ui/study-content.partial.html:243:            <p class="eyebrow">Selected Deck</p>
frontend/study-ui/index.html:6:  <title>AI Study Dashboard | AI Platform Control</title>
frontend/study-ui/index.html:7:  <link rel="stylesheet" href="/study/styles.css" />
frontend/study-ui/index.html:10:  <meta name="description" content="Study cards and local AI learning workspace for AI Platform Control.">
frontend/study-ui/index.html:11:  <meta name="application-name" content="AI Platform Control Study">
frontend/study-ui/index.html:24:        <a class="app-shell-link nav-link" href="https://alexhartel.com/study">Study</a>
frontend/study-ui/index.html:35:        <h1>Study Dashboard</h1>
frontend/study-ui/index.html:37:          Create decks, add cards, review by difficulty, and track your progress.
frontend/study-ui/index.html:50:    <main aria-label="Study workspace">
frontend/study-ui/index.html:61:            <h3>Study smarter</h3>
frontend/study-ui/index.html:62:            <p>Create decks, add cards, review by difficulty, and track progress over time.</p>
frontend/study-ui/index.html:66:            <p>Chat with your companion, ask what to study, and get help based on your study cards.</p>
frontend/study-ui/index.html:71:            <p>Create simple local study reminders while we connect the full backend calendar system.</p>
frontend/study-ui/index.html:81:            <p>Study cards are active. Companion now uses the worker proxy and Gemma E4B queue path when available.</p>
frontend/study-ui/index.html:85:            <p>Use the Companion tab and ask: “What should I study right now based on my cards?”</p>
frontend/study-ui/index.html:99:          emotional support, study help, calendar/reminder help, and safety-aware responses.
frontend/study-ui/index.html:126:          Login and registration now happen through the shared account page so Study,
frontend/study-ui/index.html:135:      <section class="panel hidden" data-page="study" id="dashboardPanel">
frontend/study-ui/index.html:138:            <p class="eyebrow">Study</p>
frontend/study-ui/index.html:145:            <span>Decks</span>
frontend/study-ui/index.html:146:            <strong id="deckCount">0</strong>
frontend/study-ui/index.html:163:      <div class="grid-2 hidden" data-page="study" id="studyGrid">
frontend/study-ui/index.html:167:              <p class="eyebrow">Decks</p>
frontend/study-ui/index.html:168:              <h2>Create / Select Deck</h2>
frontend/study-ui/index.html:172:          <form id="deckForm" class="form-grid">
frontend/study-ui/index.html:174:              Deck title
frontend/study-ui/index.html:175:              <input id="deckTitleInput" type="text" placeholder="Math 316 Review" required />
frontend/study-ui/index.html:179:              <textarea id="deckDescriptionInput" placeholder="What is this deck for?"></textarea>
frontend/study-ui/index.html:181:            <button class="primary" type="submit">Create Deck</button>
frontend/study-ui/index.html:187:            Selected deck
frontend/study-ui/index.html:188:            <select id="deckSelect">
frontend/study-ui/index.html:189:              <option value="">No deck selected</option>
frontend/study-ui/index.html:193:          <div id="deckSummary" class="mini-summary"></div>
frontend/study-ui/index.html:212:              <textarea id="answerInput" placeholder="1/s" required></textarea>
frontend/study-ui/index.html:240:      <section class="panel hidden" data-page="study" id="reviewPanel">
frontend/study-ui/index.html:266:          Select a deck and load a review queue.
frontend/study-ui/index.html:270:      <section class="panel hidden" data-page="study" id="cardsPanel">
frontend/study-ui/index.html:273:            <p class="eyebrow">Selected Deck</p>
frontend/study-ui/index.html:282:  <script src="/study/app.js?v=20260624fc044d"></script>
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:8:  <link id="studyPreviewStyles" rel="stylesheet" href="/study/styles.css?v=20260611121619" disabled />
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:14:      <span class="brand-mark helper-logo" title="Study Companion Helper">
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:15:        <svg viewBox="0 0 64 64" role="img" aria-label="Study Companion Helper logo">
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:25:      <a href="/study" data-route="/study">Study</a>
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1364:   Keeps Study/Admin/System/Credits route styling consistent.
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1487:body:not([data-current-route="/study"]) header a[data-route="/study"],
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1488:body:not([data-current-route="/study"]) .topbar a[data-route="/study"],
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1489:body:not([data-current-route="/study"]) .main-nav a[data-route="/study"],
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1490:body:not([data-current-route="/study"]) .route-nav a[data-route="/study"] {
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1532:   Study should visually match the shared wrapper pages.
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1533:   This overrides old Study-preview-only visual drift without
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1534:   introducing a separate Study page theme.
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1537:body[data-current-route="/study"] .brand-mark,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1538:body[data-current-route="/study"] .helper-logo,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1539:body[data-current-route="/study"] .logo-only .brand-mark {
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1544:body[data-current-route="/study"] .system-section,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1545:body[data-current-route="/study"] .summary-box,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1546:body[data-current-route="/study"] .summary-card,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1547:body[data-current-route="/study"] .feature-card {
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1551:body[data-current-route="/study"] .summary-box,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1552:body[data-current-route="/study"] .summary-card,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1553:body[data-current-route="/study"] .feature-card,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1554:body[data-current-route="/study"] .clean-card,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1555:body[data-current-route="/study"] .study-card {
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1561:body[data-current-route="/study"] h1,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1562:body[data-current-route="/study"] h2,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1563:body[data-current-route="/study"] h3,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1564:body[data-current-route="/study"] .eyebrow {
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1571:   Study partial must not override shared wrapper logo/header color.
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1574:body[data-current-route="/study"] .brand,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1575:body[data-current-route="/study"] .brand *,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1576:body[data-current-route="/study"] .brand-mark,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1577:body[data-current-route="/study"] .brand-logo,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1578:body[data-current-route="/study"] .brand-logo *,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1579:body[data-current-route="/study"] .logo-only,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1580:body[data-current-route="/study"] .logo-only *,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1581:body[data-current-route="/study"] .helper-logo,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1582:body[data-current-route="/study"] .helper-logo *,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1583:body[data-current-route="/study"] svg {
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1593:   Study uses the same single wrapper stylesheet as every page.
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1594:   Force any Study-rendered/logo-adjacent elements back to the
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1598:body[data-current-route="/study"] .topbar,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1599:body[data-current-route="/study"] .topbar *,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1600:body[data-current-route="/study"] .brand,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1601:body[data-current-route="/study"] .brand *,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1602:body[data-current-route="/study"] .logo-only,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1603:body[data-current-route="/study"] .logo-only *,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1604:body[data-current-route="/study"] .brand-mark,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1605:body[data-current-route="/study"] .brand-logo,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1606:body[data-current-route="/study"] .helper-logo {
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1614:body[data-current-route="/study"] .topbar svg,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1615:body[data-current-route="/study"] .brand svg,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1616:body[data-current-route="/study"] .logo-only svg,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1617:body[data-current-route="/study"] .brand-mark svg,
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1618:body[data-current-route="/study"] .brand-logo svg {
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1666:body[data-current-route="/study"] .topbar,
frontend/wrapper-ui/styles.css.bak-stage5o17-study-shared-style-2026-06-11-120210:1364:   Keeps Study/Admin/System/Credits route styling consistent.
frontend/wrapper-ui/styles.css.bak-stage5o17-study-shared-style-2026-06-11-120210:1487:body:not([data-current-route="/study"]) header a[data-route="/study"],
frontend/wrapper-ui/styles.css.bak-stage5o17-study-shared-style-2026-06-11-120210:1488:body:not([data-current-route="/study"]) .topbar a[data-route="/study"],
frontend/wrapper-ui/styles.css.bak-stage5o17-study-shared-style-2026-06-11-120210:1489:body:not([data-current-route="/study"]) .main-nav a[data-route="/study"],
frontend/wrapper-ui/styles.css.bak-stage5o17-study-shared-style-2026-06-11-120210:1490:body:not([data-current-route="/study"]) .route-nav a[data-route="/study"] {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:33:let gpuSessions = null;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:50:  token: localStorage.getItem("edgeStudyToken") || "",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:56:// can decide whether /study, /chat, /companion, /calendar, and /profile should proxy
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:118:      `edgeStudyToken=${encodeURIComponent(authState.token)}; Path=/; Max-Age=2592000; SameSite=Lax${secure}`;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:121:      `edgeStudyToken=; Path=/; Max-Age=0; SameSite=Lax${secure}`;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:129:const PRIVATE_APP_ROUTE_SET = new Set(["/study-wrapper-preview", "/study", "/chat", "/companion", "/calendar", "/profile"]);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:155:      "Practice smarter with study tools, guided review, and an AI companion designed to help you focus on what matters most.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:157:      ["Study", "Create decks, review cards, track progress, and focus on cards that need more practice.", "/study"],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:158:      ["Companion", "Use Companion for general conversation, study help, explanations, and supportive conversation.", "/companion"],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:164:      ["AI support", "The companion can eventually use study history, profile settings, and calendar context to support learning."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:170:  "/study-wrapper-preview": {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:172:    title: "Study Wrapper Preview",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:173:    subtitle: "Preview of the Study dashboard inside the shared wrapper layout. Study behavior is not wired here yet.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:177:  "/study": {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:179:    title: "Study",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:181:      "Study helps users create decks, add cards, review material, track progress, and prioritize what needs more practice.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:183:      ["Decks and cards", "Create study decks and add questions, answers, and explanations."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:186:      ["Future companion support", "The companion can help grade answers and explain difficult concepts."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:195:      "Chat remains a compatibility alias while Companion becomes the main AI surface for conversation, study help, explanations, and supportive support.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:198:      ["Study-aware direction", "Future stages will add study session controls, deck/card tools, and answer checking."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:208:      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:211:      ["Study helper", "Future stages will let Companion start study sessions, select decks, read questions, and grade answers."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:212:      ["Context aware", "Future versions can use profile, calendar, study, and file context with permission."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:310: * - /me = controller-owned current user/session
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:312: * - /api/study/* = laptop controller-owned Study API
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:317: * - /gpu/* = controller-owned GPU credit reservation and session management
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:524:  if (p.includes("/session/presence")) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:543:      "/gpu/sessions",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:550:    p.includes("/session/") ||
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:873:  const study = serviceById("study-api");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:877:      id: "study-api",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:878:      name: "Study API",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:879:      state: normalizeApiState(study, "online"),
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:880:      detail: normalizeApiDetail(study, "Decks, cards, reviews, stats, and study progress are active."),
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:886:      detail: "Companion chat, study grading, and context support are active.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1059:// sessions, start/stop/cleanup.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1137:          <p>Quotes expire before any real provider session starts.</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1169:        id="gpuStartSessionBtn"
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1175:        Start mock session
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1218:async function quoteMockGpuSession() {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1304:async function loadGpuSessions() {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1305:  gpuSessions = null;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1312:    gpuSessions = await api("/gpu/sessions", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1316:    gpuSessions = null;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1320:function renderGpuSessionsList() {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1321:  const sessions = gpuSessions?.sessions || [];
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1323:  if (!sessions.length) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1324:    return `<div class="empty-list">No GPU sessions yet.</div>`;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1329:      ${sessions.slice(0, 8).map((session) => `
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1332:            <strong>${safeText(session.gpu_name || session.gpu_id || "GPU session")}</strong>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1334:              ${safeText(session.status)} ·
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1335:              reserved ${formatNumber(session.credits_reserved || 0)} paid credits ·
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1336:              charged ${formatNumber(session.final_credits_charged || 0)} ·
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1337:              billable ${formatNumber(session.billable_minutes || 0)} min
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1342:            <b>${safeText(session.status)}</b>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1343:            ${session.status === "running" ? `
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1347:                data-stop-gpu-session="${safeText(session.session_token || "")}"
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1355:                data-cleanup-gpu-session="${safeText(session.session_token || "")}"
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1367:async function startMockGpuSession(quoteToken, reservationToken) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1391:    await loadGpuSessions();
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1393:    alert(result.detail || "Mock GPU session started.");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1394:    forceRefreshAfterOperation("gpu-session-started");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1401:async function cleanupMockGpuSession(sessionToken) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1407:  if (!sessionToken) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1408:    alert("Missing session token.");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1412:  const ok = confirm("Force-clean this stuck mock GPU session? This is for development testing only.");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1416:    const result = await api("/gpu/cleanup-mock-session", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1419:        session_token: sessionToken,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1425:    await loadGpuSessions();
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1431:    alert(result.gpu_session_cleanup?.detail || "Mock GPU session cleaned up.");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1432:    forceRefreshAfterOperation("gpu-session-cleaned");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1439:async function stopMockGpuSession(sessionToken) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1445:  if (!sessionToken) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1446:    alert("Missing session token.");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1450:  const ok = confirm("Stop this mock GPU session and commit actual used credits?");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1454:    const result = await api("/gpu/stop-session", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1457:        session_token: sessionToken,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1463:    await loadGpuSessions();
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1469:    alert(result.gpu_session?.detail || "Mock GPU session stopped.");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1470:    forceRefreshAfterOperation("gpu-session-stopped");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1738:        <p>Study, Companion, Profile, Calendar, Images, and related APIs.</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2257:          image generation, and future cloud GPU sessions.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2427:      <h2>External GPU sessions</h2>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2429:        Quote mock cloud GPU sessions and reserve paid credits. Free/local credits cannot be used here.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2456:          Log in to quote and reserve external GPU sessions.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2462:      <h2>GPU session history</h2>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2464:        Mock GPU session history. Running sessions can be stopped to commit actual used credits and release unused paid credits.
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2466:      ${loggedIn ? renderGpuSessionsList() : `<div class="notice">Log in to view GPU sessions.</div>`}
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2483:            <li>Study summaries</li>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2492:          <p>For regular study and companion use.</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2586:function setStudyWrapperPreviewReadOnly() {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2587:  const root = document.querySelector(".study-wrapper-preview");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2591:    const isSafePreviewSelect = el.id === "deckSelect";
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2592:    const isCreateDeckControl =
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2593:      el.id === "deckTitleInput" ||
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2594:      el.id === "deckDescriptionInput" ||
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2595:      el.closest?.("#deckForm");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2599:      el.id === "answerInput" ||
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2609:    if (isSafePreviewSelect || isCreateDeckControl || isCreateCardControl || isReviewQueueControl) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2612:      el.title = "Preview-only deck switching. Editing and review actions are still disabled.";
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2618:    el.title = "Preview only. Use the live Study page for editing and review actions.";
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2622:  if (firstPanel && !root.querySelector("[data-study-preview-notice]")) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2625:    notice.setAttribute("data-study-preview-notice", "true");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2628:      <p>This shared-layout preview is read-only. Use <a href="/study">the live Study page</a> to create decks, add cards, or review cards.</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2635:function studyPreviewSetText(id, value) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2640:function studyPreviewEscape(value) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2650:function studyPreviewNormalizeDifficulty(card) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2664:  const wrongStreak = Number(card?.wrong_streak ?? card?.wrongStreak ?? 0);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2668:  if (wrongStreak >= 2) return "hard";
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2674:function studyPreviewPercent(value) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2678:function studyPreviewCardArray(data) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2687:function renderStudyWrapperPreviewDeckSummary(deck) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2688:  const deckSummary = document.getElementById("deckSummary");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2689:  if (!deckSummary) return;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2691:  if (!deck) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2692:    deckSummary.textContent = "No deck selected.";
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2696:  const deckAccuracy = typeof deck.accuracy === "number"
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2697:    ? `${Math.round(deck.accuracy * 100)}% accuracy`
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2700:  deckSummary.innerHTML = `
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2701:    <strong>${studyPreviewEscape(deck.title)}</strong>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2702:    <p>${studyPreviewEscape(deck.description || "")}</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2703:    <small>${Number(deck.card_count || 0)} cards · ${Number(deck.total_reviews || 0)} reviews · ${deckAccuracy}</small>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2708:async function createStudyWrapperPreviewDeck(event) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2711:  const titleInput = document.getElementById("deckTitleInput");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2712:  const descriptionInput = document.getElementById("deckDescriptionInput");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2719:    alert("Enter a deck title first.");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2724:    if (statusText) statusText.textContent = "Creating deck...";
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2726:    const res = await fetch("/api/study/decks", {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2734:    if (!res.ok) throw new Error(`/api/study/decks HTTP ${res.status}: ${text.slice(0, 160)}`);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2737:    const newDeckId = data?.deck?.id;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2742:    await hydrateStudyWrapperPreview(newDeckId);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2744:    if (statusText) statusText.textContent = "Deck created";
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2746:    console.error("[study-wrapper-preview] create deck failed", error);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2747:    if (statusText) statusText.textContent = "Could not create deck";
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2748:    alert(`Could not create deck: ${error.message || error}`);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2754:const studyPreviewReviewState = {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2761:async function submitStudyWrapperPreviewReview(cardId, wasCorrect) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2763:  const deckSelect = document.getElementById("deckSelect");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2764:  const deckId = String(deckSelect?.value || "").trim();
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2769:    const res = await fetch(`/api/study/cards/${encodeURIComponent(cardId)}/reviews`, {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2774:        was_correct: Boolean(wasCorrect),
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2781:      throw new Error(`/api/study/cards/${cardId}/reviews HTTP ${res.status}: ${text.slice(0, 160)}`);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2784:    studyPreviewReviewState.currentIndex += 1;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2785:    studyPreviewReviewState.showingAnswer = false;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2787:    if (deckId) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2788:      await hydrateStudyWrapperPreview(deckId);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2791:    renderStudyWrapperPreviewReviewCard();
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2795:    console.error("[study-wrapper-preview] review submit failed", error);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2802:function renderStudyWrapperPreviewReviewCard() {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2806:  const card = studyPreviewReviewState.queue[studyPreviewReviewState.currentIndex];
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2817:  const answerBlock = studyPreviewReviewState.showingAnswer
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2821:        <p>${studyPreviewEscape(card.answer || "No answer saved.")}</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2822:        ${card.explanation ? `<p class="muted">${studyPreviewEscape(card.explanation)}</p>` : ""}
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2829:      <strong>${studyPreviewEscape(card.question || "Untitled card")}</strong>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2831:        ${studyPreviewEscape(card.performance_bucket || card.difficulty || "new")}
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2837:    ${answerBlock}
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2840:      ${studyPreviewReviewState.showingAnswer ? `
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2841:        <button class="secondary" type="button" id="studyPreviewWrongBtn">Wrong</button>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2842:        <button class="primary-btn" type="button" id="studyPreviewCorrectBtn">Correct</button>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2844:        <button class="primary-btn" type="button" id="studyPreviewShowAnswerBtn">Show Answer</button>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2846:      <button class="secondary" type="button" id="studyPreviewSkipCardBtn">Skip</button>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2850:  document.getElementById("studyPreviewShowAnswerBtn")?.addEventListener("click", () => {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2851:    studyPreviewReviewState.showingAnswer = true;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2852:    renderStudyWrapperPreviewReviewCard();
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2855:  document.getElementById("studyPreviewSkipCardBtn")?.addEventListener("click", () => {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2856:    studyPreviewReviewState.currentIndex += 1;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2857:    studyPreviewReviewState.showingAnswer = false;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2858:    renderStudyWrapperPreviewReviewCard();
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2861:  document.getElementById("studyPreviewWrongBtn")?.addEventListener("click", () => {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2862:    submitStudyWrapperPreviewReview(card.id, false);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2865:  document.getElementById("studyPreviewCorrectBtn")?.addEventListener("click", () => {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2866:    submitStudyWrapperPreviewReview(card.id, true);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2870:async function loadStudyWrapperPreviewReviewQueue() {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2871:  const deckSelect = document.getElementById("deckSelect");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2875:  const deckId = String(deckSelect?.value || "").trim();
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2876:  if (!deckId) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2877:    alert("Select or create a deck first.");
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2886:    const res = await fetch(`/api/study/decks/${encodeURIComponent(deckId)}/review-queue?mode=${encodeURIComponent(mode)}&limit=10`, {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2893:      throw new Error(`/api/study/decks/${deckId}/review-queue HTTP ${res.status}: ${text.slice(0, 160)}`);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2897:    studyPreviewReviewState.queue = Array.isArray(data.cards) ? data.cards : [];
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2898:    studyPreviewReviewState.currentIndex = 0;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2899:    studyPreviewReviewState.showingAnswer = false;
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2902:    studyPreviewSetText("bucketNew", String(buckets.new || 0));
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2903:    studyPreviewSetText("bucketHard", String(buckets.hard || 0));
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2904:    studyPreviewSetText("bucketMedium", String(buckets.medium || 0));
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2905:    studyPreviewSetText("bucketEasy", String(buckets.easy || 0));
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2907:    renderStudyWrapperPreviewReviewCard();

=== companion command / phrase inventory ===
frontend/study-ui/app.js:21:    console.warn(`[study-ui] Missing element #${id}; skipped ${eventName} listener.`);
frontend/study-ui/app.js:358:          <span class="pill">Wrong streak: ${card.recent_wrong_streak || 0}</span>
frontend/study-ui/app.js:434:        <button class="secondary" data-review="wrong">Wrong</button>
frontend/study-ui/app.js:435:        <button class="primary" data-review="correct">Correct</button>
frontend/study-ui/app.js:437:      <button class="secondary" id="skipCardBtn">Skip</button>
frontend/study-ui/app.js:449:  const skipCardBtn = $("skipCardBtn");
frontend/study-ui/app.js:450:  if (skipCardBtn) {
frontend/study-ui/app.js:451:    skipCardBtn.addEventListener("click", () => {
frontend/study-ui/app.js:466:async function submitReview(cardId, wasCorrect) {
frontend/study-ui/app.js:471:      was_correct: wasCorrect,
frontend/study-ui/app.js:472:      confidence: wasCorrect ? 4 : 2
frontend/study-ui/app.js:597:   Companion study mode
frontend/study-ui/app.js:600:state.companionQueue = [];
frontend/study-ui/app.js:601:state.companionIndex = 0;
frontend/study-ui/app.js:602:state.companionCurrentCard = null;
frontend/study-ui/app.js:603:state.companionPendingUnsure = null;
frontend/study-ui/app.js:605:function companionAddMessage(role, text) {
frontend/study-ui/app.js:606:  const chat = $("companionChat");
frontend/study-ui/app.js:616:function companionClearChat() {
frontend/study-ui/app.js:617:  const chat = $("companionChat");
frontend/study-ui/app.js:622:function syncCompanionDeckSelect() {
frontend/study-ui/app.js:623:  const select = $("companionDeckSelect");
frontend/study-ui/app.js:643:const originalLoadDecksForCompanion = loadDecks;
frontend/study-ui/app.js:644:loadDecks = async function patchedLoadDecksForCompanion() {
frontend/study-ui/app.js:645:  await originalLoadDecksForCompanion();
frontend/study-ui/app.js:646:  syncCompanionDeckSelect();
frontend/study-ui/app.js:649:async function companionStartQueue() {
frontend/study-ui/app.js:655:  const deckId = $("companionDeckSelect").value;
frontend/study-ui/app.js:656:  const mode = $("companionReviewMode").value;
frontend/study-ui/app.js:659:    companionClearChat();
frontend/study-ui/app.js:660:    companionAddMessage("assistant", "Please select a deck first.");
frontend/study-ui/app.js:665:    companionClearChat();
frontend/study-ui/app.js:666:    companionAddMessage("assistant", "Loading your review queue...");
frontend/study-ui/app.js:672:    state.companionQueue = data.cards || [];
frontend/study-ui/app.js:673:    state.companionIndex = 0;
frontend/study-ui/app.js:674:    state.companionPendingUnsure = null;
frontend/study-ui/app.js:676:    companionClearChat();
frontend/study-ui/app.js:678:    if (!state.companionQueue.length) {
frontend/study-ui/app.js:679:      companionAddMessage("assistant", "This deck does not have cards yet. Add cards on the Study page first.");
frontend/study-ui/app.js:683:    companionAddMessage(
frontend/study-ui/app.js:688:    companionAskCurrentCard();
frontend/study-ui/app.js:690:    companionClearChat();
frontend/study-ui/app.js:691:    companionAddMessage("assistant", `I could not load the queue: ${err.message}`);
frontend/study-ui/app.js:695:function companionAskCurrentCard() {
frontend/study-ui/app.js:696:  const card = state.companionQueue[state.companionIndex];
frontend/study-ui/app.js:697:  state.companionCurrentCard = card || null;
frontend/study-ui/app.js:698:  state.companionPendingUnsure = null;
frontend/study-ui/app.js:700:  $("companionConfirmActions")?.classList.add("hidden");
frontend/study-ui/app.js:703:    companionAddMessage("assistant", "Review complete. Load another queue when you are ready.");
frontend/study-ui/app.js:708:  const count = `${state.companionIndex + 1}/${state.companionQueue.length}`;
frontend/study-ui/app.js:710:  companionAddMessage(
frontend/study-ui/app.js:715:  $("companionAnswerInput").value = "";
frontend/study-ui/app.js:716:  $("companionAnswerInput").focus();
frontend/study-ui/app.js:719:async function companionSubmitAnswer(event) {
frontend/study-ui/app.js:722:  const card = state.companionCurrentCard;
frontend/study-ui/app.js:724:    companionAddMessage("assistant", "Load a review queue first.");
frontend/study-ui/app.js:728:  const answer = $("companionAnswerInput").value.trim();
frontend/study-ui/app.js:731:  companionAddMessage("user", answer);
frontend/study-ui/app.js:732:  $("companionAnswerInput").value = "";
frontend/study-ui/app.js:735:    const data = await api("/companion/study/grade", {
frontend/study-ui/app.js:745:      companionAddMessage("assistant", `Correct. ${data.feedback}`);
frontend/study-ui/app.js:746:      await companionAfterRecordedReview();
frontend/study-ui/app.js:751:      companionAddMessage(
frontend/study-ui/app.js:755:      await companionAfterRecordedReview();
frontend/study-ui/app.js:759:    state.companionPendingUnsure = {
frontend/study-ui/app.js:765:    companionAddMessage(
frontend/study-ui/app.js:767:      `${data.feedback}\n\nStored answer: ${data.card.answer}\n\nShould I mark your answer correct or wrong?`
frontend/study-ui/app.js:770:    $("companionConfirmActions")?.classList.remove("hidden");
frontend/study-ui/app.js:772:    companionAddMessage("assistant", `I could not grade that answer: ${err.message}`);
frontend/study-ui/app.js:776:async function companionRecordManualReview(wasCorrect) {
frontend/study-ui/app.js:777:  const pending = state.companionPendingUnsure;
frontend/study-ui/app.js:778:  const card = pending?.card || state.companionCurrentCard;
frontend/study-ui/app.js:786:      was_correct: Boolean(wasCorrect),
frontend/study-ui/app.js:787:      confidence: wasCorrect ? 4 : 2,
frontend/study-ui/app.js:788:      notes: "Companion user-confirmed review."
frontend/study-ui/app.js:792:  companionAddMessage("assistant", wasCorrect ? "Marked correct." : "Marked wrong.");
frontend/study-ui/app.js:793:  $("companionConfirmActions")?.classList.add("hidden");
frontend/study-ui/app.js:795:  await companionAfterRecordedReview();
frontend/study-ui/app.js:798:async function companionAfterRecordedReview() {
frontend/study-ui/app.js:805:  state.companionIndex += 1;
frontend/study-ui/app.js:806:  state.companionPendingUnsure = null;
frontend/study-ui/app.js:808:  setTimeout(() => companionAskCurrentCard(), 350);
frontend/study-ui/app.js:811:const companionLoadQueueBtn = $("companionLoadQueueBtn");
frontend/study-ui/app.js:812:if (companionLoadQueueBtn) {
frontend/study-ui/app.js:813:  companionLoadQueueBtn.addEventListener("click", companionStartQueue);
frontend/study-ui/app.js:816:const companionAnswerForm = $("companionAnswerForm");
frontend/study-ui/app.js:817:if (companionAnswerForm) {
frontend/study-ui/app.js:818:  companionAnswerForm.addEventListener("submit", companionSubmitAnswer);
frontend/study-ui/app.js:821:const companionConfirmCorrectBtn = $("companionConfirmCorrectBtn");
frontend/study-ui/app.js:822:if (companionConfirmCorrectBtn) {
frontend/study-ui/app.js:823:  companionConfirmCorrectBtn.addEventListener("click", () => companionRecordManualReview(true));
frontend/study-ui/app.js:826:const companionConfirmWrongBtn = $("companionConfirmWrongBtn");
frontend/study-ui/app.js:827:if (companionConfirmWrongBtn) {
frontend/study-ui/app.js:828:  companionConfirmWrongBtn.addEventListener("click", () => companionRecordManualReview(false));
frontend/study-ui/app.js:832:/* === Companion + local calendar patch === */
frontend/study-ui/app.js:834:  const CHAT_KEY = "aiStudyCompanionChat:v1";
frontend/study-ui/app.js:969:    const err = new Error(message || "Temporary gateway issue while the companion is responding.");
frontend/study-ui/app.js:981:      throw transientGatewayError("Network/proxy connection interrupted while the companion was responding.");
frontend/study-ui/app.js:996:          `Temporary gateway error ${res.status || ""}. The companion may still be working.`,
frontend/study-ui/app.js:1055:        addCompanionMessage("system", "The companion is still thinking. I am waiting for the queued response instead of showing a gateway error.");
frontend/study-ui/app.js:1064:  function buildCompanionPrompt(message) {
frontend/study-ui/app.js:1089:      "You are the user's AI study companion.",
frontend/study-ui/app.js:1099:  async function sendCompanionToApi(message) {
frontend/study-ui/app.js:1101:    const prompt = buildCompanionPrompt(message);
frontend/study-ui/app.js:1125:        url: `${base}/companion/chat`,
frontend/study-ui/app.js:1145:            addCompanionMessage("system", `Queued with Gemma E4B as job ${jobId}. Waiting for the worker...`);
frontend/study-ui/app.js:1164:  function getCompanionMessages() {
frontend/study-ui/app.js:1168:        text: "Hi, I am your study companion. Ask me what to study, paste an answer for me to check, or ask me to help make a card.",
frontend/study-ui/app.js:1173:  function setCompanionMessages(messages) {
frontend/study-ui/app.js:1177:  function renderCompanionMessages() {
frontend/study-ui/app.js:1178:    const wrap = document.getElementById("companionMessages");
frontend/study-ui/app.js:1181:    const messages = getCompanionMessages();
frontend/study-ui/app.js:1189:  function addCompanionMessage(role, text) {
frontend/study-ui/app.js:1190:    const messages = getCompanionMessages();
frontend/study-ui/app.js:1192:    setCompanionMessages(messages);
frontend/study-ui/app.js:1193:    renderCompanionMessages();
frontend/study-ui/app.js:1196:  async function handleCompanionSubmit(message) {
frontend/study-ui/app.js:1197:    const input = document.getElementById("companionInput");
frontend/study-ui/app.js:1198:    const sendBtn = document.getElementById("companionSendBtn");
frontend/study-ui/app.js:1199:    const status = document.getElementById("companionMessage");
frontend/study-ui/app.js:1205:    addCompanionMessage("user", clean);
frontend/study-ui/app.js:1211:      const answer = await sendCompanionToApi(clean);
frontend/study-ui/app.js:1212:      addCompanionMessage("assistant", answer || "I got a response, but it did not include readable text.");
frontend/study-ui/app.js:1217:        ? "The companion may still be working, but the gateway timed out before the browser received the final response. I did not save the raw Cloudflare error page. Refresh in a moment or try again."
frontend/study-ui/app.js:1220:      addCompanionMessage(
frontend/study-ui/app.js:1222:        "I could not finish the companion response yet.\n\n" + cleanError
frontend/study-ui/app.js:1224:      if (status) status.textContent = err.transient ? "Companion is still pending after a gateway timeout." : "Companion API route failed.";
frontend/study-ui/app.js:1230:  function setupCompanion() {
frontend/study-ui/app.js:1231:    renderCompanionMessages();
frontend/study-ui/app.js:1233:    const form = document.getElementById("companionForm");
frontend/study-ui/app.js:1234:    const clearBtn = document.getElementById("companionClearBtn");
frontend/study-ui/app.js:1235:    const suggestBtn = document.getElementById("companionStudySuggestBtn");
frontend/study-ui/app.js:1241:        handleCompanionSubmit();
frontend/study-ui/app.js:1249:        renderCompanionMessages();
frontend/study-ui/app.js:1256:        handleCompanionSubmit("What should I study right now based on my cards?");
frontend/study-ui/app.js:1346:        setupCompanion();
frontend/study-ui/app.js:1353:    setupCompanion();
frontend/study-ui/_headers:2:  Content-Security-Policy: default-src 'self'; connect-src 'self' https://alexhartel.com https://companion.alexhartel.com https://calendar.alexhartel.com https://profile.alexhartel.com; script-src 'self'; style-src 'self'; img-src 'self' data:; font-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self' https://alexhartel.com
frontend/study-ui/styles.css:510:   Companion page
frontend/study-ui/styles.css:513:.companion-layout {
frontend/study-ui/styles.css:518:.companion-controls {
frontend/study-ui/styles.css:525:.companion-chat {
frontend/study-ui/styles.css:563:.companion-answer {
frontend/study-ui/styles.css:569:.companion-actions {
frontend/study-ui/styles.css:576:  .companion-controls,
frontend/study-ui/styles.css:577:  .companion-answer {
frontend/study-ui/styles.css:581:  .companion-actions {
frontend/study-ui/styles.css:588:/* === Companion + local calendar patch === */
frontend/study-ui/styles.css:589:.companion-layout {
frontend/study-ui/styles.css:594:.companion-chat {
frontend/study-ui/styles.css:633:.companion-form textarea {
frontend/study-ui/study-content.partial.html:35:            <h3>AI companion</h3>
frontend/study-ui/study-content.partial.html:36:            <p>Chat with your companion, ask what to study, and get help based on your study cards.</p>
frontend/study-ui/study-content.partial.html:37:            <button class="secondary" type="button" data-page-link="companion">Open Companion</button>
frontend/study-ui/study-content.partial.html:51:            <p>Study cards are active. Companion now uses the worker proxy and Gemma E4B queue path when available.</p>
frontend/study-ui/study-content.partial.html:55:            <p>Use the Companion tab and ask: “What should I study right now based on my cards?”</p>
frontend/study-ui/study-content.partial.html:60:      <section class="panel page-block hidden" data-page="companion" id="companionPanel">
frontend/study-ui/study-content.partial.html:63:            <p class="eyebrow">Companion</p>
frontend/study-ui/study-content.partial.html:64:            <h2>AI Companion</h2>
frontend/study-ui/study-content.partial.html:68:          The full companion runs in the AI Platform app. It is designed for conversation,
frontend/study-ui/study-content.partial.html:71:        <a class="primary" href="https://alexhartel.com/companion">Open Full Companion</a>
frontend/study-ui/study-content.partial.html:82:          The full calendar/reminder system belongs in the AI Platform app so the companion
frontend/study-ui/study-content.partial.html:97:          Companion, Calendar, and Profile can use the same account.
frontend/study-ui/index.html:25:        <a class="app-shell-link nav-link" href="https://alexhartel.com/companion">Companion</a>
frontend/study-ui/index.html:65:            <h3>AI companion</h3>
frontend/study-ui/index.html:66:            <p>Chat with your companion, ask what to study, and get help based on your study cards.</p>
frontend/study-ui/index.html:67:            <button class="secondary" type="button" data-page-link="companion">Open Companion</button>
frontend/study-ui/index.html:81:            <p>Study cards are active. Companion now uses the worker proxy and Gemma E4B queue path when available.</p>
frontend/study-ui/index.html:85:            <p>Use the Companion tab and ask: “What should I study right now based on my cards?”</p>
frontend/study-ui/index.html:90:      <section class="panel page-block hidden" data-page="companion" id="companionPanel">
frontend/study-ui/index.html:93:            <p class="eyebrow">Companion</p>
frontend/study-ui/index.html:94:            <h2>AI Companion</h2>
frontend/study-ui/index.html:98:          The full companion runs in the AI Platform app. It is designed for conversation,
frontend/study-ui/index.html:101:        <a class="primary" href="https://alexhartel.com/companion">Open Full Companion</a>
frontend/study-ui/index.html:112:          The full calendar/reminder system belongs in the AI Platform app so the companion
frontend/study-ui/index.html:127:          Companion, Calendar, and Profile can use the same account.
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:14:      <span class="brand-mark helper-logo" title="Study Companion Helper">
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:15:        <svg viewBox="0 0 64 64" role="img" aria-label="Study Companion Helper logo">
frontend/wrapper-ui/index.html.bak-stage5o27-generic-public-gates-2026-06-11-121802:26:      <a href="/companion" data-route="/companion">Companion</a>
frontend/wrapper-ui/styles.css.bak-stage5o33-profile-route-fix-2026-06-11-123729:1667:body[data-current-route="/companion"] .topbar,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:15:function cleanCompanionErrorMessage(value) {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:56:// can decide whether /study, /chat, /companion, /calendar, and /profile should proxy
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:62:  if (typeof cleanCompanionErrorMessage === "function") {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:63:    return cleanCompanionErrorMessage(text);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:129:const PRIVATE_APP_ROUTE_SET = new Set(["/study-wrapper-preview", "/study", "/chat", "/companion", "/calendar", "/profile"]);
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:155:      "Practice smarter with study tools, guided review, and an AI companion designed to help you focus on what matters most.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:158:      ["Companion", "Use Companion for general conversation, study help, explanations, and supportive conversation.", "/companion"],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:159:      ["Profile", "Manage preferences, permissions, account settings, and future companion personalization.", "/profile"],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:164:      ["AI support", "The companion can eventually use study history, profile settings, and calendar context to support learning."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:186:      ["Future companion support", "The companion can help grade answers and explain difficult concepts."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:193:    title: "Companion",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:195:      "Chat remains a compatibility alias while Companion becomes the main AI surface for conversation, study help, explanations, and supportive support.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:197:      ["Companion", "General local-first AI conversation through the existing queued worker path."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:199:      ["Compatibility", "/chat stays available for old links while /companion is the primary route."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:204:  "/companion": {
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:206:    title: "Companion",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:208:      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:210:      ["General conversation", "Use Companion for normal local-first AI conversation."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:211:      ["Study helper", "Future stages will let Companion start study sessions, select decks, read questions, and grade answers."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:213:      ["Helpful boundaries", "Companion should stay supportive, ask when unsure, and use safety-aware boundaries."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:239:      ["Permissions", "Control what data the companion and tools are allowed to use."],
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:249:      "Credits control access to higher-cost features like AI jobs, companion usage, image generation, storage, and future premium tools.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:313: * - /api/companion/* = laptop controller-owned Companion API
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:883:      id: "companion-api",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:884:      name: "Companion API",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:886:      detail: "Companion chat, study grading, and context support are active.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:904:      detail: "Future ComfyUI-backed image generation for companion images and user-requested visuals.",
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:1738:        <p>Study, Companion, Profile, Calendar, Images, and related APIs.</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2256:          Credits are the platform currency for companion usage, AI jobs, storage, RAG indexing,
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2300:            <p>Used for uploaded files, future RAG data, generated assets, and companion memory.</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2484:            <li>Basic companion usage</li>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2492:          <p>For regular study and companion use.</p>
frontend/wrapper-ui/app.js.bak-stage5o33-profile-route-fix-2026-06-11-123729:2496:            <li>More companion messages</li>
```
