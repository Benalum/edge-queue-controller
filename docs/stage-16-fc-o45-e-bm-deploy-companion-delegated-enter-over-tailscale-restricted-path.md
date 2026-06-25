# Stage 16 FC-O45-E-BM — Deploy Companion Delegated Enter-to-Send over Tailscale Restricted Path

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `3782ecf`
- Prior source tag: `controller-stage-16-fc-o45-e-bl-companion-enter-delegated-source-2026-06-24`
- Prior restricted deploy tag: `controller-stage-16-fc-o45-e-bk-deploy-companion-structural-minimal-over-tailscale-restricted-path-2026-06-24`

## Approval

This live static deploy was explicitly approved with:

```
APPROVE_FC_O45_E_BM_DEPLOY_COMPANION_DELEGATED_ENTER_OVER_TAILSCALE_RESTRICTED_PATH
```

## Deploy path

BM used the intended Tailscale/OpenSSH restricted deploy path:

```
cat package.tgz | ssh apcdeploy@website-edge 'deploy sha256=<sha256> bust=20260624fc045ebm'
```

No QGA package transfer was used.

## Scope

Allowed and performed:

- Packaged repo `frontend/wrapper-ui/app.js` and `frontend/wrapper-ui/styles.css`.
- Copied the package to PVEW staging `/tmp`.
- PVEW sent the package to VM200 over Tailscale/OpenSSH as `apcdeploy@website-edge`.
- VM200 restricted helper verified package SHA-256 and required markers.
- VM200 restricted helper backed up current live `app.js`, `styles.css`, and `index.html`.
- VM200 restricted helper replaced only `app.js` and `styles.css`.
- VM200 restricted helper updated only the `index.html` app.js cache-bust.
- Public root returned HTTP 200.
- Public cache-busted app.js returned HTTP 200.
- Public app.js contains BL delegated Enter-to-send markers.
- Public app.js contains BJ-R4 structural minimal renderer markers.
- Public app.js confirms BL did not add a MutationObserver.
- Unauthenticated job132 result endpoint remained protected.

Explicitly not allowed and not performed:

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
- NO file deletion.
- NO QGA package transfer.

## Public cache bust

```
/app.js?v=20260624fc045ebm
```

## Expected user-visible change

- Enter in the Companion message box submits.
- Shift+Enter inserts a newline.
- The minimal structural Companion UI remains.
- The queued/mock/no-model message may still appear until a model worker is explicitly activated.

## Separate remaining issue

The current `mock/no-model` response means jobs are being created but no approved model worker is currently active to claim and complete them.

## Deploy output

```
=== Stage 16 FC-O45-E-BM deploy Companion delegated Enter-to-send over Tailscale restricted path ===
APPROVAL=APPROVE_FC_O45_E_BM_DEPLOY_COMPANION_DELEGATED_ENTER_OVER_TAILSCALE_RESTRICTED_PATH
MUTATION_SCOPE=vm200_static_wrapper_ui_deploy_over_tailscale_restricted_forced_command_plus_repo_doc_smoke_commit_tag_push
ALLOWED: package repo frontend/wrapper-ui app.js and styles.css
ALLOWED: copy package to PVEW staging /tmp
ALLOWED: PVEW sends package to VM200 over Tailscale/OpenSSH as apcdeploy@website-edge
ALLOWED: VM200 restricted helper verifies package SHA-256 and markers
ALLOWED: VM200 restricted helper backs up current live app.js/styles.css/index.html
ALLOWED: VM200 restricted helper replaces only app.js and styles.css
ALLOWED: VM200 restricted helper updates only index.html app.js cache bust
ALLOWED: public HTTP marker verification
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
NO file deletion
NO QGA package transfer

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=3782ecf
head_now=3782ecf
origin_main_now=3782ecf
git_preflight=PASS

=== source marker preflight ===
3740:  /* Stage 16 FC-O45-E-BJ-R4 Companion structural minimal source.
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
3767:          <label for="queuedChatInput">Message</label>
3768:          <textarea id="queuedChatInput" rows="5" placeholder="Message Companion..."></textarea>
4877:  const input = document.getElementById("queuedChatInput");
15384:    const textarea = document.getElementById("queuedChatInput");
15426: * This is delegated on document, so it works for future #queuedChatInput nodes.
15437:    if (!target || target.id !== "queuedChatInput") {
15465:    inputId: "queuedChatInput",
3766:        <form id="queuedChatForm" class="stage5p8h-message-form">
5054:  const form = document.getElementById("queuedChatForm");
15383:    const form = document.getElementById("queuedChatForm");
15444:    const form = document.getElementById("queuedChatForm");
15466:    formId: "queuedChatForm",
3771:            <button class="stage5p8h-send-button" type="submit" id="queuedChatSendBtn">Send message</button>
4878:  const button = document.getElementById("queuedChatSendBtn");
15454:      const submit = document.getElementById("queuedChatSendBtn");
15467:    sendButtonId: "queuedChatSendBtn",
3762:          <p class="stage16-fc-o45-e-bj-helper">Type a message and press Enter to send.</p>
14690:        node.textContent = "Type a message and press Enter to send.";
14875:      text.includes("Type a message and press Enter to send.") ||
14966:        node.textContent = "Type a message and press Enter to send.";
15024: * - Type a message and press Enter to send.
15123:        node.textContent = "Type a message and press Enter to send.";
15179: * - Type a message and press Enter to send.
source_delegated_enter_check=PASS

=== public pre-deploy state, read-only ===
pre_public_root_http=200
pre_public_app_js_http=200
pre_public_unauth_job132_http=401
pre_public_script_tags:
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045ebk"
<script src="/queued_chat_config.js"

=== create package and upload to PVEW ===
local_pkg_sha256=8a1ed52677d25179048b2b43c18ff94cae1ed1059d490fc16801de6ced13ee23
pkg_entry app.js
pkg_entry styles.css
pvew_package_upload=PASS

=== deploy over Tailscale restricted path from PVEW to VM200 ===
--- PVEW package verification ---
pvew
2026-06-25T01:42:14Z
pvew_pkg_sha256=8a1ed52677d25179048b2b43c18ff94cae1ed1059d490fc16801de6ced13ee23
pvew_pkg_entry app.js
pvew_pkg_entry styles.css
pvew_package_verify=PASS

--- restricted forced-command probe before deploy ---
forced_command_probe_rc=64
REFUSE_STATIC_DEPLOY_BAD_ORIGINAL_COMMAND
expected: deploy sha256=<64 lowercase hex> bust=<cache-bust-token>
forced_command_probe=PASS

--- restricted deploy over Tailscale/OpenSSH ---
restricted_deploy_rc=0
received_pkg_sha256=8a1ed52677d25179048b2b43c18ff94cae1ed1059d490fc16801de6ced13ee23
backup_sha256 eb5f3fd81760668d31687971703e65c67b02d7ab8907ceee2eda422670aac2f3  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T014215Z/app.js
backup_sha256 03b1e3e152b7ba70364e515096c079b61572d23f12ae626436296ee8f6714081  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T014215Z/styles.css
backup_sha256 78a16e25cd96a25586caf36806b0c30ecdadcfa10d8bbf2f95b27b4ea0f7abeb  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T014215Z/index.html
backup_dir=/var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T014215Z
live_sha256 0003f92ea766e42f94c79216897e4049f18ce321b410dc48ee918d2197a77351  /var/www/apc-wrapper-local/app.js
live_sha256 03b1e3e152b7ba70364e515096c079b61572d23f12ae626436296ee8f6714081  /var/www/apc-wrapper-local/styles.css
live_sha256 5f985fd0ca1556403dd86c2a78ff0176c5b4395786a68cd50ae5424b3db03f32  /var/www/apc-wrapper-local/index.html
APC_VM200_STATIC_DEPLOY_WRAPPER_UI_PASS cache_bust=20260624fc045ebm
restricted_tailscale_deploy=PASS
FC_O45_E_BM_RESTRICTED_DEPLOY_RECORDED

=== public post-deploy verification ===
post_public_root_http=200
post_public_app_js_http=200
post_public_unauth_job132_http=401
{"detail":"Missing bearer token."}
post_public_script_tags:
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045ebm"
<script src="/queued_chat_config.js"

post_public_delegated_enter_check=PASS
post_public_verification=PASS
FC_O45_E_BM_DEPLOY_RECORDED new_app_js_bust=20260624fc045ebm
```
