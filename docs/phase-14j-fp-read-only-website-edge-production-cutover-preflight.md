# Phase 14J-FP - Website-edge production cutover preflight, no apply

PHASE_14J_FP_READ_ONLY_WEBSITE_EDGE_PRODUCTION_CUTOVER_PREFLIGHT

## Status

Result: preflight_passed_no_apply.

This phase records the read-only baseline and pre-apply validation performed after Phase 14J-FO. It does not apply any Cloudflare production route mutation and does not replace apex/root or any primary public route.

## Starting checkpoint

Previous Source/repo checkpoint:

- Phase: 14J-FO - website-edge production cutover plan only
- Commit: 16831d7
- Tag: controller-phase-14j-fo-plan-website-edge-production-cutover-no-apply-2026-06-17
- Repo state at preflight start: clean/current
- Production cutover status at start: not applied

## Preflight support repair

The first FP attempts found that the laptop did not have a resolvable `website-edge` SSH alias. The following support repair was completed before the final preflight:

- Tailscale peer for `website-edge` was online.
- Local laptop SSH alias `Host website-edge` was added/updated in `~/.ssh/config`.
- The laptop public SSH key was installed for the website-edge user.
- Final noninteractive SSH alias validation passed.
- Remote hostname validated as `website-edge`.
- Remote OS validated as Ubuntu 26.04 LTS.
- Remote SSH user validated as `jkg76nid`.

No Cloudflare route mutation, Tailscale ACL/grants/tag mutation, Tailscale SSH mode enablement, website-edge service mutation, nginx config mutation, CT101 call, worker start, model call, or production DB/job mutation occurred during this repair.

## FP-R4 no-sudo read-only baseline results

Phase 14J-FP-R4 completed with exit code 0.

Validated:

- repo clean/current at commit 16831d7;
- expected Phase 14J-FO tag points at commit 16831d7;
- website-edge hostname guard passed;
- website-edge OS: Ubuntu 26.04 LTS;
- Docker absent;
- Node absent;
- npm absent;
- nginx service active;
- local loopback root path returned HTTP 200;
- local loopback `/app.js` returned HTTP 200;
- local loopback `/styles.css` returned HTTP 200;
- local loopback `/queued_chat_config.js` returned HTTP 200;
- local root contained expected public wrapper markers;
- local root had no Cloudflare/error markers;
- `cloudflared` version observed as 2026.6.0;
- `cloudflared.service` active and enabled;
- `cloudflared.service` contains `--no-autoupdate`;
- `cloudflared.service` contains `EnvironmentFile=`;
- `cloudflared.service` contains `tunnel run`;
- `cloudflared-update.service` absent;
- `cloudflared-update.timer` absent;
- temporary hostname root returned HTTP 200;
- temporary hostname root contained expected wrapper marker;
- temporary hostname root had no Cloudflare/error markers;
- temporary hostname asset hashes matched website-edge loopback asset hashes;
- production apex `alexhartel.com` returned HTTP 200;
- production apex root contained expected wrapper/public marker;
- production apex asset hashes matched website-edge loopback asset hashes;
- `www.alexhartel.com` did not resolve during fingerprinting.

R4 warning:

- no-sudo `nginx -t` could not read a root-protected nginx site file;
- no-sudo token env file stat could not read the root-protected token env file;
- both gaps were intentionally completed in FP-R5 using sudo-only read-only checks.

## FP-R5 sudo-only read-only completion results

Phase 14J-FP-R5 completed with exit code 0.

Validated:

- sudo identity/location guard passed on website-edge;
- effective UID was root for read-only inspection only;
- `nginx -t` syntax was OK;
- `nginx -t` config test was successful;
- `cloudflared` version observed as 2026.6.0;
- `cloudflared.service` active and enabled;
- `cloudflared.service` contains `--no-autoupdate`;
- `cloudflared.service` contains `EnvironmentFile=`;
- `cloudflared.service` contains `tunnel run`;
- token env file owner/mode verified as `root:root 600`;
- token content was not printed;
- `cloudflared-update.service` absent;
- `cloudflared-update.timer` absent.

## Static asset hashes observed during FP-R4

Website-edge local loopback and temporary public hostname matched for:

- `/app.js`: `1658e5f03e754ae8fa563a5e7f3655ffbd6a3d368b230080a57c579670da203b`
- `/styles.css`: `c1e629398a7bb15ae9735fdb287cc0636cd36504031a93605783a45b12b55d19`
- `/queued_chat_config.js`: `5ea0fc240fbe42ee263e29a730e119b11e29759500dd0764f7ae37adff77765b`

Production apex `alexhartel.com` returned the same three static asset hashes during fingerprinting.

## Important interpretation

The matching production apex content is content parity, not proof that a production Cloudflare route mutation was applied.

No production route mutation was performed by Phase 14J-FP. Do not assume production route ownership has changed from content/hash parity alone.

## Current known hostname status

- `website-edge-test.alexhartel.com`: healthy temporary public hostname.
- `alexhartel.com`: HTTP 200 with expected wrapper/public markers and matching static asset hashes during FP-R4.
- `www.alexhartel.com`: did not resolve during FP-R4 fingerprinting.

## Safety gates satisfied by preflight

Gate B website-edge static runtime validation:

- nginx active: yes;
- nginx config test passes: yes;
- local loopback paths return 200: yes;
- `cloudflared.service` active/running/enabled: yes;
- `cloudflared-update.service` absent: yes;
- `cloudflared-update.timer` absent: yes;
- token env file root-owned `0600`: yes;
- temporary hostname smoke passes: yes.

Gate C is not satisfied because no production cutover apply approval has been given.

Gate D rollback readiness still requires explicit rollback route target or rollback method before any production apply.

## Still not performed

- no Cloudflare production route mutation;
- no apex/root route replacement by this phase;
- no primary public route replacement by this phase;
- no global Cloudflare API key use;
- no broad Cloudflare account token use;
- no token printing;
- no token in repo;
- no token in Source files;
- no token in ChatGPT;
- no Proxmox public exposure;
- no nginx config mutation;
- no Docker install;
- no Node/npm install;
- no Tailscale ACL/grants/tag mutation;
- no Tailscale SSH mode enablement;
- no subnet routes;
- no exit node;
- no controller/queue migration;
- no worker start;
- no production DB/job mutation;
- no CT101 call;
- no model/Ollama endpoint call;
- no Phase 14J-AG apply wrapper rerun.

## Required approval before any future apply

A future production apply phase requires a new explicit approval that names:

- exact production hostname or hostnames;
- exact Cloudflare route target;
- rollback route target or rollback method;
- that this is production cutover apply;
- no controller/queue/worker/CT101/model/DB mutation;
- no Proxmox public exposure;
- no secrets printed.

## Phase result

PHASE_14J_FP_RESULT=read_only_preflight_passed_no_apply

NEXT_SAFE_PHASE=production_cutover_apply_only_if_explicitly_approved_with_exact_hostname_route_target_and_rollback_or_source_refresh_handoff

www.alexhartel.com did not resolve during FP-R4 fingerprinting

nginx -t config test was successful

token env file owner/mode verified as root:root 600

cloudflared-update.service absent

cloudflared-update.timer absent
