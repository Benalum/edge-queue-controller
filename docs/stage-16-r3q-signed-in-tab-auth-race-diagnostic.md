# Stage 16 R3Q Signed-In Tab Auth Race Diagnostic

This checkpoint records a read-only source diagnostic for the issue where clicking a tab while signed in can sometimes show a public tab or public view.

## Scope

- Source scan only.
- Repo docs and smoke checkpoint only.
- VM200 SSH/live scan skipped because the previous read-only SSH attempt timed out.

No source app patch, no VM200 static deploy, no backend patch, no DB write, no service restart, no CT or VM restart, no OAuth or Google API work, and no runtime model helper scheduler mutation.

## Working hypothesis

This is most likely a front-end auth routing race.

The UI should not treat auth as a simple boolean. It should use three states:

- checking
- signed_in
- signed_out

Expected behavior:

- checking: keep the current private shell or show Checking session.
- signed_in: render the private signed-in tab.
- signed_out: render the public view or login prompt.

## Source finding

The source scan found private page code that falls back to local-user when APC_PRIVATEPAGES.me is absent or not ready. That is a likely contributor to signed-in views briefly behaving like public or local views during auth refresh.

## Recommended next checkpoint

Stage 16 R3R Signed-In Tab Auth Gate Stabilization

Patch direction:

- Centralize auth and session state.
- Make private tab renderers wait while auth is checking.
- Do not render public content for private tabs until api/me definitively returns signed-out.
- Do not fall back to local-user while signed-in auth is still checking.
- Keep current private tab shell during short refreshes and rechecks.
- Keep the patch static front-end only unless backend evidence requires otherwise.

## Source file inventory
frontend/wrapper-ui/apc-wrapper-local/index.html
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js
frontend/wrapper-ui/apc-wrapper-local/privatepages/sol.css
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-session.css
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js

## Source auth routing grep
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:18:      const user = window.APC_PRIVATEPAGES && window.APC_PRIVATEPAGES.me
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:19:        ? window.APC_PRIVATEPAGES.me()
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:21:      return user && user.email ? user.email : "local-user";
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:23:      return "local-user";
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:37:      sessions: [],
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:48:    out.sessions = Array.isArray(out.sessions) ? out.sessions : [];
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:69:        seenCount: Number(card.seenCount || card.seen_count || card.reviewCount || 0),
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:217:    let selected = cards.slice();
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:219:    if (cleanStyle === "new") selected = cards.filter((card) => !card.seenCount || card.difficulty === "new");
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:220:    if (cleanStyle === "all") selected = cards.slice();
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:221:    if (cleanStyle === "hard") selected = cards.filter((card) => card.difficulty === "hard" || card.flagged || card.wrongCount > card.correctCount);
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:222:    if (cleanStyle === "medium") selected = cards.filter((card) => card.difficulty === "medium");
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:223:    if (cleanStyle === "easy") selected = cards.filter((card) => card.difficulty === "easy");
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:225:      selected = cards.slice().sort((a, b) => cardScore(b) - cardScore(a));
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:228:    if (!selected.length && cleanStyle !== "all") selected = cards.slice();
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:230:    return selected;
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:238:        result = { ok: false, message: "A study session is already running." };
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:254:        id: uid("session"),
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:271:      result = { ok: true, message: "Study session started.", runtime: draft.runtime };
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:285:    let message = "No active session to pause.";
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:291:      message = "Study session paused.";
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:297:    let message = "No paused session to resume.";
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:304:      message = "Study session resumed.";
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:335:      draft.sessions.unshift(record);
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:351:        ? "Study session stopped and saved."
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:352:        : "Study session stopped. No session was saved because no cards were reviewed."
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:440:        reply = "The study session is paused. Resume it when you are ready.";
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:460:      const userAnswer = normalizeAnswer(answer);
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:463:      if (userAnswer && expected && (userAnswer === expected || userAnswer.includes(expected) || expected.includes(userAnswer))) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:475:        userAnswer: String(answer || ""),
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:487:    const reviewedCards = state.cards.filter((card) => card.seenCount > 0).length;
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:489:    const cardsSeen = state.sessions.reduce((sum, session) => sum + Number(session.cardsSeen || 0), 0);
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:490:    const totalMs = state.sessions.reduce((sum, session) => sum + Number(session.durationMs || 0), 0);
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:495:      reviewedCards,
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:497:      savedSessions: state.sessions.length,
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:531:      console.warn("[study-store] skipping backend sync because no login token is available yet");
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:591:    let reviewSummary = null;
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:593:      reviewSummary = await apiGet("/api/study/review-summary-lite");
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:595:      console.warn("[study-store] backend review summary sync failed", error);
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:598:    if (reviewSummary && reviewSummary.by_card) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:600:        const summary = reviewSummary.by_card[String(card.id)];
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:614:      backendSessions = await apiGet("/api/study/sessions-lite");
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:616:      console.warn("[study-store] backend sessions sync failed", error);
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:619:    const sessions = backendSessions && Array.isArray(backendSessions.sessions)
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:620:      ? backendSessions.sessions.map((session) => {
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:621:          const started = session.started_at ? Date.parse(session.started_at) : 0;
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:622:          const ended = session.ended_at ? Date.parse(session.ended_at) : 0;
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:624:            id: String(session.id),
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:625:            startedAt: session.started_at || "",
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:626:            endedAt: session.ended_at || "",
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:629:            deckIds: session.deck_id ? [String(session.deck_id)] : [],
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:630:            cardsSeen: Number(session.cards_seen || 0),
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:631:            correct: Number(session.correct || 0),
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:632:            wrong: Number(session.wrong || 0),
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:633:            skipped: Number(session.skipped || 0),
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:634:            reason: session.status || "saved",
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:638:      : current.sessions;
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:644:      sessions,
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:646:      backendReviewSummary: reviewSummary,
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:686:    if (!token) throw new Error("No login token available for backend writeback.");
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:718:  function rememberBackendSessionId(sessionId) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:719:    if (!sessionId) return;
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:724:    state.runtime.backendSessionId = String(sessionId);
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:748:    console.log("[study-store] CT203 session start writeback", {
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:754:    backendStartPromise = apiPost("/api/study/session-writeback-lite", {
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:761:      console.log("[study-store] CT203 session start complete", data);
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:762:      if (data && data.session_id) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:763:        rememberBackendSessionId(data.session_id);
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:764:        return String(data.session_id);
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:768:      console.warn("[study-store] backend session start writeback failed", error);
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:777:  async function backendRecordReview(card, result) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:780:    const sessionId = await backendStartRuntime();
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:782:    console.log("[study-store] CT203 review writeback", {
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:783:      sessionId,
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:789:    const data = await apiPost("/api/study/session-writeback-lite", {
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:790:      action: "review",
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:791:      session_id: sessionId ? intOrNull(sessionId) : null,
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:797:    console.log("[study-store] CT203 review writeback complete", data);
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:799:    if (data && data.session_id) rememberBackendSessionId(data.session_id);
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:802:  async function backendStopSession(sessionId, pendingStart) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:803:    let resolvedSessionId = sessionId || null;
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:814:      console.warn("[study-store] CT203 stop skipped: no backend session id");
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:818:    console.log("[study-store] CT203 stop writeback", { sessionId: resolvedSessionId });
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:820:    await apiPost("/api/study/session-writeback-lite", {
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:822:      session_id: intOrNull(resolvedSessionId)
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:825:    console.log("[study-store] CT203 stop writeback complete", { sessionId: resolvedSessionId });
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:875:      backendRecordReview(beforeCardSnapshot, outcome)
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:878:          console.warn("[study-store] backend review writeback failed", error);
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:881:      console.warn("[study-store] no CT203 review outcome detected", {
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:894:    const sessionId = rt.backendSessionId || null;
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:899:    console.log("[study-store] stopSessionWithBackend", { sessionId, result });
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js:901:    backendStopSession(sessionId, pendingStart)
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:7:  const VERSION = "sol-study-session-v2";
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:10:    listening: "/privatepages/assets/sol-clips/dog_listening_236b385d.mp4",
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:11:    thinking: "/privatepages/assets/sol-clips/dog_thinking_8dcd159e.mp4",
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:12:    talking: "/privatepages/assets/sol-clips/dog_talking_f28d314b.mp4"
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:38:      const user = window.APC_PRIVATEPAGES && window.APC_PRIVATEPAGES.me ? window.APC_PRIVATEPAGES.me() : null;
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:39:      return user && user.email ? user.email : "local-user";
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:41:      return "local-user";
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:164:        const selectedVoice = selectedBrowserVoice(settings);
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:165:        if (selectedVoice) utterance.voice = selectedVoice;
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:190:    render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:200:    render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:214:    render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:261:  function selectedBrowserVoice(settings) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:267:      const selected = voices.find((voice) => browserVoiceKey(voice) === key);
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:268:      if (selected) return selected;
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:276:  function renderBrowserVoiceOptions(settings) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:279:    const systemSelected = !settings.browserVoiceURI ? "selected" : "";
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:284:      const selected = settings.browserVoiceURI === key ? "selected" : "";
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:285:      options.push(`<option value="${escapeHtml(key)}" ${selected}>${escapeHtml(browserVoiceLabel(voice))}</option>`);
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:347:      render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:367:    render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:445:        stopBrowserListening("Listening stopped. Review the message, then press Send.");
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:476:      render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:538:      render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:549:    render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:560:    render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:688:        render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:698:        render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:707:      render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:714:      render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:724:  function renderLastMessage() {
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:726:    if (!latest) return `<div class="sol-reply empty">Ask Sol a question or start a study session below.</div>`;
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:730:  function renderDeckChoices(state) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:745:  function renderRuntime(state) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:747:    if (!rt) return `<p class="study-muted">No active study session.</p>`;
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:751:      <div class="sol-session-status">
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:753:        <span>${escapeHtml(rt.style)} · ${rt.cardsSeen} reviewed · ${store().formatDuration(store().activeElapsedMs(rt))}</span>
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:766:  function renderStudyControls(state) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:772:        <h2>Study session</h2>
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:774:        ${renderRuntime(state)}
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:776:        <div class="sol-session-grid">
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:782:              <option value="balanced" selected>balanced cards</option>
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:792:              ${renderDeckChoices(state)}
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:798:          <button class="sol-button" type="button" data-companion-action="start-session">Start</button>
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:799:          <button class="sol-button secondary" type="button" data-companion-action="pause-session">Pause</button>
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:800:          <button class="sol-button secondary" type="button" data-companion-action="resume-session">Resume</button>
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:801:          <button class="sol-button secondary" type="button" data-companion-action="stop-session">Stop</button>
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:818:                ${state.decks.map((deck) => `<option value="${escapeHtml(deck.id)}" ${deck.id === state.activeDeckId ? "selected" : ""}>${escapeHtml(deck.title)}</option>`).join("")}
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:870:                : `<p class="study-muted">No cards in the selected deck.</p>`
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:883:  function renderVoiceBox(settings) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:901:            ${renderBrowserVoiceOptions(normalized)}
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:912:  function renderListenBox() {
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:942:  function renderNoticeBox() {
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:952:          Companion can chat with you, speak replies, listen to drafts, run hands-free conversation mode, list and select study decks, start study sessions, show cards, create/edit/delete decks and cards, and flag cards.
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:958:  function render() {
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:977:        <div class="sol-message-window">${renderLastMessage()}</div>
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:986:      ${renderVoiceBox(settings)}
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:988:        ${renderListenBox()}
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:990:        ${renderNoticeBox()}
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1036:  function selectedStyleFromText(text) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1148:    if (rt && rt.status === "active") return "A study session is already active. Answer the current card, or say “pause study” or “stop study”.";
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1149:    if (rt && rt.status === "paused") return "A study session is paused. Say “resume study” to continue it, or “stop study” to end it.";
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1168:    if (!result.ok) return result.message || "I could not start a study session yet.";
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1172:    return `Started a ${style} study session with “${deck.title}”.\n\n${card ? `Question:\n\n${card.front}` : "No card is ready yet."}`;
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1178:    if (!rt || rt.status !== "active") return "There is no active study session to pause.";
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1185:    if (!rt || rt.status !== "paused") return "There is no paused study session to resume.";
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1195:    if (!rt) return "There is no active study session to stop.";
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1395:  function routeStudyCommand(prompt) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1409:      return card ? `Current card:\n\n${card.front} → ${card.back}` : "No current card is selected.";
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1416:    if (lower === "start study" || lower.includes("start study session") || lower.includes("begin study")) return commandStartStudy(clean);
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1421:    if (lower === "pause study" || lower.includes("pause study session")) return commandPauseStudy();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1422:    if (lower === "resume study" || lower.includes("resume study session") || lower.includes("continue study")) return commandResumeStudy();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1423:    if (lower === "stop study" || lower.includes("stop study session") || lower.includes("end study") || lower.includes("finish study") || lower.includes("quit study")) return commandStopStudy();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1439:    const routed = routeStudyCommand(prompt);
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1440:    if (routed) return routed;
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1455:    addMessage("user", clean);
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1463:      const routed = routeStudyCommand(clean);
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1465:      if (routed) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1466:        reply = routed;
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1470:        reply = "The study session is paused. Say “resume study” to continue it, or “stop study” to end it.";
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1477:      render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1489:    let reply = result.message || "Study session started.";
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1495:    render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1503:    render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1514:    render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1522:    render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1527:    const selected = settings.voiceName || "kokoro:af_sarah";
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1528:    if (selected.startsWith("kokoro:")) return selected.replace(/^kokoro:/, "");
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1535:    // Companion Browser-Only Notice R3M: server-side Kokoro fallback is intentionally disabled for this browser MVP.
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1643:    render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1647:    if (action === "start-session") return startStudySession();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1648:    if (action === "pause-session") return pauseStudySession();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1649:    if (action === "resume-session") return resumeStudySession();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1650:    if (action === "stop-session") return stopStudySession();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1698:    render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1716:        render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1726:        render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1764:  render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1772:    render,
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1783:  if (document.readyState === "loading") {
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1789:  document.addEventListener("apc-private-page-rendered", function (event) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1800:    const selected = selectedBrowserVoice(settings);
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1801:    settings.browserVoiceName = selected ? selected.name || "" : "";
frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js:1812:        if (byId("companionBrowserVoiceSelect")) render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-session.css:132:.study-live-session,
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-session.css:133:.sol-session-status,
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-session.css:144:.sol-session-grid,
frontend/wrapper-ui/apc-wrapper-local/privatepages/study-session.css:181:  .sol-session-grid,
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:28:  function renderStats(state) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:31:      state.backendReviewSummary && state.backendReviewSummary.overall
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:32:        ? state.backendReviewSummary.overall
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:40:    const backendCardsReviewed =
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:41:      summaryOverall && Number.isFinite(Number(summaryOverall.total_reviews))
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:42:        ? Number(summaryOverall.total_reviews)
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:43:        : progressOverall && Number.isFinite(Number(progressOverall.review_count))
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:44:          ? Number(progressOverall.review_count)
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:65:        <article><strong>${s.reviewedCards}</strong><span>Unique cards reviewed</span></article>
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:66:        <article><strong>${backendCardsReviewed}</strong><span>Total card reviews</span></article>
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:73:  function renderDecks(state) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:110:  function renderCards(state) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:162:  function renderSessions(state) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:170:            ? `<article class="study-live-session">
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:172:                <span>${escapeHtml(runtime.style)} · ${runtime.cardsSeen} card(s) reviewed · ${store().formatDuration(store().activeElapsedMs(runtime))}</span>
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:174:            : `<p class="study-muted">No active session. Start one by asking Sol: start study.</p>`
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:179:            state.sessions.length
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:180:              ? state.sessions.slice(0, 12).map((session) => `
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:183:                      <h3>${escapeHtml(session.style === "backend" ? "Study session" : session.style + " study session")}</h3>
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:184:                      <p>${session.cardsSeen} card(s) · ${session.correct} correct · ${session.wrong} wrong · ${session.skipped} skipped</p>
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:185:                      <small>${escapeHtml(new Date(session.startedAt).toLocaleString())} · ${store().formatDuration(session.durationMs)}</small>
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:189:              : `<p class="study-muted">No saved sessions yet. Sessions are saved after at least one card is reviewed.</p>`
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:204:    render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:207:  function render() {
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:214:      ${renderStats(state)}
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:216:        ${renderDecks(state)}
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:217:        ${renderCards(state)}
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:219:      ${renderSessions(state)}
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:232:        render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:243:        render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:290:      render();
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:295:    render,
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:301:  document.addEventListener("apc-private-page-rendered", function (event) {
frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js:305:  if (document.readyState === "loading") {
frontend/wrapper-ui/apc-wrapper-local/privatepages/sol.css:4:.private-shell[data-private-page="companion"] .sol-page-shell {
frontend/wrapper-ui/apc-wrapper-local/privatepages/sol.css:287:/* Companion tab must not expose study management GUI */
frontend/wrapper-ui/apc-wrapper-local/privatepages/sol.css:289:[data-private-page="companion"] .sol-study-box,
frontend/wrapper-ui/apc-wrapper-local/privatepages/sol.css:290:.private-shell[data-private-page="companion"] .sol-study-box {
frontend/wrapper-ui/apc-wrapper-local/index.html:5:  <meta name="viewport" content="width=device-width,initial-scale=1" />
frontend/wrapper-ui/apc-wrapper-local/index.html:8:  <link id="studyPreviewStyles" rel="stylesheet" href="/study/styles.css?v=20260612000409" disabled />
frontend/wrapper-ui/apc-wrapper-local/index.html:10:  <link rel="stylesheet" href="/header/header.css?v=spa-active-tabs-20260626" />
frontend/wrapper-ui/apc-wrapper-local/index.html:11:<link rel="stylesheet" href="/auth/auth.css?v=reset-password-page-20260626" />
frontend/wrapper-ui/apc-wrapper-local/index.html:12:  <link rel="stylesheet" href="/publicpages/publicpages.css?v=lavender-deep-green-20260626" />
frontend/wrapper-ui/apc-wrapper-local/index.html:13:  <link rel="stylesheet" href="/privatepages/sol.css?v=hide-companion-study-box-20260627" />
frontend/wrapper-ui/apc-wrapper-local/index.html:14:  <link rel="stylesheet" href="/privatepages/study-session.css?v=study-session-v2-20260626" />
frontend/wrapper-ui/apc-wrapper-local/index.html:41:    We’re working toward Google Drive sync so decks, cards, sessions, and study history can stay in each user’s own Google account.
frontend/wrapper-ui/apc-wrapper-local/index.html:46:  <script src="/header/header.js?v=spa-active-tabs-20260626"></script>
frontend/wrapper-ui/apc-wrapper-local/index.html:49:  <p>loading..</p>
frontend/wrapper-ui/apc-wrapper-local/index.html:76:  <section id="authModal" class="auth-modal hidden" aria-label="Login and register dialog">
frontend/wrapper-ui/apc-wrapper-local/index.html:77:    <div class="auth-card">
frontend/wrapper-ui/apc-wrapper-local/index.html:80:          <h2 id="authTitle">Login</h2>
frontend/wrapper-ui/apc-wrapper-local/index.html:81:          <p id="authSubtitle">Sign in to access your dashboard and future live services.</p>
frontend/wrapper-ui/apc-wrapper-local/index.html:84:        <button id="authCloseBtn" class="ghost-btn" type="button">
frontend/wrapper-ui/apc-wrapper-local/index.html:89:      <div class="auth-tabs">
frontend/wrapper-ui/apc-wrapper-local/index.html:90:        <button id="loginTabBtn" class="ghost-btn active" type="button">Login</button>
frontend/wrapper-ui/apc-wrapper-local/index.html:94:      <form id="authForm" class="auth-form">
frontend/wrapper-ui/apc-wrapper-local/index.html:97:          <input id="authEmail" type="email" autocomplete="email" required />
frontend/wrapper-ui/apc-wrapper-local/index.html:102:          <input id="authPassword" type="password" autocomplete="current-password" required />
frontend/wrapper-ui/apc-wrapper-local/index.html:105:        <button id="authSubmitBtn" class="primary-btn" type="submit">
frontend/wrapper-ui/apc-wrapper-local/index.html:110:      <div id="authMessage" class="notice hidden"></div>
frontend/wrapper-ui/apc-wrapper-local/index.html:115:  <script src="/router_shadow_read_stub.js?v=2026061208k"></script>
frontend/wrapper-ui/apc-wrapper-local/index.html:116:  <script src="/auth/auth.js?v=force-hard-logout-reload-20260626"></script>
frontend/wrapper-ui/apc-wrapper-local/index.html:117:  <script src="/auth/recover.js?v=recover-click-fix-20260626"></script>
frontend/wrapper-ui/apc-wrapper-local/index.html:118:  <script src="/auth/reset.js?v=reset-new-password-payload-fix-20260626"></script>
frontend/wrapper-ui/apc-wrapper-local/index.html:119:  <!-- <script src="/app.js?v=auth-aware-publicpages-20260626"></script> -->
frontend/wrapper-ui/apc-wrapper-local/index.html:120:  <script src="/publicpages/publicpages.js?v=auth-standalone-20260626"></script>
frontend/wrapper-ui/apc-wrapper-local/index.html:121:  <script src="/privatepages/privatepages.js?v=compact-companion-voice-20260626"></script>
frontend/wrapper-ui/apc-wrapper-local/index.html:122:  <script src="/privatepages/study-store.js?v=crud-writeback-r2-ui-args-20260627"></script>
frontend/wrapper-ui/apc-wrapper-local/index.html:123:  <script src="/privatepages/study.js?v=session-label-polish-20260627"></script>
frontend/wrapper-ui/apc-wrapper-local/index.html:124:  <script src="/privatepages/companion.js?v=global-drive-banner-r3p-20260627"></script>
