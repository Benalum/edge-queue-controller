# Stage 16 FC-O45-E-BA — Deploy Companion Immersion Primary Workspace over Tailscale Restricted Path

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `3064635`
- Prior source tag: `controller-stage-16-fc-o45-e-az-companion-immersion-primary-workspace-source-2026-06-24`
- Prior restricted deploy tag: `controller-stage-16-fc-o45-e-ay-deploy-companion-immersion-ui-over-tailscale-restricted-path-2026-06-24`

## Approval

This live static deploy was explicitly approved with:

```
APPROVE_FC_O45_E_BA_DEPLOY_COMPANION_IMMERSION_PRIMARY_WORKSPACE_OVER_TAILSCALE_RESTRICTED_PATH
```

## Deploy path

BA used the intended Tailscale/OpenSSH restricted deploy path:

```
cat package.tgz | ssh apcdeploy@website-edge 'deploy sha256=<sha256> bust=20260624fc045eba'
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
- Public app.js contains Companion result-reader, Immersion, and AZ primary-workspace markers.
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
/app.js?v=20260624fc045eba
```

## Expected user-visible change

The Companion Immersion panel should now behave as the primary Companion workspace:

- visible Immersion state panel near the Conversation area;
- debug details collapsed by default;
- legacy debug-like sections visually de-emphasized;
- model label aligned to `fallback: qwen2.5:0.5b`;
- queued chat and result-reader behavior preserved.

## Deploy output

```
=== Stage 16 FC-O45-E-BA deploy Companion Immersion primary workspace over Tailscale restricted path ===
APPROVAL=APPROVE_FC_O45_E_BA_DEPLOY_COMPANION_IMMERSION_PRIMARY_WORKSPACE_OVER_TAILSCALE_RESTRICTED_PATH
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
expected_head=3064635
head_now=3064635
origin_main_now=3064635
git_preflight=PASS

=== source marker preflight ===
13991:    title.textContent = "Companion result reader";
14065: * Stage 16 FC-O45-E-AS Companion Immersion Mode scaffold.
14204: * Stage 16 FC-O45-E-AT Companion Immersion visible panel source wiring.
14481: * Stage 16 FC-O45-E-AZ Companion Immersion primary workspace placement.
14470:  window.apcCompanionImmersionRuntime = Object.freeze({
14634:  window.apcCompanionImmersionPrimaryWorkspace = Object.freeze({
14422:    window.fetch = async function apcCompanionImmersionObservedFetch(input, init = {}) {
3813:              <strong>fallback: qwen2.5:0.5b</strong>
14604:        node.textContent = "fallback: qwen2.5:0.5b";
3001:/* Stage 16 FC-O45-E-AT Companion Immersion visible panel CSS wiring. */
3025:/* Stage 16 FC-O45-E-AZ Companion Immersion primary workspace CSS. */
3026:#companionImmersionPrimaryWorkspace {
3030:#companionImmersionPrimaryWorkspace #companionImmersionVisiblePanel {
3034:#companionImmersionPrimaryWorkspace .companion-immersion-panel {
3038:#companionImmersionPrimaryWorkspace .companion-immersion-state {
3042:#companionImmersionPrimaryWorkspace .companion-immersion-debug:not([open]) pre {

=== public pre-deploy state, read-only ===
pre_public_root_http=200
pre_public_app_js_http=200
pre_public_unauth_job132_http=401
pre_public_script_tags:
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045eay"
<script src="/queued_chat_config.js"

=== create package and upload to PVEW ===
local_pkg_sha256=535a20b3d47aa7f69ca244324a6a3e3a40af6d36cae19b1ac0ea326f7c16fc3d
pkg_entry app.js
pkg_entry styles.css
pvew_package_upload=PASS

=== deploy over Tailscale restricted path from PVEW to VM200 ===
--- PVEW package verification ---
pvew
2026-06-25T00:51:22Z
pvew_pkg_sha256=535a20b3d47aa7f69ca244324a6a3e3a40af6d36cae19b1ac0ea326f7c16fc3d
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
received_pkg_sha256=535a20b3d47aa7f69ca244324a6a3e3a40af6d36cae19b1ac0ea326f7c16fc3d
backup_sha256 44ce4c74c19f392e6a5058702c730b59dea5ef29717442c2c31dffe8cc2854ba  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T005123Z/app.js
backup_sha256 ce08d885ecc8e943746a6fac738f278f1e2b0c6dbdf493ca92cee3aa55bfaaa3  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T005123Z/styles.css
backup_sha256 7ebf1b11609f50a33ebad88c84f4c1ee1e83882d3b93e3573950121b867eafa8  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T005123Z/index.html
backup_dir=/var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T005123Z
live_sha256 3c750e19779ae9bfdcdc960d4c7b458fcb917f132e4acda4244e1f8d6e745b2b  /var/www/apc-wrapper-local/app.js
live_sha256 d2e5ac3403a36f0aa8636f7de22babae605491fb65e98aaf11d42724f6f12a97  /var/www/apc-wrapper-local/styles.css
live_sha256 0e95fef31b6950982c5806fd56016f505748a2022ebbf00cea71065d50b01cd8  /var/www/apc-wrapper-local/index.html
APC_VM200_STATIC_DEPLOY_WRAPPER_UI_PASS cache_bust=20260624fc045eba
restricted_tailscale_deploy=PASS
FC_O45_E_BA_RESTRICTED_DEPLOY_RECORDED

=== public post-deploy verification ===
post_public_root_http=200
post_public_app_js_http=200
post_public_unauth_job132_http=401
{"detail":"Missing bearer token."}
post_public_script_tags:
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045eba"
<script src="/queued_chat_config.js"

post_public_verification=PASS
FC_O45_E_BA_DEPLOY_RECORDED new_app_js_bust=20260624fc045eba
```
