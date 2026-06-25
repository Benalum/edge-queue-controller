# Stage 16 FC-O45-E-AV-R3 — VM200 Access Method Discovery

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `771d049`
- Prior readiness tag: `controller-stage-16-fc-o45-e-au-companion-immersion-deploy-readiness-2026-06-24`

## Why this phase exists

AV-R1 failed before live mutation because the command mixed a tar stream with an SSH heredoc.

AV-R2 fixed the package upload pattern, but failed before live mutation because PVEW could not SSH into VM200:

```
REFUSE_VM200_SSH_UNREACHABLE_FROM_PVEW
```

This phase discovers the correct VM200 access method before another deploy attempt.

## Scope

This phase is read-only access discovery plus repo docs/smoke/commit/tag/push.

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
- NO service restart/reload/start/stop/enable/disable.
- NO CT/VM restart.
- NO nginx/cloudflared config mutation.
- NO storage mutation.
- NO file deletion.

## Live deploy state

The Companion Immersion UI source remains ready in the repo, but it is not live unless a later deploy succeeds.

## Candidate next deploy phase

After this discovery, use:

```
FC-O45-E-AV-R4
```

R4 should use the access method discovered here, likely one of:

- QEMU guest agent into VM200,
- corrected VM200 SSH host/IP/user/key,
- another verified VM200 static deploy path.

## Live discovery output

```
=== Stage 16 FC-O45-E-AV-R3 VM200 access method discovery ===
MUTATION_SCOPE=read_only_vm200_access_discovery_plus_repo_doc_smoke_commit_tag_push
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
NO service restart/reload/start/stop/enable/disable
NO CT/VM restart
NO nginx/cloudflared config mutation
NO storage mutation
NO file deletion

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=771d049
head_now=771d049
origin_main_now=771d049
git_preflight=PASS

=== public current state, read-only ===
public_root_http=200
public_app_js_http=200
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045eader2"
<script src="/queued_chat_config.js"
    title.textContent = "Companion result reader";

=== PVEW / VM200 access discovery, read-only ===
--- pvew posture ---
pvew
2026-06-25T00:11:06Z
status: running
agent: enabled=1
boot: order=ide2;scsi0
cores: 2
cpu: host
description: AI Platform Control website-edge VM. Created stopped in Phase 14J-EW retry after approved pvecm expected 1. No Cloudflare cutover. No controller/queue migration. No worker/runtime activation.
ide2: none,media=cdrom
memory: 2048
meta: creation-qemu=10.1.2,ctime=1781723019
name: website-edge
net0: virtio=BC:24:11:46:32:17,bridge=vmbr0
onboot: 1
ostype: l26
scsi0: local-lvm:vm-200-disk-0,discard=on,iothread=1,size=20G
scsihw: virtio-scsi-pci
smbios1: uuid=0df393ea-aaea-4e2e-9f0b-f5c6ce428db4
tablet: 1
vmgenid: a73a98a9-9153-42c2-b826-ce6be9c6552c

--- VM200 guest agent probes, read-only ---
guest_ping:

guest_network_get_interfaces:
[
   {
      "hardware-address" : "00:00:00:00:00:00",
      "ip-addresses" : [
         {
            "ip-address" : "127.0.0.1",
            "ip-address-type" : "ipv4",
            "prefix" : 8
         },
         {
            "ip-address" : "::1",
            "ip-address-type" : "ipv6",
            "prefix" : 128
         }
      ],
      "name" : "lo",
      "statistics" : {
         "rx-bytes" : 620778327,
         "rx-dropped" : 0,
         "rx-errs" : 0,
         "rx-packets" : 631157,
         "tx-bytes" : 620778327,
         "tx-dropped" : 0,
         "tx-errs" : 0,
         "tx-packets" : 631157
      }
   },
   {
      "hardware-address" : "bc:24:11:46:32:17",
      "ip-addresses" : [
         {
            "ip-address" : "192.168.0.144",
            "ip-address-type" : "ipv4",
            "prefix" : 24
         },
         {
            "ip-address" : "2601:8c0:800:7627:be24:11ff:fe46:3217",
            "ip-address-type" : "ipv6",
            "prefix" : 64
         },
         {
            "ip-address" : "fe80::be24:11ff:fe46:3217",
            "ip-address-type" : "ipv6",
            "prefix" : 64
         }
      ],
      "name" : "ens18",
      "statistics" : {
         "rx-bytes" : 1058900680,
         "rx-dropped" : 21253,
         "rx-errs" : 0,
         "rx-packets" : 4310479,
         "tx-bytes" : 990460035,
         "tx-dropped" : 0,
         "tx-errs" : 0,
         "tx-packets" : 3418197
      }
   },
   {
      "hardware-address" : "00:00:00:00:00:00",
      "ip-addresses" : [
         {
            "ip-address" : "<redacted-tailscale-ip>",
            "ip-address-type" : "ipv4",
            "prefix" : 32
         },
         {
            "ip-address" : "fd7a:115c:a1e0::e43a:8546",
            "ip-address-type" : "ipv6",
            "prefix" : 128
         },
         {
            "ip-address" : "fe80::327f:a1c6:2ac2:ee89",
            "ip-address-type" : "ipv6",
            "prefix" : 64
         }
      ],
      "name" : "tailscale0",
      "statistics" : {
         "rx-bytes" : 26609,
         "rx-dropped" : 0,
         "rx-errs" : 0,
         "rx-packets" : 124,
         "tx-bytes" : 28984,
         "tx-dropped" : 0,
         "tx-errs" : 0,
         "tx-packets" : 228
      }
   }
]

guest_hostname_exec:
{
   "exitcode" : 0,
   "exited" : 1,
   "out-data" : "website-edge\n",
   "out-truncated" : 0
}

guest_ip_exec:
{
   "exitcode" : 0,
   "exited" : 1,
   "out-data" : "lo               UNKNOWN        127.0.0.1/8 ::1/128 \nens18            UP             192.168.0.144/24 metric 100 2601:8c0:800:7627:be24:11ff:fe46:3217/64 fe80::be24:11ff:fe46:3217/64 \ntailscale0       UNKNOWN        <redacted-tailscale-ip>/32 fd7a:115c:a1e0::e43a:8546/128 fe80::327f:a1c6:2ac2:ee89/64 \n",
   "out-truncated" : 0
}

--- PVEW route/neigh/DNS observations, read-only ---
getent hosts:
vm200 -> vm-200 -> website-edge -> <redacted-tailscale-ip>  website-edge.tail40a52f.ts.net
website-edge.local -> 
ip route:
default via 192.168.0.1 dev vmbr0 proto kernel onlink 
192.168.0.0/24 dev vmbr0 proto kernel scope link src 192.168.0.11 

ip neigh likely VM candidates:
192.168.0.200 dev vmbr0 FAILED 
192.168.0.250 dev vmbr0 lladdr bc:24:11:bd:e6:9d STALE 
192.168.0.12 dev vmbr0 lladdr d8:bb:c1:03:fc:33 STALE 
192.168.0.144 dev vmbr0 lladdr bc:24:11:46:32:17 REACHABLE 
192.168.0.146 dev vmbr0 lladdr 58:1c:f8:6b:3d:ca REACHABLE 
192.168.0.1 dev vmbr0 lladdr 68:7f:f0:67:1d:ec REACHABLE 
fe80::be24:11ff:febd:e69d dev vmbr0 lladdr bc:24:11:bd:e6:9d STALE 
fe80::be24:11ff:fe46:3217 dev vmbr0 lladdr bc:24:11:46:32:17 STALE 
fe80::52d4:5cff:fe99:79fa dev vmbr0 lladdr 50:d4:5c:99:79:fa STALE 
fe80::9acc:f3ff:feb6:54b9 dev vmbr0 lladdr 98:cc:f3:b6:54:b9 STALE 
fe80::6a7f:f0ff:fe67:1dec dev vmbr0 lladdr 68:7f:f0:67:1d:ec router STALE 
fe80::809:3c89:8771:8185 dev vmbr0 lladdr ec:28:d3:b2:12:c3 STALE 
fe80::b28b:a8ff:fef2:56b1 dev vmbr0 lladdr b0:8b:a8:f2:56:b1 STALE 
fe80::872:cb1d:2f16:d305 dev vmbr0 lladdr 06:5f:ba:ea:0b:d8 STALE 
fe80::865:1d77:f3de:990b dev vmbr0 lladdr 16:a4:18:89:cb:14 STALE 
fe80::4b:1cf7:94dd:3541 dev vmbr0 lladdr 06:5f:ba:ea:0b:d8 STALE 
fe80::1404:4d43:7e3f:b507 dev vmbr0 lladdr 16:a4:18:89:cb:14 STALE 
fe80::c2:3753:81cc:2180 dev vmbr0 lladdr 7a:66:84:68:8b:eb STALE 
fe80::140d:cc34:90a2:5fca dev vmbr0 lladdr 1e:9e:24:51:87:74 STALE 
fe80::4d2:df3d:59a8:7364 dev vmbr0 lladdr 7e:9e:76:d7:f1:48 STALE 
fe80::1cdd:5966:9bc:3c dev vmbr0 lladdr 2a:1b:de:3a:e4:c2 STALE 
fe80::14d9:df16:1dfe:22c dev vmbr0 lladdr 06:5f:ba:ea:0b:d8 STALE 
fe80::18cd:9583:a5db:6788 dev vmbr0 lladdr b2:23:f4:e7:9d:c6 STALE 

bridge fdb snippets:
1e:9e:24:51:87:74 dev nic0 master vmbr0 
7a:66:84:68:8b:eb dev nic0 master vmbr0 
7e:9e:76:d7:f1:48 dev nic0 master vmbr0 
58:1c:f8:6b:3d:ca dev nic0 master vmbr0 
50:d4:5c:99:79:fa dev nic0 master vmbr0 
98:cc:f3:b6:54:b9 dev nic0 master vmbr0 
b0:8b:a8:f2:56:b1 dev nic0 master vmbr0 
10:00:3b:09:b9:28 dev nic0 master vmbr0 
10:00:3b:0a:54:10 dev nic0 master vmbr0 
68:7f:f0:67:1d:ec dev nic0 master vmbr0 
f0:2f:74:c9:b3:e5 dev nic0 vlan 1 master vmbr0 permanent
f0:2f:74:c9:b3:e5 dev nic0 master vmbr0 permanent
33:33:00:00:00:01 dev nic0 self permanent
01:00:5e:00:00:01 dev nic0 self permanent
33:33:00:00:00:01 dev vmbr0 self permanent
33:33:00:00:00:02 dev vmbr0 self permanent
01:00:5e:00:00:6a dev vmbr0 self permanent
33:33:00:00:00:6a dev vmbr0 self permanent
01:00:5e:00:00:01 dev vmbr0 self permanent
33:33:ff:c9:b3:e5 dev vmbr0 self permanent
33:33:ff:00:00:00 dev vmbr0 self permanent
bc:24:11:46:32:17 dev tap200i0 master vmbr0 
ba:f2:ea:4d:62:f1 dev tap200i0 vlan 1 master vmbr0 permanent
ba:f2:ea:4d:62:f1 dev tap200i0 master vmbr0 permanent
33:33:00:00:00:01 dev tap200i0 self permanent
01:00:5e:00:00:01 dev tap200i0 self permanent
bc:24:11:bd:e6:9d dev veth203i0 master vmbr0 
fe:ed:51:b5:45:f3 dev veth203i0 vlan 1 master vmbr0 permanent
fe:ed:51:b5:45:f3 dev veth203i0 master vmbr0 permanent
33:33:00:00:00:01 dev veth203i0 self permanent
01:00:5e:00:00:01 dev veth203i0 self permanent

--- SSH reachability matrix from PVEW, read-only/no command mutation ---
ssh_probe_host=vm200
debug3: Started with: ssh -n -vvv -o BatchMode=yes -o ConnectTimeout=4 -o StrictHostKeyChecking=accept-new root@vm200 hostname
ssh: Could not resolve hostname vm200: Name or service not known

ssh_probe_host=vm-200
debug3: Started with: ssh -n -vvv -o BatchMode=yes -o ConnectTimeout=4 -o StrictHostKeyChecking=accept-new root@vm-200 hostname
ssh: Could not resolve hostname vm-200: Name or service not known

ssh_probe_host=website-edge
debug3: Started with: ssh -n -vvv -o BatchMode=yes -o ConnectTimeout=4 -o StrictHostKeyChecking=accept-new root@website-edge hostname
debug1: Connecting to website-edge [<redacted-tailscale-ip>] port 22.
debug1: Authenticating to website-edge:22 as 'root'
debug1: Offering public key: /root/.ssh/id_rsa RSA SHA256:lENyvwB0qKcScq4RJQ8MXhjGS+Zj1OCfidQOf65Ltdo
debug1: Offering public key: /root/.ssh/id_ed25519 ED25519 SHA256:AInRZAW5hNJB6SXkwPOpJcCNItwhuGR6FVmk4NP2WMo
root@website-edge: Permission denied (publickey,password,keyboard-interactive).

ssh_probe_host=website-edge.local
debug3: Started with: ssh -n -vvv -o BatchMode=yes -o ConnectTimeout=4 -o StrictHostKeyChecking=accept-new root@website-edge.local hostname
ssh: Could not resolve hostname website-edge.local: Name or service not known

ssh_probe_host=192.168.0.200
debug3: Started with: ssh -n -vvv -o BatchMode=yes -o ConnectTimeout=4 -o StrictHostKeyChecking=accept-new root@192.168.0.200 hostname
debug2: resolve_canonicalize: hostname 192.168.0.200 is address
debug1: Connecting to 192.168.0.200 [192.168.0.200] port 22.
debug1: connect to address 192.168.0.200 port 22: No route to host
ssh: connect to host 192.168.0.200 port 22: No route to host

ssh_probe_host=<redacted-private-ip>
debug3: Started with: ssh -n -vvv -o BatchMode=yes -o ConnectTimeout=4 -o StrictHostKeyChecking=accept-new root@<redacted-private-ip> hostname
debug2: resolve_canonicalize: hostname <redacted-private-ip> is address
debug1: Connecting to <redacted-private-ip> [<redacted-private-ip>] port 22.
debug1: connect to address <redacted-private-ip> port 22: Connection timed out
ssh: connect to host <redacted-private-ip> port 22: Connection timed out

--- local public curl from PVEW, read-only ---
pvew_public_root_http=200
<script src="router_shadow_read_stub.js?v=2026061208k"
<script src="/app.js?v=20260624fc045eader2"
<script src="/queued_chat_config.js"

--- suggested deploy methods from discovery ---
candidate_method=qemu_guest_agent
candidate_method=ssh_root_website_edge_not_ready

=== AV-R3 conclusion ===
R3 is read-only. Use the observed reachable method for AV-R4 deploy.
```
