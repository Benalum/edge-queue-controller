# Stage 16 FC-O45-E-BY — Deploy Companion Final Render Wins Over Restricted Static Path

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `ae3f854`
- Prior source tag: `controller-stage-16-fc-o45-e-bx-companion-final-render-wins-source-no-runtime-2026-06-24`

## Approval

This public static deploy was explicitly approved with:

```
APPROVE_FC_O45_E_BY_DEPLOY_COMPANION_FINAL_RENDER_WINS_OVER_RESTRICTED_STATIC_PATH
```

## Purpose

BY deploys the BX final-render-wins patch to the public VM200 wrapper UI.

The deployed app.js includes:

```
stage16FcO45EBsCompanionResultReaderRefreshRestore
stage16FcO45EBvCompanionStableResultPoller
stage16FcO45EBxCompanionFinalRenderWins
data-stage16-fc-o45-e-bx-render-signature
hasRenderedConversationRows
queued-chat-message
response_text
```

## Scope

Allowed and performed:

- Deployed `frontend/wrapper-ui/app.js` to VM200 public static `app.js` over the existing restricted static deploy path.
- Included current repo `styles.css` as required by the restricted deploy helper.
- Updated the public root cache-bust script reference to `20260624fc045eby`.
- Verified public root HTTP 200.
- Verified public app.js HTTP 200.
- Verified public styles.css HTTP 200.
- Verified unauthenticated `/api/chat/queued/572` remains protected with HTTP 401.
- Verified BS/BV/BX markers are present in live public app.js.
- Recorded repo docs/smoke/commit/tag/push.

Explicitly not allowed and not performed:

- NO backend deploy.
- NO CT203 runtime patch.
- NO DB write.
- NO job mutation.
- NO result insert.
- NO model/helper/Ollama call.
- NO scheduler activation.
- NO timer activation.
- NO persistent worker activation.
- NO service restart/reload/start/stop/enable/disable.
- NO CT/VM restart.
- NO nginx/cloudflared/sshd config mutation.
- NO storage mutation outside approved VM200 static deploy backup/write.
- NO file deletion outside restricted deploy helper rotation semantics.

## Browser validation

After BY, hard refresh the Companion page. Expected behavior:

1. The deployed app.js is loaded with cache bust `20260624fc045eby`.
2. Job 572 remains visible with its completed assistant response.
3. The page does not show the conversation and then later revert to the blank/no-conversation page.
4. Clear still intentionally removes the stored conversation.

## Output

```
=== Stage 16 FC-O45-E-BY deploy Companion final-render-wins over restricted static path ===
APPROVAL=APPROVE_FC_O45_E_BY_DEPLOY_COMPANION_FINAL_RENDER_WINS_OVER_RESTRICTED_STATIC_PATH
MUTATION_SCOPE=vm200_public_static_appjs_stylescss_deploy_over_existing_restricted_path_plus_repo_doc_smoke_commit_tag_push
ALLOWED: deploy frontend/wrapper-ui/app.js to VM200 public static app.js
ALLOWED: include current repo styles.css required by restricted deploy helper
ALLOWED: update public root cache-bust script reference to 20260624fc045eby through restricted deploy helper
ALLOWED: VM200 static backup created by restricted deploy helper
ALLOWED: public read-only HTTP verification
ALLOWED: repo docs/smoke commit/tag/push
NO backend deploy
NO CT203 runtime patch
NO DB write
NO job mutation
NO result insert
NO model/helper/Ollama call
NO scheduler activation
NO timer activation
NO persistent worker activation
NO service restart/reload/start/stop/enable/disable
NO CT/VM restart
NO nginx/cloudflared/sshd config mutation
NO storage mutation outside approved VM200 static deploy backup/write
NO file deletion outside restricted deploy helper rotation semantics

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=ae3f854
head_now=ae3f854
origin_main_now=ae3f854
git_preflight=PASS

=== source safety checks ===
node_syntax_check=PASS
repo_appjs_sha256=e5d08a1eb297c934e60e2654c66abb348cd4bd093f3c7ee1855118f82d89ecb0
repo_styles_sha256=03b1e3e152b7ba70364e515096c079b61572d23f12ae626436296ee8f6714081

=== build restricted static deploy package with app.js and styles.css ===
package=/tmp/tmp.FRcuKfcxDH/fc-o45-e-by-static-package.tgz
package_sha256=b2d319aafd89c553afaedd4f83b026c7e07c9643eed4e9dfd4bf546f83571e88
cache_bust=20260624fc045eby
package_entry=app.js
package_entry=styles.css

=== deploy over PVEW -> VM200 restricted static path ===
--- PVEW package verification ---
pvew
2026-06-25T03:27:29Z
pvew_package_sha256=b2d319aafd89c553afaedd4f83b026c7e07c9643eed4e9dfd4bf546f83571e88
pvew_package_entry=app.js
pvew_package_entry=styles.css

--- restricted deploy helper invocation ---
received_pkg_sha256=b2d319aafd89c553afaedd4f83b026c7e07c9643eed4e9dfd4bf546f83571e88
backup_sha256 42d323a42c1f3213129b5454edfc986062c1838e86ae37c48743cf50199687b8  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T032729Z/app.js
backup_sha256 03b1e3e152b7ba70364e515096c079b61572d23f12ae626436296ee8f6714081  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T032729Z/styles.css
backup_sha256 21ff9e3ceefc41a52714e7996420edb054c946fdfc797d36b72c3ff735dd77f5  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T032729Z/index.html
backup_dir=/var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T032729Z
live_sha256 e5d08a1eb297c934e60e2654c66abb348cd4bd093f3c7ee1855118f82d89ecb0  /var/www/apc-wrapper-local/app.js
live_sha256 03b1e3e152b7ba70364e515096c079b61572d23f12ae626436296ee8f6714081  /var/www/apc-wrapper-local/styles.css
live_sha256 1a2582b7b4badb2b4c175d2bbb2ace1ad8cdc3c01a2ca3471faea323f4430f36  /var/www/apc-wrapper-local/index.html
APC_VM200_STATIC_DEPLOY_WRAPPER_UI_PASS cache_bust=20260624fc045eby
restricted_static_deploy_invoked=PASS

=== public verification ===
public_root_http=200
public_app_js_http=200
public_styles_css_http=200
public_unauth_job572_http=401
public_unauth_job572_body_preview:
{"detail":"Missing bearer token."}
root_cache_bust_refs:
/app.js?v=20260624fc045eby
/styles.css?v=20260612000409
/styles.css?v=20260614214f

public_static_verification=PASS

BY_STATIC_DEPLOY_RECORDED=PASS
LIVE_CACHE_BUST=20260624fc045eby
NEXT_MANUAL_BROWSER_STEP=hard_refresh_companion_verify_completed_job572_stays_visible_without_disappearing
```
