# Stage 16 FC-O45-E-BW — Deploy Companion Stable Result Poller Over Restricted Static Path

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `74cfb00`
- Prior source tag: `controller-stage-16-fc-o45-e-bv-companion-stable-result-poller-source-no-runtime-2026-06-24`

## Approval

This public static deploy was explicitly approved with:

```
APPROVE_FC_O45_E_BW_DEPLOY_COMPANION_STABLE_RESULT_POLLER_OVER_RESTRICTED_STATIC_PATH
```

## Purpose

BW deploys the BV stable Companion result poller to the public VM200 wrapper UI.

The deployed app.js includes:

```
stage16FcO45EBsCompanionResultReaderRefreshRestore
stage16FcO45EBvCompanionStableResultPoller
activePollJobId
lastRenderSignature
scheduleRestoreLastQueuedJob
response_text
```

## Scope

Allowed and performed:

- Deployed `frontend/wrapper-ui/app.js` to VM200 public static `app.js` over the existing restricted static deploy path.
- Included current repo `styles.css` as required by the restricted deploy helper.
- Updated the public root cache-bust script reference to `20260624fc045ebw`.
- Verified public root HTTP 200.
- Verified public app.js HTTP 200.
- Verified public styles.css HTTP 200.
- Verified unauthenticated `/api/chat/queued/572` remains protected with HTTP 401.
- Verified BS/BV markers are present in live public app.js.
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

After BW, hard refresh the Companion page. Expected behavior:

1. The deployed app.js is loaded with cache bust `20260624fc045ebw`.
2. Job 572 remains visible with its completed assistant response.
3. The page no longer constantly reloads/re-renders.
4. A new queued job should display queued/running, poll until terminal status, render the answer, then stop.

## Output

```
=== Stage 16 FC-O45-E-BW deploy Companion stable result poller over restricted static path ===
APPROVAL=APPROVE_FC_O45_E_BW_DEPLOY_COMPANION_STABLE_RESULT_POLLER_OVER_RESTRICTED_STATIC_PATH
MUTATION_SCOPE=vm200_public_static_appjs_stylescss_deploy_over_existing_restricted_path_plus_repo_doc_smoke_commit_tag_push
ALLOWED: deploy frontend/wrapper-ui/app.js to VM200 public static app.js
ALLOWED: include current repo styles.css required by restricted deploy helper
ALLOWED: update public root cache-bust script reference to 20260624fc045ebw through restricted deploy helper
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
expected_head=74cfb00
head_now=74cfb00
origin_main_now=74cfb00
git_preflight=PASS

=== source safety checks ===
node_syntax_check=PASS
repo_appjs_sha256=42d323a42c1f3213129b5454edfc986062c1838e86ae37c48743cf50199687b8
repo_styles_sha256=03b1e3e152b7ba70364e515096c079b61572d23f12ae626436296ee8f6714081

=== build restricted static deploy package with app.js and styles.css ===
package=/tmp/tmp.0rTi6ZqSso/fc-o45-e-bw-static-package.tgz
package_sha256=83dbedb94323c4c24bc90f58ef0eafbafc0daa3e4d90265b2cfdd27b841e3f53
cache_bust=20260624fc045ebw
package_entry=app.js
package_entry=styles.css

=== deploy over PVEW -> VM200 restricted static path ===
--- PVEW package verification ---
pvew
2026-06-25T03:16:51Z
pvew_package_sha256=83dbedb94323c4c24bc90f58ef0eafbafc0daa3e4d90265b2cfdd27b841e3f53
pvew_package_entry=app.js
pvew_package_entry=styles.css

--- restricted deploy helper invocation ---
received_pkg_sha256=83dbedb94323c4c24bc90f58ef0eafbafc0daa3e4d90265b2cfdd27b841e3f53
backup_sha256 aac02cc376e6daaa8ac21b52e84ff21f46878500b420c55e71418e5d2a621e9e  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T031651Z/app.js
backup_sha256 03b1e3e152b7ba70364e515096c079b61572d23f12ae626436296ee8f6714081  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T031651Z/styles.css
backup_sha256 582c9f60fc5da276bee8594aea6a958fdb3602cd8fa37bd66ee3540aeb618cff  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T031651Z/index.html
backup_dir=/var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T031651Z
live_sha256 42d323a42c1f3213129b5454edfc986062c1838e86ae37c48743cf50199687b8  /var/www/apc-wrapper-local/app.js
live_sha256 03b1e3e152b7ba70364e515096c079b61572d23f12ae626436296ee8f6714081  /var/www/apc-wrapper-local/styles.css
live_sha256 21ff9e3ceefc41a52714e7996420edb054c946fdfc797d36b72c3ff735dd77f5  /var/www/apc-wrapper-local/index.html
APC_VM200_STATIC_DEPLOY_WRAPPER_UI_PASS cache_bust=20260624fc045ebw
restricted_static_deploy_invoked=PASS

=== public verification ===
public_root_http=200
public_app_js_http=200
public_styles_css_http=200
public_unauth_job572_http=401
public_unauth_job572_body_preview:
{"detail":"Missing bearer token."}
root_cache_bust_refs:
/app.js?v=20260624fc045ebw
/styles.css?v=20260612000409
/styles.css?v=20260614214f

public_static_verification=PASS

BW_STATIC_DEPLOY_RECORDED=PASS
LIVE_CACHE_BUST=20260624fc045ebw
NEXT_MANUAL_BROWSER_STEP=hard_refresh_companion_verify_no_constant_reload_and_completed_job572_stays_visible
```
