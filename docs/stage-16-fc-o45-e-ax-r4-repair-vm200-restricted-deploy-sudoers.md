# Stage 16 FC-O45-E-AX-R4 — Repair VM200 Restricted Deploy Sudoers

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `9fd64f4`
- Prior tag: `controller-stage-16-fc-o45-e-aw-vm200-tailscale-restricted-deploy-access-contract-2026-06-24`

## Approval

This restricted access repair was covered by the explicit AX approval:

```
APPROVE_FC_O45_E_AX_INSTALL_VM200_TAILSCALE_RESTRICTED_STATIC_DEPLOY_ACCESS
```

## Why R4 was needed

AX-R3 partially installed the restricted deploy path but failed because the sudoers file used a Red Hat-style setting not accepted by this VM200 sudo version:

```
Defaults:apcdeploy !requiretty
```

R4 replaced the sudoers file with a Debian/Ubuntu-compatible restricted rule:

```
apcdeploy ALL=(root) NOPASSWD: /usr/local/sbin/apc-vm200-static-deploy-wrapper-ui-root *
```

## Scope

Allowed and performed:

- Repaired only `/etc/sudoers.d/apc-vm200-static-deploy-wrapper-ui`.
- Verified `apcdeploy` exists.
- Verified forced wrapper exists:
  - `/usr/local/bin/apc-vm200-static-deploy-wrapper-ui`
- Verified restricted root helper exists:
  - `/usr/local/sbin/apc-vm200-static-deploy-wrapper-ui-root`
- Verified sudoers syntax with `visudo -cf`.
- Verified `apcdeploy` can reach the helper and arbitrary/probe command is refused.
- Verified PVEW can reach VM200 over Tailscale as `apcdeploy@website-edge`.
- Verified public root/app remained on the old cache-bust after access repair.
- Verified unauthenticated job132 result endpoint remained protected.

Explicitly not allowed and not performed:

- NO DB write.
- NO job mutation.
- NO result insert.
- NO model/helper/Ollama call.
- NO model generation.
- NO scheduler activation.
- NO timer activation.
- NO persistent worker activation.
- NO backend/frontend deploy.
- NO public `/var/www` static deploy.
- NO `app.js`/`styles.css`/`index.html` replacement.
- NO nginx/cloudflared config mutation.
- NO sshd config mutation.
- NO service restart/reload/start/stop/enable/disable.
- NO CT/VM restart.
- NO storage mutation.
- NO file deletion.

## Installed access contract

Future deploys must use:

```
cat package.tgz | ssh apcdeploy@website-edge 'deploy sha256=<sha256> bust=<cache-bust-token>'
```

## Next phase

Use the installed restricted path for:

```
FC-O45-E-AY — deploy Companion Immersion UI over Tailscale restricted path
```

AY should not use QGA for package transfer.

## Repair output

```
=== Stage 16 FC-O45-E-AX-R4 repair VM200 restricted deploy sudoers ===
APPROVAL=APPROVE_FC_O45_E_AX_INSTALL_VM200_TAILSCALE_RESTRICTED_STATIC_DEPLOY_ACCESS
MUTATION_SCOPE=vm200_restricted_deploy_sudoers_repair_plus_access_verify_plus_repo_doc_smoke_commit_tag_push
FIX=remove_invalid_requiretty_setting_and_verify_forced_command
ALLOWED: repair /etc/sudoers.d/apc-vm200-static-deploy-wrapper-ui only
ALLOWED: verify apcdeploy user/key/wrapper/helper presence
ALLOWED: verify PVEW to VM200 over Tailscale reaches forced command
NO DB write
NO job mutation
NO result insert
NO model/helper/Ollama call
NO model generation
NO scheduler activation
NO timer activation
NO persistent worker activation
NO backend/frontend deploy
NO public /var/www static deploy
NO app.js/styles.css/index.html replacement
NO nginx/cloudflared config mutation
NO sshd config mutation
NO service restart/reload/start/stop/enable/disable
NO CT/VM restart
NO storage mutation
NO file deletion

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=9fd64f4
head_now=9fd64f4
origin_main_now=9fd64f4
git_preflight=PASS

=== public pre-repair state, read-only ===
public_root_http=200
public_app_js_http=200
public_unauth_job132_http=401
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045eader2"
<script src="/queued_chat_config.js"

=== repair sudoers and verify installed restricted access via QGA ===
--- pvew/qga posture ---
pvew
2026-06-25T00:38:37Z
status: running
{
   "exitcode" : 0,
   "exited" : 1,
   "out-data" : "website-edge\n",
   "out-truncated" : 0
}
qga_readiness=PASS

--- repair sudoers and verify VM200 install inventory ---
{
   "exitcode" : 0,
   "exited" : 1,
   "out-data" : "vm200_hostname=website-edge\n2026-06-25T00:38:40Z\n--- replace sudoers file with Debian/Ubuntu compatible rule ---\n/etc/sudoers.d/apc-vm200-static-deploy-wrapper-ui: parsed OK\n--- verify sudo path as apcdeploy refuses probe through helper ---\nsudo_probe_rc=64\nREFUSE_STATIC_DEPLOY_BAD_ORIGINAL_COMMAND\nexpected: deploy sha256=<64 lowercase hex> bust=<cache-bust-token>\n--- installed inventory ---\nuid=999(apcdeploy) gid=983(apcdeploy) groups=983(apcdeploy)\n-r--r----- 1 root      root        89 Jun 25 00:38 /etc/sudoers.d/apc-vm200-static-deploy-wrapper-ui\n-rw------- 1 apcdeploy apcdeploy  225 Jun 25 00:35 /home/apcdeploy/.ssh/authorized_keys\n-rwxr-xr-x 1 root      root       156 Jun 25 00:35 /usr/local/bin/apc-vm200-static-deploy-wrapper-ui\n-rwxr-x--- 1 root      root      3720 Jun 25 00:35 /usr/local/sbin/apc-vm200-static-deploy-wrapper-ui-root\n\n/home/apcdeploy/.ssh:\ntotal 12\ndrwx------ 2 apcdeploy apcdeploy 4096 Jun 25 00:35 .\ndrwxr-x--- 3 apcdeploy apcdeploy 4096 Jun 25 00:35 ..\n-rw------- 1 apcdeploy apcdeploy  225 Jun 25 00:35 authorized_keys\n256 SHA256:AInRZAW5hNJB6SXkwPOpJcCNItwhuGR6FVmk4NP2WMo pve@host (ED25519)\n/app.js?v=20260624fc045eader2\n    title.textContent = \"Companion result reader\";\nAX_R4_VM200_SUDOERS_REPAIR_PASS\n",
   "out-truncated" : 0
}

--- verify PVEW to VM200 forced command over Tailscale ---
forced_command_probe_rc=64
REFUSE_STATIC_DEPLOY_BAD_ORIGINAL_COMMAND
expected: deploy sha256=<64 lowercase hex> bust=<cache-bust-token>
forced_command_probe=PASS
FC_O45_E_AX_R4_REPAIR_RECORDED

=== public post-repair state, read-only ===
post_public_root_http=200
post_public_app_js_http=200
post_public_unauth_job132_http=401
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045eader2"
<script src="/queued_chat_config.js"
public_post_repair_unchanged=PASS
AX_R4_RESTRICTED_ACCESS_READY_FOR_AY
```
