# Stage 16 FC-O45-E-BC — Deploy Companion Clean Chat Workspace over Tailscale Restricted Path

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `acda1c8`
- Prior source tag: `controller-stage-16-fc-o45-e-bb-companion-clean-chat-workspace-source-2026-06-24`
- Prior restricted deploy tag: `controller-stage-16-fc-o45-e-ba-deploy-companion-immersion-primary-workspace-over-tailscale-restricted-path-2026-06-24`

## Approval

This live static deploy was explicitly approved with:

```
APPROVE_FC_O45_E_BC_DEPLOY_COMPANION_CLEAN_CHAT_WORKSPACE_OVER_TAILSCALE_RESTRICTED_PATH
```

## Deploy path

BC used the intended Tailscale/OpenSSH restricted deploy path:

```
cat package.tgz | ssh apcdeploy@website-edge 'deploy sha256=<sha256> bust=20260624fc045ebc'
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
- Public app.js contains Companion result-reader, Immersion, AZ primary-workspace, and BB clean-chat markers.
- Public app.js contains `Chat with your Companion`.
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
/app.js?v=20260624fc045ebc
```

## Expected user-visible change

The Companion page should now show a cleaner primary chat experience:

```
Chat with your Companion
Conversation
Message
Send message
Clear
```

The following are hidden from the primary flow:

- Companion auth test
- Companion status
- How this works
- Study phrases
- Companion result reader
- Supportive chat workspace text
- Queue-aware UI label

Message behavior:

- Enter sends the message.
- Shift+Enter inserts a newline.

## Deploy output

```
=== Stage 16 FC-O45-E-BC deploy Companion clean chat workspace over Tailscale restricted path ===
APPROVAL=APPROVE_FC_O45_E_BC_DEPLOY_COMPANION_CLEAN_CHAT_WORKSPACE_OVER_TAILSCALE_RESTRICTED_PATH
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
expected_head=acda1c8
head_now=acda1c8
origin_main_now=acda1c8
git_preflight=PASS

=== source marker preflight ===
13991:    title.textContent = "Companion result reader";
14647: * - Hide Companion auth test, Companion status, How this works, Study phrases, and Companion result reader from the primary user flow.
14065: * Stage 16 FC-O45-E-AS Companion Immersion Mode scaffold.
14204: * Stage 16 FC-O45-E-AT Companion Immersion visible panel source wiring.
14481: * Stage 16 FC-O45-E-AZ Companion Immersion primary workspace placement.
14644: * Stage 16 FC-O45-E-BB Companion clean chat workspace.
14470:  window.apcCompanionImmersionRuntime = Object.freeze({
14634:  window.apcCompanionImmersionPrimaryWorkspace = Object.freeze({
14812:  window.apcCompanionCleanChatWorkspace = Object.freeze({
14422:    window.fetch = async function apcCompanionImmersionObservedFetch(input, init = {}) {
14760:  function installEnterToSend() {
14791:    installEnterToSend();
14815:    installEnterToSend,
3773:              <h2>Chat with your Companion</h2>
10704:      '<h2>Chat with your Companion</h2>',
13601:       bodyText.includes("Chat with your Companion"));
13621:          text.includes("Chat with your Companion") ||
13811:       bodyText.includes("Chat with your Companion"));
14649: * - Rename the chat card to "Chat with your Companion".
14723:    renameText("Start a Companion conversation", "Chat with your Companion");
14724:    renameText("Start a companion conversation", "Chat with your Companion");
14733:        node.textContent = "Type a message and press Enter to send.";
14683:    block.classList.add("companion-clean-hidden");
14693:        node.classList.add("companion-clean-hidden");
14729:        node.classList.add("companion-clean-hidden");
3813:              <strong>fallback: qwen2.5:0.5b</strong>
14604:        node.textContent = "fallback: qwen2.5:0.5b";
3001:/* Stage 16 FC-O45-E-AT Companion Immersion visible panel CSS wiring. */
3025:/* Stage 16 FC-O45-E-AZ Companion Immersion primary workspace CSS. */
3057:/* Stage 16 FC-O45-E-BB Companion clean chat workspace CSS. */
3026:#companionImmersionPrimaryWorkspace {
3030:#companionImmersionPrimaryWorkspace #companionImmersionVisiblePanel {
3034:#companionImmersionPrimaryWorkspace .companion-immersion-panel {
3038:#companionImmersionPrimaryWorkspace .companion-immersion-state {
3042:#companionImmersionPrimaryWorkspace .companion-immersion-debug:not([open]) pre {
3071:#companionImmersionPrimaryWorkspace {
3076:#companionImmersionPrimaryWorkspace .companion-immersion-debug:not([open]) {
3058:.companion-clean-hidden {

=== public pre-deploy state, read-only ===
pre_public_root_http=200
pre_public_app_js_http=200
pre_public_unauth_job132_http=401
pre_public_script_tags:
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045eba"
<script src="/queued_chat_config.js"

=== create package and upload to PVEW ===
local_pkg_sha256=04962b4a4715549f84721197af73eb2c5181ff375da6b07e600fefe936a5f272
pkg_entry app.js
pkg_entry styles.css
pvew_package_upload=PASS

=== deploy over Tailscale restricted path from PVEW to VM200 ===
--- PVEW package verification ---
pvew
2026-06-25T00:59:32Z
pvew_pkg_sha256=04962b4a4715549f84721197af73eb2c5181ff375da6b07e600fefe936a5f272
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
received_pkg_sha256=04962b4a4715549f84721197af73eb2c5181ff375da6b07e600fefe936a5f272
backup_sha256 3c750e19779ae9bfdcdc960d4c7b458fcb917f132e4acda4244e1f8d6e745b2b  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T005933Z/app.js
backup_sha256 d2e5ac3403a36f0aa8636f7de22babae605491fb65e98aaf11d42724f6f12a97  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T005933Z/styles.css
backup_sha256 0e95fef31b6950982c5806fd56016f505748a2022ebbf00cea71065d50b01cd8  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T005933Z/index.html
backup_dir=/var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T005933Z
live_sha256 7776af5fb0b3c88d62558410595cc654cf7bc21c785b03109892658f5abf282f  /var/www/apc-wrapper-local/app.js
live_sha256 21f7b37fe14e6b6bb48d7121ac570eb278e7aa9c719ca9e13518e4745ec7ba55  /var/www/apc-wrapper-local/styles.css
live_sha256 0036c5edaf1197c0541c73ea73d0a7269c727e598f0d1dab97b663e64d209940  /var/www/apc-wrapper-local/index.html
APC_VM200_STATIC_DEPLOY_WRAPPER_UI_PASS cache_bust=20260624fc045ebc
restricted_tailscale_deploy=PASS
FC_O45_E_BC_RESTRICTED_DEPLOY_RECORDED

=== public post-deploy verification ===
post_public_root_http=200
post_public_app_js_http=200
post_public_unauth_job132_http=401
{"detail":"Missing bearer token."}
post_public_script_tags:
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045ebc"
<script src="/queued_chat_config.js"

post_public_verification=PASS
FC_O45_E_BC_DEPLOY_RECORDED new_app_js_bust=20260624fc045ebc
```
