# Stage 5O-11 Deep Route Reload Inventory — 2026-06-11

## Reload/navigation patterns

frontend/wrapper-ui/styles.css:1419:body:not([data-current-route="/credits"]) header a[href="/credits"]:not([aria-current="page"]),
frontend/wrapper-ui/styles.css:1421:body:not([data-current-route="/credits"]) .topbar a[href="/credits"]:not([aria-current="page"]),
frontend/wrapper-ui/styles.css:1423:body:not([data-current-route="/credits"]) .main-nav a[href="/credits"]:not([aria-current="page"]),
frontend/wrapper-ui/styles.css:1425:body:not([data-current-route="/credits"]) .route-nav a[href="/credits"]:not([aria-current="page"]),
frontend/wrapper-ui/index.html:7:  <link rel="stylesheet" href="./styles.css" />
frontend/wrapper-ui/index.html:8:  <link id="studyPreviewStyles" rel="stylesheet" href="/study/styles.css" disabled />
frontend/wrapper-ui/index.html:12:    <a class="brand logo-only" href="/" data-route="/" aria-label="AlexHartel AI Platform home">
frontend/wrapper-ui/index.html:24:      <a href="/study" data-route="/study">Study</a>
frontend/wrapper-ui/index.html:25:      <a href="/companion" data-route="/companion">Companion</a>
frontend/wrapper-ui/index.html:26:      <a href="/profile" data-route="/profile">Profile</a>
frontend/wrapper-ui/index.html:27:      <a href="/support" data-route="/support">Support</a>
frontend/wrapper-ui/index.html:28:      <a id="adminNavLink" class="hidden" href="/admin" data-route="/admin">Admin</a>
frontend/wrapper-ui/index.html:29:      <a href="/system" data-route="/system" id="systemNavLink">
frontend/wrapper-ui/app.js:134:  // invalidation/refresh layer, not by adding ?fresh= timestamps to URLs.
frontend/wrapper-ui/app.js:136:    const cleanPath = String(window.location.pathname || "/").split("?")[0].split("#")[0] || "/";
frontend/wrapper-ui/app.js:288:  const path = window.location.pathname || "/";
frontend/wrapper-ui/app.js:2628:      <p>This shared-layout preview is read-only. Use <a href="/study">the live Study page</a> to create decks, add cards, or review cards.</p>
frontend/wrapper-ui/app.js:3200:  const isLiveStudyRoute = window.location.pathname === "/study";
frontend/wrapper-ui/app.js:3229:            <a class="primary-btn" href="/study">Open Live Study</a>
frontend/wrapper-ui/app.js:3230:            <a class="secondary" href="/study-standalone">Open Standalone Fallback</a>
frontend/wrapper-ui/app.js:3943:  const url = new URL(window.location.href);
frontend/wrapper-ui/app.js:3976:        window.location.href = "/";
frontend/wrapper-ui/app.js:4555:      <a class="feature-card" href="/support" data-route="/support">
frontend/wrapper-ui/app.js:4560:      <a class="feature-card" href="/support" data-route="/support">
frontend/wrapper-ui/app.js:4565:      <a class="feature-card" href="/support" data-route="/support">
frontend/wrapper-ui/app.js:4570:      <a class="feature-card" href="/support" data-route="/support">
frontend/wrapper-ui/app.js:5802:  const href = link.getAttribute("href");
frontend/wrapper-ui/app.js:5821:  location.href = target.toString();
frontend/wrapper-ui/app.js:5904:  const url = new URL(window.location.href);
frontend/wrapper-ui/app.js:6895:    return normalizeRoute(window.location.pathname || "/");
frontend/wrapper-ui/app.js:6904:    const href = anchor.getAttribute("href") || "";
frontend/wrapper-ui/app.js:6908:      const url = new URL(href, window.location.origin);
frontend/wrapper-ui/app.js:6909:      if (url.origin !== window.location.origin) return "";
frontend/wrapper-ui/app.js:7015:    const current = cleanRoute(window.location.pathname || "/");
frontend/wrapper-ui/app.js:7055:// Defensive cleanup for old/stale links that still include ?fresh=.
frontend/wrapper-ui/app.js:7060:      const url = new URL(window.location.href);

## Route click handlers

138:      window.history.replaceState({}, "", cleanPath);
140:        renderRoute(cleanPath);
347:  document.querySelectorAll("[data-route]").forEach((link) => {
348:    link.classList.toggle("active", link.getAttribute("data-route") === path);
399:  const supportLink = document.querySelector('[data-route="/support"]');
465:function navigate(path) {
467:  history.pushState({}, "", path);
600:                renderPage();
661:renderPage();
1212:    renderPage();
1248:    renderPage();
1293:    renderPage();
1395:    renderPage();
1433:    renderPage();
1471:    renderPage();
1597:    renderPage();
1629:    renderPage();
1866:    renderPage();
1906:    renderPage();
1950:  renderPage();
2850:  document.getElementById("studyPreviewShowAnswerBtn")?.addEventListener("click", () => {
2855:  document.getElementById("studyPreviewSkipCardBtn")?.addEventListener("click", () => {
2861:  document.getElementById("studyPreviewWrongBtn")?.addEventListener("click", () => {
2865:  document.getElementById("studyPreviewCorrectBtn")?.addEventListener("click", () => {
3484:function renderPage() {
3532:    btn.addEventListener("click", () => navigate(btn.getAttribute("data-go")));
3535:  $("openSystemBtn")?.addEventListener("click", openSystemDrawer);
3536:  $("wakeLoginBtn")?.addEventListener("click", () => {
3541:  $("claimAdRewardBtn")?.addEventListener("click", claimMockAdReward);
3542:  $("showGoogleRewardedAdBtn")?.addEventListener("click", loadGoogleRewardedAd);
3543:  $("gpuQuoteBtn")?.addEventListener("click", quoteMockGpuSession);
3544:  $("gpuReserveQuoteBtn")?.addEventListener("click", reserveMockGpuQuote);
3545:  $("adminGrantCreditsBtn")?.addEventListener("click", adminGrantCredits);
3547:  $("supportCreateTicketBtn")?.addEventListener("click", createSupportTicket);
3548:  $("supportReplyBtn")?.addEventListener("click", (event) => {
3553:    button.addEventListener("click", () => loadSupportThread(button.dataset.openTicket));
3556:  $("gpuStartSessionBtn")?.addEventListener("click", (buttonEvent) => {
3562:    button.addEventListener("click", () => stopMockGpuSession(button.dataset.stopGpuSession));
3565:    button.addEventListener("click", () => cleanupMockGpuSession(button.dataset.cleanupGpuSession));
3568:    button.addEventListener("click", () => refundReservationToken(button.dataset.refundToken));
3689:    renderPage();
3763:  renderPage();
3788:    btn.addEventListener("click", resendVerificationEmail);
3953:    window.history.replaceState({}, "", "/");
3973:      window.history.replaceState({}, "", "/");
3983:    window.history.replaceState({}, "", "/");
4000:    window.history.replaceState({}, "", "/");
4095:    renderPage();
4122:  renderPage();
4145:  renderPage();
4148:document.addEventListener("click", (event) => {
4149:  const link = event.target.closest("[data-route]");
4152:  const path = link.getAttribute("data-route");
4156:  navigate(path);
4161:$("drawerCloseBtn").addEventListener("click", closeSystemDrawer);
4162:$("authOpenBtn").addEventListener("click", () => openAuthModal("login"));
4163:$("logoutBtn").addEventListener("click", logout);
4164:$("authCloseBtn").addEventListener("click", closeAuthModal);
4165:$("loginTabBtn").addEventListener("click", () => setAuthMode("login"));
4166:$("registerTabBtn").addEventListener("click", () => setAuthMode("register"));
4167:$("resendVerificationBtn")?.addEventListener("click", resendVerificationEmail);
4175:renderPage();
4235:  const supportLink = document.querySelector('[data-route="/support"]');
4555:      <a class="feature-card" href="/support" data-route="/support">
4560:      <a class="feature-card" href="/support" data-route="/support">
4565:      <a class="feature-card" href="/support" data-route="/support">
4570:      <a class="feature-card" href="/support" data-route="/support">
5172:  document.getElementById("cleanCreateSupportTicketBtn")?.addEventListener("click", cleanCreateSupportTicket);
5173:  document.getElementById("cleanAdminGrantCreditsBtn")?.addEventListener("click", cleanAdminGrantCredits);
5178:    btn.addEventListener("click", () => cleanOpenTicket(btn.dataset.cleanOpenTicket));
5184:    btn.addEventListener("click", () => cleanSendReply(btn.dataset.cleanReplyTicket));
5190:    btn.addEventListener("click", () => cleanSetTicketStatus(btn.dataset.cleanSolveTicket, "solved"));
5196:    btn.addEventListener("click", () => cleanSetTicketStatus(btn.dataset.cleanReopenTicket, "waiting_admin"));
5202:    btn.addEventListener("click", () => openAuthModal("login"));
5205:  document.getElementById("cleanToggleAdminSystemDetailsBtn")?.addEventListener("click", () => {
5245:  renderPage();
5248:document.addEventListener("click", async (event) => {
5249:  const link = event.target.closest?.("[data-route]");
5257:  history.pushState({}, "", route);
5260:  renderPage();
5271:  renderPage();
5305:      renderPage();
5434:    renderPage();
5499:    renderPage();
5539:    renderPage();
5559:document.addEventListener("click", fastHandleLogoutClick, true);
5660:document.addEventListener("click", (event) => {
5769:    renderPage();
5780:    renderPage();
5798:document.addEventListener("click", (event) => {
5845:    btn.addEventListener("click", requestPasswordResetFromLogin);
5914:    window.history.replaceState({}, "", "/");
5925:    window.history.replaceState({}, "", "/");
5934:    window.history.replaceState({}, "", "/");
5949:    window.history.replaceState({}, "", "/");
5959:    window.history.replaceState({}, "", "/");
6901:    const dataRoute = anchor.getAttribute("data-route");
6942:      "header a, .topbar a, .main-nav a, .route-nav a, .nav a, .tabs a, .tabbar a, [data-route]"
6969:  const originalPushState = history.pushState;
6970:  history.pushState = function patchedPushState() {
6976:  const originalReplaceState = history.replaceState;
6977:  history.replaceState = function patchedReplaceState() {
6986:  document.addEventListener("click", function onPossibleRouteClick(event) {
7044:  document.addEventListener("click", scheduleCreditsPillRouteState, true);
7069:      window.history.replaceState({}, "", clean || "/");
