# Phase 14J-FO - Website-edge production cutover plan only

Date: 2026-06-17

## Phase marker

PHASE_14J_FO_PLAN_WEBSITE_EDGE_PRODUCTION_CUTOVER_NO_APPLY

## Purpose

Plan the production cutover from the current public wrapper route to the website-edge static tunnel path without applying any Cloudflare route mutation.

This is a planning-only phase. It records the exact cutover guardrails, validation order, rollback expectations, and explicit approval requirements for a future apply phase.

## Previous repo checkpoint

Previous repo phase: Phase 14J-FN-R8 - website-edge minimal cloudflared service temporary hostname
Previous commit: ab6aac3
Previous tag: controller-phase-14j-fn-r8-minimal-cloudflared-service-temp-hostname-2026-06-17

## Current proven runtime state

FN-R8 proved the following on website-edge:

- website-edge VM 200 serves the static wrapper locally through nginx on loopback port 18080.
- cloudflared is installed at /usr/local/bin/cloudflared.
- minimal cloudflared.service is active, running, and enabled.
- cloudflared.service uses --no-autoupdate.
- cloudflared.service uses a root-owned 0600 EnvironmentFile.
- cloudflared-update.service was not created.
- cloudflared-update.timer was not created.
- temporary hostname website-edge-test.alexhartel.com passed public smoke.
- public root path passed marker validation.
- public static assets passed exact hash validation.
- no apex/root production cutover was performed.
- no primary public route replacement was performed.

## Production cutover status

PRODUCTION_CUTOVER_STATUS=not_performed
APEX_ROOT_ROUTE_REPLACEMENT_STATUS=not_performed
PRIMARY_PUBLIC_ROUTE_REPLACEMENT_STATUS=not_performed
TEMPORARY_TEST_HOSTNAME_STATUS=active_and_smoked

## Future cutover goal

Future production cutover goal:

- Route the public static wrapper/home surface to website-edge tunnel origin.
- Keep controller/queue/worker/CT101/model services private.
- Preserve existing public API ownership boundaries.
- Avoid exposing Proxmox, Tailscale admin, controller internals, database, worker runtime, or model endpoints.
- Preserve a fast rollback path to the previous public route.

## Candidate production hostnames

Production hostnames must be handled separately and explicitly.

Potential production hostname candidates:

- alexhartel.com
- www.alexhartel.com

The following must not be moved as part of a static wrapper cutover unless separately planned and approved:

- API routes
- authenticated app API routes
- CT101-owned routes
- companion runtime APIs
- study runtime APIs
- calendar runtime APIs
- controller queue APIs
- admin/control endpoints

## Required pre-apply checks for future cutover

A future cutover apply phase must begin with read-only checks:

1. Confirm repo clean and current.
2. Confirm Phase 14J-FN-R8 tag exists and points to current expected checkpoint.
3. Confirm website-edge nginx is active.
4. Confirm website-edge nginx config test passes.
5. Confirm local static wrapper paths return 200 on loopback 18080.
6. Confirm cloudflared.service is active, running, and enabled.
7. Confirm cloudflared service is minimal no-autoupdate service.
8. Confirm cloudflared-update.service is absent.
9. Confirm cloudflared-update.timer is absent.
10. Confirm token file exists only as root-owned 0600.
11. Confirm token content is not printed.
12. Confirm temporary hostname public smoke still passes.
13. Confirm no Docker, Node, or npm was installed on website-edge.
14. Confirm no Cloudflare apt repo/key was added.
15. Confirm no controller/queue/worker/CT101/model mutation is needed.

## Future cutover apply method

A future apply phase must use the Cloudflare dashboard or a separately approved scoped Cloudflare mechanism.

The future apply phase must:

- use only a dedicated Cloudflare tunnel/public hostname routing change;
- target website-edge tunnel;
- target origin service http://127.0.0.1:18080 inside website-edge;
- avoid printing tokens or account secrets;
- avoid raw auth URLs;
- avoid broad account tokens;
- avoid global API keys;
- avoid any app runtime deployment;
- avoid nginx config mutation unless separately planned;
- avoid database and job mutation;
- avoid model calls.

## Future cutover validation

After production cutover apply, validation must check production hostnames only for static wrapper behavior:

- production root returns HTTP 200;
- production root contains expected wrapper markers;
- production root does not contain Cloudflare error markers;
- production /app.js returns 200 and exact hash matches website-edge local file;
- production /styles.css returns 200 and exact hash matches website-edge local file;
- production /queued_chat_config.js returns 200 and exact hash matches website-edge local file;
- temporary hostname remains valid or is intentionally retired only after production validation;
- controller/queue/CT101/model endpoints remain private and are not called during this static cutover smoke.

## Rollback plan for future cutover

Future rollback must be prepared before apply.

Rollback must be able to:

- restore previous Cloudflare route target for production hostname;
- keep website-edge cloudflared service untouched unless the rollback reason is website-edge service failure;
- avoid deleting the tunnel token unless explicitly retiring website-edge tunnel;
- avoid touching Proxmox public exposure because none should be created;
- avoid CT101/model/worker/controller/DB mutation;
- preserve temporary hostname as a fallback diagnostic path until the new production route is stable.

## Forbidden operations for future cutover apply

The following remain denied unless separately approved:

cloudflare_global_api_key_use=no
broad_cloudflare_account_token_use=no
cloudflare_secret_printing=no
token_in_apc_last_output=no
token_in_chatgpt=no
token_in_source_files=no
apex_root_cutover_without_explicit_apply_approval=no
primary_public_route_replacement_without_explicit_apply_approval=no
proxmox_public_exposure=no
nginx_config_mutation=no
docker_install=no
node_npm_install=no
tailscale_acl_grants_tag_mutation=no
tailscale_ssh_mode_enablement=no
subnet_routes=no
exit_node=no
controller_queue_migration=no
worker_start=no
production_db_job_mutation=no
ct101_call=no
model_ollama_endpoint_call=no
phase_14j_ag_apply_wrapper_rerun=no

## Required approval text for future apply phase

A future production apply phase requires a new explicit approval. The approval must name:

- the exact production hostname or hostnames;
- the exact Cloudflare route target;
- the rollback route target or rollback method;
- that this applies a production cutover;
- that no controller/queue/worker/CT101/model/db mutation is allowed;
- that no Proxmox management path is exposed;
- that no secrets may be printed.

## Phase result

PHASE_14J_FO_RESULT=production_cutover_plan_recorded_no_apply
CLOUDFLARE_ROUTE_MUTATION_PERFORMED=no
PRODUCTION_CUTOVER_PERFORMED=no
WEBSITE_EDGE_MUTATION_PERFORMED=no
TOKEN_USED=no
TOKEN_PRINTED=no
TEMPORARY_TEST_HOSTNAME_LEFT_ACTIVE=yes

## Next safe phase

NEXT_SAFE_PHASE=explicit_approval_required_for_website_edge_production_cutover_apply_or_source_refresh_new_chat_handoff
