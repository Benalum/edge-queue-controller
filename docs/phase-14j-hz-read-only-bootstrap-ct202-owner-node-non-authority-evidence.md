# Phase 14J-HZ - Read-only bootstrap CT202 owner-node non-authority evidence

Date: 2026-06-17

## Scope

This phase records the new-chat bootstrap evidence after the Phase 14J-HY Source refresh.

Mutation scope:

- docs/smoke only;
- no CT202 restore;
- no CT202 candidate rebuild;
- no CT202 schema apply;
- no CT202 data migration/import/copy/dump;
- no `systemctl start`, `stop`, `restart`, `reload`, `enable`, or `disable`;
- no CT202 onboot/autostart mutation;
- no public route, Cloudflare, DNS, or tunnel mutation;
- no laptop controller stop/pause;
- no live DB mutation;
- no CT101, model/Ollama, or worker call;
- no destructive GitHub branch/repository deletion.

## Source checkpoint confirmed

The new-chat Source checkpoint remained:

- Phase: `14J-HY`
- Commit: `e696b1f`
- Tag: `controller-phase-14j-hy-ct202-candidate-rebuild-no-apply-decision-review-2026-06-17`
- Repo state: clean
- Decision result: `CONTINUE_NO_APPLY_PLANNING_UNTIL_SOURCE_REFRESH_OR_EXPLICIT_REAL_MUTATION_BOUNDARY`

## Laptop authority evidence

The laptop remained the live controller/queue authority.

Read-only bootstrap evidence showed:

- local listener on checked port `7070`;
- local listener on checked port `8787`;
- local listener on checked port `8765`;
- `edge-queue-controller.service`: `active`;
- `edge-wrapper-ui.service`: `active`;
- laptop-local `edge_queue.sqlite3` quick_check: `ok`;
- laptop-local app table count: `39`.

The earlier `7070 /health` HTTP probe returned `000`, but subsequent listener and systemd evidence showed the laptop controller service was active. This was classified as a probe/path issue, not as proof of controller outage.

## Proxmox access-path evidence

Initial bootstrap could not reach Proxmox through the bare `pveso` SSH alias.

Read-only access discovery found:

- `website-edge` was reachable over SSH, but it had no `pct` or `pvesh`;
- `pvew` was reachable over a Tailscale-derived direct target as `root` and had `pct`/`pvesh`;
- `pveso` was also reachable over a Tailscale-derived direct target as `root` and had `pct`/`pvesh`;
- CT202 ownership was then verified on `pveso`.

No SSH config was mutated. No permanent access-path change was installed by this phase.

## CT202 owner-node evidence

Strict read-only owner-node discovery found:

- CT202 owner node: `pveso`;
- CT202 Proxmox config present on `pveso`;
- CT202 status: `running`;
- CT202 onboot/autostart: `0`.

This corrected the earlier weaker check where `pvew` was reachable but did not own CT202.

## CT202 non-authority evidence

Inside CT202, strict read-only posture verification showed:

- hostname: `edge-controller`;
- service unit: `edge-queue-controller.service`;
- service enabled state: `disabled`;
- service active state: `inactive`;
- listener count on `7070`: `0`;
- listener count on `8787`: `0`;
- listener count on `8765`: `0`;
- DB path present: `/srv/edge-controller/data/edge_queue.sqlite3`;
- DB size: `262144`;
- DB quick_check: `ok`.

Result:

`STRICT_BOOTSTRAP_RESULT=PASS_CT202_OWNER_NODE_AND_NON_AUTHORITY_VERIFIED`

## Current conclusion

The new-chat bootstrap baseline is now valid:

- repo remained clean at Phase 14J-HY before this HZ docs/smoke checkpoint;
- laptop controller and laptop-local DB remained live authority;
- CT202 was located on its owner node;
- CT202 remained private and non-authoritative;
- CT202 service remained disabled/inactive;
- CT202 onboot remained `0`;
- no checked CT202 runtime listener was active;
- no restore, rebuild, schema apply, import, cutover, route change, laptop stop/pause, CT101 call, model call, or worker start occurred.

## Next allowed scope

Allowed next scope remains one of:

1. continue no-apply/no-restore planning or artifact work; or
2. stop and define a separate explicit real-mutation boundary.

This phase does not approve any real CT202 mutation.
