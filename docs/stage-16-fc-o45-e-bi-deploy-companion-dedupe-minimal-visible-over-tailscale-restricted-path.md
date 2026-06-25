# Stage 16 FC-O45-E-BI — Deploy Companion Dedupe Minimal Visible over Tailscale Restricted Path

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `fb6e44c`
- Prior source tag: `controller-stage-16-fc-o45-e-bh-companion-dedupe-minimal-visible-source-2026-06-24`
- Prior restricted deploy tag: `controller-stage-16-fc-o45-e-bg-deploy-companion-minimal-chat-over-tailscale-restricted-path-2026-06-24`

## Approval

This live static deploy was explicitly approved with:

```
APPROVE_FC_O45_E_BI_DEPLOY_COMPANION_DEDUPE_MINIMAL_VISIBLE_OVER_TAILSCALE_RESTRICTED_PATH
```

## Deploy path

BI used the intended Tailscale/OpenSSH restricted deploy path:

```
cat package.tgz | ssh apcdeploy@website-edge 'deploy sha256=<sha256> bust=20260624fc045ebi'
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
- Public app.js contains BH dedupe/minimal-visible markers.
- Public app.js contains `dedupeVisibleMessages`.
- Public app.js contains `hideRemainingChrome`.
- Public app.js contains `companion-dedupe-minimal-hidden`.
- Public app.js contains `installEnterToSend`.
- Public app.js contains `Type a message and press Enter to send.`
- Public app.js contains updated model label `fallback: qwen2.5:0.5b`.
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
/app.js?v=20260624fc045ebi
```

## Expected user-visible change

The Companion page should retain the minimal chat flow while hiding remaining chrome and duplicate rows:

```
Conversation
Type a message and press Enter to send.
Message
Send message
Clear
```

Corrected from BG observation:

- Hide Thinking / Debug details / Study phrases chrome.
- Hide decorative chat icon.
- Deduplicate repeated visible user/assistant message rows.
- Enter still sends.
- Shift+Enter still inserts a newline.

## Deploy output

```
=== Stage 16 FC-O45-E-BI deploy Companion dedupe minimal visible over Tailscale restricted path ===
APPROVAL=APPROVE_FC_O45_E_BI_DEPLOY_COMPANION_DEDUPE_MINIMAL_VISIBLE_OVER_TAILSCALE_RESTRICTED_PATH
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
expected_head=fb6e44c
head_now=fb6e44c
origin_main_now=fb6e44c
git_preflight=PASS

=== source marker preflight ===
15052: * Stage 16 FC-O45-E-BF Companion minimal chat source.
15201: * Stage 16 FC-O45-E-BH Companion dedupe minimal visible source.
15387:  window.apcCompanionDedupeMinimalVisible = Object.freeze({
15336:  function dedupeVisibleMessages(root) {
15366:    dedupeVisibleMessages(root);
15390:    dedupeVisibleMessages,
15284:  function hideRemainingChrome(root) {
15365:    hideRemainingChrome(root);
15391:    hideRemainingChrome,
frontend/wrapper-ui/app.js:15233:    node.classList.add("companion-dedupe-minimal-hidden");
frontend/wrapper-ui/app.js:15245:      node.classList.contains("companion-dedupe-minimal-hidden") ||
frontend/wrapper-ui/styles.css:3114:.companion-dedupe-minimal-hidden,
14760:  function installEnterToSend() {
14791:    installEnterToSend();
14815:    installEnterToSend,
15011:    if (window.apcCompanionCleanChatWorkspace && typeof window.apcCompanionCleanChatWorkspace.installEnterToSend === "function") {
15012:      window.apcCompanionCleanChatWorkspace.installEnterToSend();
15161:    if (window.apcCompanionCleanChatWorkspace && typeof window.apcCompanionCleanChatWorkspace.installEnterToSend === "function") {
15162:      window.apcCompanionCleanChatWorkspace.installEnterToSend();
15358:    if (window.apcCompanionCleanChatWorkspace && typeof window.apcCompanionCleanChatWorkspace.installEnterToSend === "function") {
15359:      window.apcCompanionCleanChatWorkspace.installEnterToSend();
14733:        node.textContent = "Type a message and press Enter to send.";
14913:      text.includes("Type a message and press Enter to send.") ||
15004:        node.textContent = "Type a message and press Enter to send.";
15062: * - Type a message and press Enter to send.
15156:        node.textContent = "Type a message and press Enter to send.";
15212: * - Type a message and press Enter to send.
3813:              <strong>fallback: qwen2.5:0.5b</strong>
14604:        node.textContent = "fallback: qwen2.5:0.5b";
14878:        "Worker Companion queue worker Model fallback: qwen2.5:0.5b"
3113:/* Stage 16 FC-O45-E-BH Companion dedupe minimal visible CSS. */

=== public pre-deploy state, read-only ===
pre_public_root_http=200
pre_public_app_js_http=200
pre_public_unauth_job132_http=401
pre_public_script_tags:
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045ebg"
<script src="/queued_chat_config.js"

=== create package and upload to PVEW ===
local_pkg_sha256=8a62164828033767fdcdf703fbe25dea2b07e8619661f235040177059eb02a44
pkg_entry app.js
pkg_entry styles.css
pvew_package_upload=PASS

=== deploy over Tailscale restricted path from PVEW to VM200 ===
--- PVEW package verification ---
pvew
2026-06-25T01:18:50Z
pvew_pkg_sha256=8a62164828033767fdcdf703fbe25dea2b07e8619661f235040177059eb02a44
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
received_pkg_sha256=8a62164828033767fdcdf703fbe25dea2b07e8619661f235040177059eb02a44
backup_sha256 96aa84cd07052fa8e815fdf271e0e507e94711caf69e6fe804ecb526afe8ac75  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T011850Z/app.js
backup_sha256 3101eb843ee59dad9f21ffe29c3393570a723bb7f0f35270c94fb1d7b80e288a  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T011850Z/styles.css
backup_sha256 ca9ce781f3f1ffeefba4b231e4055df0b3b1b9b4260535afb11746cc7448925b  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T011850Z/index.html
backup_dir=/var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T011850Z
live_sha256 26deb9eff933624f3f68593d84181d6d4857a3ae91d2f77fc782b80391cdc3bb  /var/www/apc-wrapper-local/app.js
live_sha256 1d01fdc9ecba9b50649e0ee3c0a223aed655a0959fba995d011523a7d7547cd6  /var/www/apc-wrapper-local/styles.css
live_sha256 0aa67177b7c53a4c588d8bdbe7b808e9c68108025ca805cf8e211093426c2425  /var/www/apc-wrapper-local/index.html
APC_VM200_STATIC_DEPLOY_WRAPPER_UI_PASS cache_bust=20260624fc045ebi
restricted_tailscale_deploy=PASS
FC_O45_E_BI_RESTRICTED_DEPLOY_RECORDED

=== public post-deploy verification ===
post_public_root_http=200
post_public_app_js_http=200
post_public_unauth_job132_http=401
{"detail":"Missing bearer token."}
post_public_script_tags:
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045ebi"
<script src="/queued_chat_config.js"

post_public_verification=PASS
FC_O45_E_BI_DEPLOY_RECORDED new_app_js_bust=20260624fc045ebi
```
