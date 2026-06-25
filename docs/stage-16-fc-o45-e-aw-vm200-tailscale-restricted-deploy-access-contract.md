# Stage 16 FC-O45-E-AW — VM200 Tailscale Restricted Deploy Access Contract

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `d223c86`
- Prior deploy-readiness tag: `controller-stage-16-fc-o45-e-au-companion-immersion-deploy-readiness-2026-06-24`
- Current source-only/deploy target remains Companion Immersion UI.

## Why this phase exists

AV-R4 through AV-R8 showed that QEMU guest-agent file transfer is the wrong long-term path for VM200 static deploys:

- R4 timed out.
- R5 found the staged VM200 package was corrupt/truncated.
- R6 found this Proxmox `qm guest exec` does not support `--pass-stdin`.
- R7 found VM200 could not fetch the package from a temporary PVEW LAN HTTP server.
- R8 showed QGA chunk transfer can corrupt the payload before SHA verification.

The intended platform architecture is Tailscale-first inter-system communication, especially so future workers can be added with the same restricted access pattern.

## Scope

This phase is read-only Tailscale/SSH discovery plus repo docs/smoke/commit/tag/push.

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
- NO public `/var/www` mutation.
- NO package copy to VM200.
- NO key install.
- NO `authorized_keys` mutation.
- NO sshd config mutation.
- NO service restart/reload/start/stop/enable/disable.
- NO CT/VM restart.
- NO nginx/cloudflared config mutation.
- NO storage mutation.
- NO file deletion.

## Access design contract

The next deploy path should be:

```
controller / orchestrator
  -> Tailscale identity
  -> OpenSSH over Tailscale
  -> restricted forced command on VM200
  -> exact static deploy operation only
```

The restricted command should be named:

```
apc-vm200-static-deploy-wrapper-ui
```

It should allow only:

1. receive a signed or checksum-pinned tar package containing `app.js` and `styles.css`;
2. verify package SHA-256 before mutation;
3. verify package contains required Companion result-reader and Immersion markers;
4. backup current `/var/www/apc-wrapper-local/app.js`, `styles.css`, and `index.html`;
5. replace only `app.js` and `styles.css`;
6. update only the `/app.js?v=...` cache-bust in `index.html`;
7. verify live markers;
8. print backup path and final hashes.

It should not allow:

- general shell;
- arbitrary file write;
- service restart/reload;
- nginx/cloudflared config mutation;
- DB/job/model/worker mutation;
- VM/CT restart;
- deletion.

## Proposed next phases

### FC-O45-E-AX

Approval-gated install of VM200 restricted static-deploy access over Tailscale.

Suggested approval phrase:

```
APPROVE_FC_O45_E_AX_INSTALL_VM200_TAILSCALE_RESTRICTED_STATIC_DEPLOY_ACCESS
```

AX should install only the restricted access path and then verify that the command refuses anything except the exact static deploy operation.

### FC-O45-E-AY

Use the restricted Tailscale path to deploy the Companion Immersion UI.

AY should not use QGA for package transfer.

## Discovery output

```
=== Stage 16 FC-O45-E-AW VM200 Tailscale restricted deploy access contract ===
MUTATION_SCOPE=read_only_tailscale_access_discovery_plus_repo_doc_smoke_commit_tag_push
NO DB write
NO job mutation
NO result insert
NO model/helper/Ollama call
NO model generation
NO scheduler activation
NO timer activation
NO persistent worker activation
NO backend/frontend deploy
NO public /var/www mutation
NO package copy to VM200
NO key install
NO authorized_keys mutation
NO sshd config mutation
NO service restart/reload/start/stop/enable/disable
NO CT/VM restart
NO nginx/cloudflared config mutation
NO storage mutation
NO file deletion

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=d223c86
head_now=d223c86
origin_main_now=d223c86
git_preflight=PASS

=== public live state, read-only ===
public_root_http=200
public_app_js_http=200
public_unauth_job132_http=401
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045eader2"
<script src="/queued_chat_config.js"
    title.textContent = "Companion result reader";

=== PVEW and VM200 Tailscale/SSH discovery, read-only ===
--- pvew posture ---
pvew
2026-06-25T00:27:50Z
status: running

--- pvew tailscale self and name resolution ---
1.98.4
  tailscale commit: 9e69045b291a7cb1edc714442d68e83b95d05e6b
  long version: 1.98.4-t9e69045b2-ged3a62f14
  other commit: ed3a62f143dd73c8aae368d9c639ea49de878f9b
  go version: go1.26.3 (tailscale/go e877d97384)
<redacted-tailscale-ip>
<redacted-tailscale-ip>   pvew                alexhartel179@  linux  -                                                        
<redacted-tailscale-ip>  alex-latitude-3540  alexhartel179@  linux  active; direct 192.168.0.146:41641, tx 145248 rx 756272  
<redacted-tailscale-ip>   iphone-14           alexhartel179@  iOS    offline, last seen 1h ago                                
<redacted-tailscale-ip>   llms                alexhartel179@  linux  -                                                        
<redacted-tailscale-ip>   pveso               alexhartel179@  linux  -                                                        
<redacted-tailscale-ip>  website-edge        alexhartel179@  linux  -                                                        
getent website-edge:
<redacted-tailscale-ip>  website-edge.tail40a52f.ts.net

--- pvew SSH identity fingerprints only ---
256 SHA256:AInRZAW5hNJB6SXkwPOpJcCNItwhuGR6FVmk4NP2WMo pve@host (ED25519)
4096 SHA256:lENyvwB0qKcScq4RJQ8MXhjGS+Zj1OCfidQOf65Ltdo root@pve (RSA)
pvew_pubkey_file=/root/.ssh/id_ed25519.pub
pvew_pubkey_file=/root/.ssh/id_rsa.pub

--- pvew to website-edge OpenSSH over Tailscale probe, read-only ---
debug3: Started with: ssh -n -vvv -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new root@website-edge hostname
debug2: resolving "website-edge" port 22
debug3: resolve_host: lookup website-edge:22
debug1: Connecting to website-edge [<redacted-tailscale-ip>] port 22.
debug1: Authenticating to website-edge:22 as 'root'
debug3: load_hostkeys_file: loaded 1 keys from website-edge
debug3: load_hostkeys_file: loaded 1 keys from website-edge
debug1: Host 'website-edge' is known and matches the ED25519 host key.
debug1: Offering public key: /root/.ssh/id_rsa RSA SHA256:lENyvwB0qKcScq4RJQ8MXhjGS+Zj1OCfidQOf65Ltdo
debug1: Offering public key: /root/.ssh/id_ed25519 ED25519 SHA256:AInRZAW5hNJB6SXkwPOpJcCNItwhuGR6FVmk4NP2WMo
root@website-edge: Permission denied (publickey,password,keyboard-interactive).

--- VM200 guest agent read-only host/network posture ---
{
   "exitcode" : 0,
   "exited" : 1,
   "out-data" : "website-edge\n",
   "out-truncated" : 0
}
{
   "exitcode" : 0,
   "exited" : 1,
   "out-data" : "lo               UNKNOWN        127.0.0.1/8 ::1/128 \nens18            UP             192.168.0.144/24 metric 100 2601:8c0:800:7627:be24:11ff:fe46:3217/64 fe80::be24:11ff:fe46:3217/64 \ntailscale0       UNKNOWN        <redacted-tailscale-ip>/32 fd7a:115c:a1e0::e43a:8546/128 fe80::327f:a1c6:2ac2:ee89/64 \n",
   "out-truncated" : 0
}

--- VM200 read-only Tailscale and SSH posture via QGA ---
{
   "exitcode" : 0,
   "exited" : 1,
   "out-data" : "hostname=website-edge\n\ntailscale:\n1.98.4\n  tailscale commit: 9e69045b291a7cb1edc714442d68e83b95d05e6b\n  long version: 1.98.4-t9e69045b2-ged3a62f14\n  other commit: ed3a62f143dd73c8aae368d9c639ea49de878f9b\n  go version: go1.26.3 (tailscale/go e877d97384)\n<redacted-tailscale-ip>\n<redacted-tailscale-ip>  website-edge        alexhartel179@  linux  -                                                   \n<redacted-tailscale-ip>  alex-latitude-3540  alexhartel179@  linux  -                                                   \n<redacted-tailscale-ip>   iphone-14           alexhartel179@  iOS    offline, last seen 1h ago                           \n<redacted-tailscale-ip>   llms                alexhartel179@  linux  -                                                   \n<redacted-tailscale-ip>   pveso               alexhartel179@  linux  -                                                   \n<redacted-tailscale-ip>   pvew                alexhartel179@  linux  active; direct 192.168.0.11:41641, tx 4732 rx 5364  \n\nssh service/listener:\nssh_enabled=enabled\nssh_active=active\nsshd_enabled=alias\nsshd_active=active\nLISTEN 0      4096                       0.0.0.0:22         0.0.0.0:*    users:((\"sshd\",pid=1309,fd=3),(\"systemd\",pid=1,fd=291))                           \nLISTEN 0      4096                          [::]:22            [::]:*    users:((\"sshd\",pid=1309,fd=4),(\"systemd\",pid=1,fd=292))                           \n\nsshd config effective snippets:\npermitrootlogin no\npubkeyauthentication yes\npasswordauthentication yes\nx11forwarding yes\nallowtcpforwarding yes\nforcecommand none\nauthorizedkeysfile .ssh/authorized_keys .ssh/authorized_keys2\npermitopen any\n\nauthorized_keys fingerprints only:\nauthorized_keys_file=/root/.ssh/authorized_keys\nauthorized_keys_file=/home/jkg76nid/.ssh/authorized_keys\n256 SHA256:P8EtJEt5R+oOo0SCsq88Aw+2SqOFzMOH9HX63Wk0dZc alex@alex-Latitude-3540 (ED25519)\n\nexisting apc/restricted command inventory:\n\nlive static state:\nfc0225078cb046bb4f058a3705afbb1866508b643ac15587fc57849e274e82ba  /var/www/apc-wrapper-local/index.html\n4c4ca9db2fc88abeaf6442ee7ada3efbb88c9b2a2436f175c7442720e5daf8e7  /var/www/apc-wrapper-local/app.js\nc1e629398a7bb15ae9735fdb287cc0636cd36504031a93605783a45b12b55d19  /var/www/apc-wrapper-local/styles.css\n/app.js?v=20260624fc045eader2\n    title.textContent = \"Companion result reader\";\n",
   "out-truncated" : 0
}

--- recommended conclusion from discovery ---
recommended_method=tailscale_openssh_restricted_forced_command
recommended_next_stage=FC-O45-E-AX approval-gated install restricted VM200 static-deploy access

=== AW conclusion ===
Do not retry deploy until VM200 Tailscale restricted deploy access is installed under explicit AX approval.
```
