# Stage 16 FC-O45-E-BL — Companion Delegated Enter-to-Send Source

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `d0e5e90`
- Prior deploy tag: `controller-stage-16-fc-o45-e-bk-deploy-companion-structural-minimal-over-tailscale-restricted-path-2026-06-24`

## Purpose

After BK, the Companion page rendered structurally minimal, but browser observation showed Enter did not send.

Cause:

- The helper was still route-timing dependent.
- The Companion tab can render `#queuedChatInput` after helper setup runs.

BL fixes this with a delegated keydown handler on `document`, targeting future `#queuedChatInput` nodes.

## Scope

Modified repo source only:

- `frontend/wrapper-ui/app.js`
- `docs/stage-16-fc-o45-e-bl-companion-enter-delegated-source.md`
- `ops/smoke/check-stage-16-fc-o45-e-bl-companion-enter-delegated-source.sh`

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

## Source behavior

BL adds:

- `Stage 16 FC-O45-E-BL Companion delegated Enter-to-send source`
- `stage16FcO45EBlCompanionDelegatedEnterToSend`
- `window.apcCompanionDelegatedEnterToSend`

Behavior:

- Enter in `#queuedChatInput` submits `#queuedChatForm`.
- Shift+Enter still inserts a newline.
- Ctrl/Alt/Meta Enter are not intercepted.
- No MutationObserver is added.
- No old UI cleanup loop is added.
- Existing click Send behavior is preserved.

## Model response note

The current queued reply saying `mock/no-model` is separate from Enter-to-send.

It means jobs are being created, but no approved model worker is currently active to claim and complete them.

## Output

```
=== Stage 16 FC-O45-E-BL Companion delegated Enter-to-send source ===
MUTATION_SCOPE=repo_source_docs_smoke_commit_tag_push_only
FIX=enter_to_send_route_timing_without_mutation_observer
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

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=d0e5e90
head_now=d0e5e90
origin_main_now=d0e5e90
git_preflight=PASS

=== source marker preflight ===
3740:  /* Stage 16 FC-O45-E-BJ-R4 Companion structural minimal source.
3767:          <label for="queuedChatInput">Message</label>
3768:          <textarea id="queuedChatInput" rows="5" placeholder="Message Companion..."></textarea>
4877:  const input = document.getElementById("queuedChatInput");
15384:    const textarea = document.getElementById("queuedChatInput");
3766:        <form id="queuedChatForm" class="stage5p8h-message-form">
5054:  const form = document.getElementById("queuedChatForm");
15383:    const form = document.getElementById("queuedChatForm");
3771:            <button class="stage5p8h-send-button" type="submit" id="queuedChatSendBtn">Send message</button>
4878:  const button = document.getElementById("queuedChatSendBtn");

=== apply BL source patch ===
=== syntax and marker checks ===
15423: * Stage 16 FC-O45-E-BL Companion delegated Enter-to-send source.
15429:(function stage16FcO45EBlCompanionDelegatedEnterToSend() {
15430:  if (window.__stage16FcO45EBlCompanionDelegatedEnterToSendInstalled) {
15433:  window.__stage16FcO45EBlCompanionDelegatedEnterToSendInstalled = true;
15464:    marker: "stage16FcO45EBlCompanionDelegatedEnterToSend",
15463:  window.apcCompanionDelegatedEnterToSend = Object.freeze({
15437:    if (!target || target.id !== "queuedChatInput") {
5054:  const form = document.getElementById("queuedChatForm");
15383:    const form = document.getElementById("queuedChatForm");
15444:    const form = document.getElementById("queuedChatForm");
4878:  const button = document.getElementById("queuedChatSendBtn");
15454:      const submit = document.getElementById("queuedChatSendBtn");
source_patch=PASS
```
