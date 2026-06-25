# Stage 16 FC-O45-E-BG — Deploy Companion Minimal Chat over Tailscale Restricted Path

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `1d7fbd8`
- Prior source tag: `controller-stage-16-fc-o45-e-bf-companion-minimal-chat-source-2026-06-24`
- Prior restricted deploy tag: `controller-stage-16-fc-o45-e-be-deploy-companion-hard-clean-workspace-over-tailscale-restricted-path-2026-06-24`

## Approval

This live static deploy was explicitly approved with:

```
APPROVE_FC_O45_E_BG_DEPLOY_COMPANION_MINIMAL_CHAT_OVER_TAILSCALE_RESTRICTED_PATH
```

## Deploy path

BG used the intended Tailscale/OpenSSH restricted deploy path:

```
cat package.tgz | ssh apcdeploy@website-edge 'deploy sha256=<sha256> bust=20260624fc045ebg'
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
- Public app.js contains BF minimal-chat markers.
- Public app.js contains `hideImmersionChrome`.
- Public app.js contains `hideExtraChatCardHeadingAndCopy`.
- Public app.js contains `companion-minimal-chat-hidden`.
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
/app.js?v=20260624fc045ebg
```

## Expected user-visible change

The Companion page should now show the minimal chat flow:

```
Conversation
Type a message and press Enter to send.
Message
Send message
Clear
```

Hidden from the primary flow:

- Listening / Debug details Immersion chrome
- Companion page header chrome
- Extra `Chat with your Companion` heading
- Queued endpoint explanation copy
- Legacy status/help/study/result-reader panels

Message behavior:

- Enter sends the message.
- Shift+Enter inserts a newline.

## Deploy output

```
=== Stage 16 FC-O45-E-BG deploy Companion minimal chat over Tailscale restricted path ===
APPROVAL=APPROVE_FC_O45_E_BG_DEPLOY_COMPANION_MINIMAL_CHAT_OVER_TAILSCALE_RESTRICTED_PATH
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
expected_head=1d7fbd8
head_now=1d7fbd8
origin_main_now=1d7fbd8
git_preflight=PASS

=== source marker preflight ===
13991:    title.textContent = "Companion result reader";
14647: * - Hide Companion auth test, Companion status, How this works, Study phrases, and Companion result reader from the primary user flow.
14842: * - Companion result reader
14898:        "Companion result reader",
14986:        "Companion result reader"
14065: * Stage 16 FC-O45-E-AS Companion Immersion Mode scaffold.
14204: * Stage 16 FC-O45-E-AT Companion Immersion visible panel source wiring.
14481: * Stage 16 FC-O45-E-AZ Companion Immersion primary workspace placement.
14644: * Stage 16 FC-O45-E-BB Companion clean chat workspace.
14823: * Stage 16 FC-O45-E-BD Companion hard-clean visible workspace.
15052: * Stage 16 FC-O45-E-BF Companion minimal chat source.
15191:  window.apcCompanionMinimalChatWorkspace = Object.freeze({
15125:  function hideImmersionChrome() {
15167:    hideImmersionChrome();
15144:  function hideExtraChatCardHeadingAndCopy() {
15169:    hideExtraChatCardHeadingAndCopy();
frontend/wrapper-ui/app.js:15083:    node.classList.add("companion-minimal-chat-hidden");
frontend/wrapper-ui/styles.css:3101:.companion-minimal-chat-hidden,
14760:  function installEnterToSend() {
14791:    installEnterToSend();
14815:    installEnterToSend,
15011:    if (window.apcCompanionCleanChatWorkspace && typeof window.apcCompanionCleanChatWorkspace.installEnterToSend === "function") {
15012:      window.apcCompanionCleanChatWorkspace.installEnterToSend();
15161:    if (window.apcCompanionCleanChatWorkspace && typeof window.apcCompanionCleanChatWorkspace.installEnterToSend === "function") {
15162:      window.apcCompanionCleanChatWorkspace.installEnterToSend();
14733:        node.textContent = "Type a message and press Enter to send.";
14913:      text.includes("Type a message and press Enter to send.") ||
15004:        node.textContent = "Type a message and press Enter to send.";
15062: * - Type a message and press Enter to send.
15156:        node.textContent = "Type a message and press Enter to send.";
3813:              <strong>fallback: qwen2.5:0.5b</strong>
14604:        node.textContent = "fallback: qwen2.5:0.5b";
14878:        "Worker Companion queue worker Model fallback: qwen2.5:0.5b"
3100:/* Stage 16 FC-O45-E-BF Companion minimal chat CSS. */

=== public pre-deploy state, read-only ===
pre_public_root_http=200
pre_public_app_js_http=200
pre_public_unauth_job132_http=401
pre_public_script_tags:
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045ebe"
<script src="/queued_chat_config.js"

=== create package and upload to PVEW ===
local_pkg_sha256=3f50147bfb06715823f05b507be4ff51c294b1016b8806be4d2a50d47166f009
pkg_entry app.js
pkg_entry styles.css
pvew_package_upload=PASS

=== deploy over Tailscale restricted path from PVEW to VM200 ===
--- PVEW package verification ---
pvew
2026-06-25T01:12:51Z
pvew_pkg_sha256=3f50147bfb06715823f05b507be4ff51c294b1016b8806be4d2a50d47166f009
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
received_pkg_sha256=3f50147bfb06715823f05b507be4ff51c294b1016b8806be4d2a50d47166f009
backup_sha256 14cc2cb3d57de4c7babfce9e383df81487ff8d1bb4102bd4f75c95f9857b7106  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T011251Z/app.js
backup_sha256 300b0ac6230d5b64d92ef0d416cd606b52289e313d5b9405dec69fa7d38f4d9e  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T011251Z/styles.css
backup_sha256 d7b83bee2a58050ce7f9bbd8e7f18264a59e52437ecdf40c0ff695a20da34a4f  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T011251Z/index.html
backup_dir=/var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T011251Z
live_sha256 96aa84cd07052fa8e815fdf271e0e507e94711caf69e6fe804ecb526afe8ac75  /var/www/apc-wrapper-local/app.js
live_sha256 3101eb843ee59dad9f21ffe29c3393570a723bb7f0f35270c94fb1d7b80e288a  /var/www/apc-wrapper-local/styles.css
live_sha256 ca9ce781f3f1ffeefba4b231e4055df0b3b1b9b4260535afb11746cc7448925b  /var/www/apc-wrapper-local/index.html
APC_VM200_STATIC_DEPLOY_WRAPPER_UI_PASS cache_bust=20260624fc045ebg
restricted_tailscale_deploy=PASS
FC_O45_E_BG_RESTRICTED_DEPLOY_RECORDED

=== public post-deploy verification ===
post_public_root_http=200
post_public_app_js_http=200
post_public_unauth_job132_http=401
{"detail":"Missing bearer token."}
post_public_script_tags:
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045ebg"
<script src="/queued_chat_config.js"

post_public_verification=PASS
FC_O45_E_BG_DEPLOY_RECORDED new_app_js_bust=20260624fc045ebg
```
