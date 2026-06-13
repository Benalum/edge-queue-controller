# Phase 11D System Page Double-Render Inspection

Phase 11D records the user-visible System page issue found after Phase 11C.

## Baseline

Previous checkpoint:

- Phase: Phase 11C
- Commit: 29805d9 style: polish admin system dashboard css phase 11c
- Tag: controller-phase-11c-admin-system-css-polish-2026-06-13
- Result: PASS

## User-visible issue

The `/system` page currently appears to render two different versions:

First render:

- Study API
- Companion API
- Profile API
- Calendar Integrations
- Images API

Second render shortly after:

- Backend API
- Frontend Wrapper
- Queue
- Workers
- CT101 Laptop Queue Worker
- Power Automation

This looks like a static placeholder/API catalog render being replaced by live system status after asynchronous loading.

## Goal

Inspect the frontend System page render path and prepare the safest next implementation stage.

## Safety posture

Phase 11D is read-only.

Allowed:

- Source inspection.
- GET-only route checks.
- Documentation.
- Smoke checkpoint.

Not allowed:

- No JavaScript implementation changes yet.
- No CSS changes.
- No Python/backend changes.
- No service restarts.
- No POST traffic.
- No router rollout.
- No auth boundary changes.

## Recommended Phase 11E implementation target

Phase 11E should make `/system` use one stable render path:

- Show one loading state while live status is loading.
- Then show one final live status layout.
- Do not show the old static API catalog first if it will immediately be replaced.
- Keep public/private boundaries unchanged.
- Keep Admin-only infrastructure details out of `/system`.
- Keep `/admin` as the admin infrastructure surface.

## Done criteria

Phase 11D is done when:

- This inspection document exists.
- A read-only smoke exists.
- The smoke captures relevant System render markers.
- `/system` returns HTTP 200.
- Static assets return HTTP 200.
- `/api/system/status` returns HTTP 200 JSON and remains fast.
- Router rollout remains parked.
- The checkpoint is committed, tagged, and pushed only after the smoke passes.

## Phase 11D Smoke Evidence

Generated: 2026-06-13T00:19:57-06:00

### Git

```text
29805d9 style: polish admin system dashboard css phase 11c
3523ff3 docs: inspect admin system dashboard polish phase 11b
7e1501e docs: add phase 11a post-transition product quality plan
9c3572f test: checkpoint transition complete baseline stage 10o
d0f5b4f test: verify post cache system status stability stage 10n
e53b0e3 perf: cache system status briefly stage 10m
eadbe18 test: inspect system status backend dependencies stage 10l
169393b docs: plan system status optimization stage 10k
controller-phase-11c-admin-system-css-polish-2026-06-13
```

### Selected gateways

```text
FRONTEND_BASE=http://127.0.0.1:8787
STATUS_BASE=http://127.0.0.1:8787
```

### System render markers

```text
36:let adminSystemStatus = null;
220:    title: "Calendar Integrations",
312: * - /api/study/* = laptop controller-owned Study API
313: * - /api/companion/* = laptop controller-owned Companion API
322: * or proxied to CT101 /api/* compatibility endpoints as appropriate.
687:  "ct101-laptop-queue-worker",
700:  "backend-api": "Backend API and controller services.",
704:  "ct101-laptop-queue-worker": "Managed CT101 worker processing queued chat jobs with guarded one-at-a-time execution.",
705:  "power-automation": "Power automation status.",
878:      name: "Study API",
884:      name: "Companion API",
890:      name: "Profile API",
896:      name: "Calendar Integrations",
902:      name: "Images API",
1705:function renderAdminSystemStatus() {
1706:  const payload = adminSystemStatus || {};
2550:function renderSystemPage() {
4588:    title: "Google Calendar and Apple Calendar integrations.",
4841:      ${isSystem ? renderSystemPage() : ""}
5046:let systemStatusLoadInFlight = null;
5048:async function loadSystemStatus() {
5051:  if (systemStatusLoadInFlight) {
5052:    return systemStatusLoadInFlight;
5055:  systemStatusLoadInFlight = (async () => {
5082:    return await systemStatusLoadInFlight;
5084:    systemStatusLoadInFlight = null;
5411:    await loadSystemStatus();
5438:  await loadSystemStatus();
5461:  await loadSystemStatus();
5494:loadSystemStatus();
5495:setInterval(loadSystemStatus, 60000);
6487:function cleanRemoveAdminInfrastructureFromSystemPage() {
6583:    cleanRemoveAdminInfrastructureFromSystemPage();
6633:      if (typeof loadSystemStatus === "function") {
6634:        await loadSystemStatus();
6767:  if (typeof loadSystemStatus === "function") {
6768:    jobs.push(loadSystemStatus());
7012:  // heartbeat after auth state changes. This is what powers CT101 for logged-in users.
```

### Recommendation

Phase 11E should remove the visible static-to-live System page swap by giving /system one stable render path: loading state first, then live status once loaded.
