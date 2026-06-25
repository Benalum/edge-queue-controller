# Stage 16 FC-O45-E-BK — Deploy Companion Structural Minimal over Tailscale Restricted Path

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `d4f45a7`
- Prior source tag: `controller-stage-16-fc-o45-e-bj-r4-companion-structural-minimal-source-2026-06-24`
- Prior restricted deploy tag: `controller-stage-16-fc-o45-e-bi-deploy-companion-dedupe-minimal-visible-over-tailscale-restricted-path-2026-06-24`

## Approval

This live static deploy was explicitly approved with:

```
APPROVE_FC_O45_E_BK_DEPLOY_COMPANION_STRUCTURAL_MINIMAL_OVER_TAILSCALE_RESTRICTED_PATH
```

## Deploy path

BK used the intended Tailscale/OpenSSH restricted deploy path:

```
cat package.tgz | ssh apcdeploy@website-edge 'deploy sha256=<sha256> bust=20260624fc045ebk'
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
- Public app.js contains BJ-R4 structural markers.
- Public `renderQueuedChatPage()` body was parsed and verified structural-minimal.
- Public `renderQueuedChatPage()` preserves existing queued-chat IDs.
- Public `renderQueuedChatPage()` excludes legacy signed-in Companion chrome copy.
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
/app.js?v=20260624fc045ebk
```

## Expected user-visible change

The signed-in Companion page should no longer render old UI and hide it afterward.

Expected visible primary flow:

```
Conversation
Type a message and press Enter to send.
Message
Send message
Clear
```

Expected absence:

- No old UI flash.
- No constant cleanup/reload feel from old Companion chrome scripts.
- No Thinking / Debug details / Study phrases / result-reader flicker.
- Existing queued-chat handlers remain compatible.
- Enter sends.
- Shift+Enter inserts a newline.

## Deploy output

```
=== Stage 16 FC-O45-E-BK deploy Companion structural minimal over Tailscale restricted path ===
APPROVAL=APPROVE_FC_O45_E_BK_DEPLOY_COMPANION_STRUCTURAL_MINIMAL_OVER_TAILSCALE_RESTRICTED_PATH
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
expected_head=d4f45a7
head_now=d4f45a7
origin_main_now=d4f45a7
git_preflight=PASS

=== source marker preflight ===
3740:  /* Stage 16 FC-O45-E-BJ-R4 Companion structural minimal source.
14153:/* Stage 16 FC-O45-E-BJ-R4 Companion structural minimal early flag.
15376:(function stage16FcO45EBjR4CompanionStructuralMinimalRuntime() {
15377:  if (window.__stage16FcO45EBjR4CompanionStructuralMinimalRuntimeInstalled) {
15380:  window.__stage16FcO45EBjR4CompanionStructuralMinimalRuntimeInstalled = true;
15412:    marker: "stage16FcO45EBjR4CompanionStructuralMinimalRuntime",
15411:  window.apcCompanionStructuralMinimalWorkspace = Object.freeze({
3722:  const el = document.getElementById("queuedChatMessages");
3763:          <div id="queuedChatMessages" class="stage5p8h-message-list"></div>
3767:          <label for="queuedChatInput">Message</label>
3768:          <textarea id="queuedChatInput" rows="5" placeholder="Message Companion..."></textarea>
4877:  const input = document.getElementById("queuedChatInput");
15384:    const textarea = document.getElementById("queuedChatInput");
3771:            <button class="stage5p8h-send-button" type="submit" id="queuedChatSendBtn">Send message</button>
4878:  const button = document.getElementById("queuedChatSendBtn");
3772:            <button class="stage5p8h-clear-button" type="button" id="queuedChatClearBtn">Clear</button>
5059:  const clearBtn = document.getElementById("queuedChatClearBtn");
3762:          <p class="stage16-fc-o45-e-bj-helper">Type a message and press Enter to send.</p>
14690:        node.textContent = "Type a message and press Enter to send.";
14875:      text.includes("Type a message and press Enter to send.") ||
14966:        node.textContent = "Type a message and press Enter to send.";
15024: * - Type a message and press Enter to send.
15123:        node.textContent = "Type a message and press Enter to send.";
15179: * - Type a message and press Enter to send.
3182:/* Stage 16 FC-O45-E-BJ-R4 Companion structural minimal CSS. */
source_structural_render_check=PASS

=== public pre-deploy state, read-only ===
pre_public_root_http=200
pre_public_app_js_http=200
pre_public_unauth_job132_http=401
pre_public_script_tags:
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045ebi"
<script src="/queued_chat_config.js"

=== create package and upload to PVEW ===
local_pkg_sha256=a0bd628209902fb53d68161f88737a5530bc279231a8b7583687c35fe24a956f
pkg_entry app.js
pkg_entry styles.css
pvew_package_upload=PASS

=== deploy over Tailscale restricted path from PVEW to VM200 ===
--- PVEW package verification ---
pvew
2026-06-25T01:34:44Z
pvew_pkg_sha256=a0bd628209902fb53d68161f88737a5530bc279231a8b7583687c35fe24a956f
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
received_pkg_sha256=a0bd628209902fb53d68161f88737a5530bc279231a8b7583687c35fe24a956f
backup_sha256 26deb9eff933624f3f68593d84181d6d4857a3ae91d2f77fc782b80391cdc3bb  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T013445Z/app.js
backup_sha256 1d01fdc9ecba9b50649e0ee3c0a223aed655a0959fba995d011523a7d7547cd6  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T013445Z/styles.css
backup_sha256 0aa67177b7c53a4c588d8bdbe7b808e9c68108025ca805cf8e211093426c2425  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T013445Z/index.html
backup_dir=/var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T013445Z
live_sha256 eb5f3fd81760668d31687971703e65c67b02d7ab8907ceee2eda422670aac2f3  /var/www/apc-wrapper-local/app.js
live_sha256 03b1e3e152b7ba70364e515096c079b61572d23f12ae626436296ee8f6714081  /var/www/apc-wrapper-local/styles.css
live_sha256 78a16e25cd96a25586caf36806b0c30ecdadcfa10d8bbf2f95b27b4ea0f7abeb  /var/www/apc-wrapper-local/index.html
APC_VM200_STATIC_DEPLOY_WRAPPER_UI_PASS cache_bust=20260624fc045ebk
restricted_tailscale_deploy=PASS
FC_O45_E_BK_RESTRICTED_DEPLOY_RECORDED

=== public post-deploy verification ===
post_public_root_http=200
post_public_app_js_http=200
post_public_unauth_job132_http=401
{"detail":"Missing bearer token."}
post_public_script_tags:
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045ebk"
<script src="/queued_chat_config.js"

post_public_structural_render_check=PASS
post_public_verification=PASS
FC_O45_E_BK_DEPLOY_RECORDED new_app_js_bust=20260624fc045ebk
```
