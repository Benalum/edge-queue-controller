# Stage 16 FC-O45-E-BT-R2 — Deploy Companion Result-Reader Refresh Restore Over Restricted Static Path

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `ca6ba79`
- Prior source tag: `controller-stage-16-fc-o45-e-bs-companion-result-reader-refresh-restore-source-no-runtime-2026-06-24`

## Approval

This public static deploy was explicitly approved with:

```
APPROVE_FC_O45_E_BT_DEPLOY_COMPANION_RESULT_READER_REFRESH_RESTORE_OVER_RESTRICTED_STATIC_PATH
```

## Recovery

The first BT deploy package was refused by the VM200 restricted deploy helper because it contained `app.js` but not `styles.css`:

```
REFUSE_PACKAGE_STYLES_CSS_MISSING
```

BT-R2 packages both files:

```
app.js
styles.css
```

## Purpose

BT-R2 deploys the BS frontend result-reader/hard-refresh restore patch to the public VM200 wrapper UI.

The deployed app.js includes:

```
stage16FcO45EBsCompanionResultReaderRefreshRestore
apcCompanionQueuedChatLastJobId
fetchQueuedJob
pollQueuedJob
renderCachedConversation
response_text
```

## Scope

Allowed and performed:

- Deployed `frontend/wrapper-ui/app.js` to VM200 public static `app.js` over the existing restricted static deploy path.
- Included current repo `styles.css` as required by the restricted deploy helper.
- Updated the public root cache-bust script reference to `20260624fc045ebtr2`.
- Verified public root HTTP 200.
- Verified public app.js HTTP 200.
- Verified public styles.css HTTP 200.
- Verified unauthenticated `/api/chat/queued/571` remains protected with HTTP 401.
- Verified BS markers are present in live public app.js.
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

After BT-R2, hard refresh the Companion page. Expected behavior:

1. The deployed app.js is loaded with cache bust `20260624fc045ebtr2`.
2. The result-reader restore layer is present.
3. The UI should restore/render the last queued Companion job if localStorage contains its job id.
4. If not, send one new Companion message; the UI should store that new job id, poll it, and render the assistant response when the backend completes it.

## Output

```
=== Stage 16 FC-O45-E-BT-R2 deploy Companion result-reader refresh restore over restricted static path ===
APPROVAL=APPROVE_FC_O45_E_BT_DEPLOY_COMPANION_RESULT_READER_REFRESH_RESTORE_OVER_RESTRICTED_STATIC_PATH
MUTATION_SCOPE=vm200_public_static_appjs_stylescss_deploy_over_existing_restricted_path_plus_repo_doc_smoke_commit_tag_push
RECOVERY_FROM=BT_REFUSE_PACKAGE_STYLES_CSS_MISSING
ALLOWED: deploy frontend/wrapper-ui/app.js to VM200 public static app.js
ALLOWED: include current repo styles.css required by restricted deploy helper
ALLOWED: update public root cache-bust script reference to 20260624fc045ebtr2 through restricted deploy helper
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
expected_head=ca6ba79
head_now=ca6ba79
origin_main_now=ca6ba79
git_preflight=PASS

=== locate required styles.css ===
styles_source=frontend/wrapper-ui/styles.css

=== source safety checks ===
node_syntax_check=PASS
repo_appjs_sha256=aac02cc376e6daaa8ac21b52e84ff21f46878500b420c55e71418e5d2a621e9e
repo_styles_sha256=03b1e3e152b7ba70364e515096c079b61572d23f12ae626436296ee8f6714081

=== build restricted static deploy package with app.js and styles.css ===
package=/tmp/tmp.7TOmFJBeDE/fc-o45-e-bt-r2-static-package.tgz
package_sha256=6988756c503afb2bfc1ff6225ef0251fa675bbf6689cde2d00a709b2779f4000
cache_bust=20260624fc045ebtr2
package_entry=app.js
package_entry=styles.css

=== deploy over PVEW -> VM200 restricted static path ===
--- PVEW package verification ---
pvew
2026-06-25T02:57:47Z
pvew_package_sha256=6988756c503afb2bfc1ff6225ef0251fa675bbf6689cde2d00a709b2779f4000
pvew_package_entry=app.js
pvew_package_entry=styles.css

--- restricted deploy helper invocation ---
received_pkg_sha256=6988756c503afb2bfc1ff6225ef0251fa675bbf6689cde2d00a709b2779f4000
backup_sha256 0003f92ea766e42f94c79216897e4049f18ce321b410dc48ee918d2197a77351  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T025747Z/app.js
backup_sha256 03b1e3e152b7ba70364e515096c079b61572d23f12ae626436296ee8f6714081  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T025747Z/styles.css
backup_sha256 5f985fd0ca1556403dd86c2a78ff0176c5b4395786a68cd50ae5424b3db03f32  /var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T025747Z/index.html
backup_dir=/var/www/apc-wrapper-local/apc-vm200-static-deploy-backup-20260625T025747Z
live_sha256 aac02cc376e6daaa8ac21b52e84ff21f46878500b420c55e71418e5d2a621e9e  /var/www/apc-wrapper-local/app.js
live_sha256 03b1e3e152b7ba70364e515096c079b61572d23f12ae626436296ee8f6714081  /var/www/apc-wrapper-local/styles.css
live_sha256 582c9f60fc5da276bee8594aea6a958fdb3602cd8fa37bd66ee3540aeb618cff  /var/www/apc-wrapper-local/index.html
APC_VM200_STATIC_DEPLOY_WRAPPER_UI_PASS cache_bust=20260624fc045ebtr2
restricted_static_deploy_invoked=PASS

=== public verification ===
public_root_http=200
public_app_js_http=200
public_styles_css_http=200
public_unauth_job571_http=401
public_unauth_job571_body_preview:
{"detail":"Missing bearer token."}
root_cache_bust_refs:
/app.js?v=20260624fc045ebtr2
/styles.css?v=20260612000409
/styles.css?v=20260614214f

public_static_verification=PASS

BT_R2_STATIC_DEPLOY_RECORDED=PASS
LIVE_CACHE_BUST=20260624fc045ebtr2
NEXT_MANUAL_BROWSER_STEP=hard_refresh_companion_then_verify_job571_reply_or_send_new_message
```
