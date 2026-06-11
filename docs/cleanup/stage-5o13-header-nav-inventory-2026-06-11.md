# Stage 5O-13 Header/Nav Inventory — 2026-06-11

## HTML nav
12:    <a class="brand logo-only" href="/" data-route="/" aria-label="AlexHartel AI Platform home">
23:    <nav class="nav" aria-label="Main navigation">
24:      <a href="/study" data-route="/study">Study</a>
25:      <a href="/companion" data-route="/companion">Companion</a>
26:      <a href="/profile" data-route="/profile">Profile</a>
27:      <a href="/support" data-route="/support">Support</a>
28:      <a id="adminNavLink" class="hidden" href="/admin" data-route="/admin">Admin</a>
29:      <a href="/system" data-route="/system" id="systemNavLink">
34:      <button id="creditsPill" class="credits-pill hidden" type="button" data-route="/credits" title="View credits and plans">

## App route/nav logic

## CSS header/nav/credits rules
35:.topbar {
342:  .topbar {
557:   Header credits display
560:.credits-pill {
573:.credits-pill small {
582:.credits-pill {
769:.credits-pill {
778:.credits-total {
783:.credits-breakdown {
789:.credits-pill:hover {
794:  .credits-pill {
798:  .credits-breakdown {
1368:.topbar a[data-route],
1369:.main-nav a[data-route],
1370:.route-nav a[data-route],
1375:.topbar a[href^="/"],
1376:.main-nav a[href^="/"],
1377:.route-nav a[href^="/"],
1387:header a[data-route][aria-current="page"],
1388:.topbar a[data-route].active,
1389:.topbar a[data-route].is-active,
1390:.topbar a[data-route].selected,
1391:.topbar a[data-route][aria-current="page"],
1392:.main-nav a[data-route].active,
1393:.main-nav a[data-route].is-active,
1394:.main-nav a[data-route].selected,
1395:.main-nav a[data-route][aria-current="page"],
1396:.route-nav a[data-route].active,
1397:.route-nav a[data-route].is-active,
1398:.route-nav a[data-route].selected,
1399:.route-nav a[data-route][aria-current="page"],
1403:.nav a[data-route][aria-current="page"],
1407:.tabs a[data-route][aria-current="page"],
1411:.tabbar a[data-route][aria-current="page"] {
1418:/* Prevent stale route state from leaving Credits permanently green. */
1419:body:not([data-current-route="/credits"]) header a[href="/credits"]:not([aria-current="page"]),
1420:body:not([data-current-route="/credits"]) header a[data-route="/credits"]:not([aria-current="page"]),
1421:body:not([data-current-route="/credits"]) .topbar a[href="/credits"]:not([aria-current="page"]),
1422:body:not([data-current-route="/credits"]) .topbar a[data-route="/credits"]:not([aria-current="page"]),
1423:body:not([data-current-route="/credits"]) .main-nav a[href="/credits"]:not([aria-current="page"]),
1424:body:not([data-current-route="/credits"]) .main-nav a[data-route="/credits"]:not([aria-current="page"]),
1425:body:not([data-current-route="/credits"]) .route-nav a[href="/credits"]:not([aria-current="page"]),
1426:body:not([data-current-route="/credits"]) .route-nav a[data-route="/credits"]:not([aria-current="page"]) {
1435:   The credits header pill displays account balance. It must not look like
1436:   the selected page unless the current route is /credits.
1439:#creditsPill,
1440:.credits-pill {
1447:#creditsPill:hover,
1448:.credits-pill:hover {
1455:body[data-current-route="/credits"] #creditsPill,
1456:body[data-current-route="/credits"] .credits-pill,
1457:#creditsPill.route-active,
1458:.credits-pill.route-active {
