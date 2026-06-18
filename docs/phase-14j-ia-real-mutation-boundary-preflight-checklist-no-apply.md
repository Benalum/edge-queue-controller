# Phase 14J-IA - Real-mutation boundary preflight checklist, no apply

Date: 2026-06-17

## Scope

This phase defines the checklist that must be satisfied before any future CT202 real-mutation boundary can be opened.

Mutation scope for this phase:

- docs/smoke only;
- no CT202 restore;
- no CT202 candidate rebuild;
- no CT202 schema apply;
- no CT202 data migration/import/copy/dump;
- no SQLite `.dump` or row-content output;
- no `systemctl start`, `stop`, `restart`, `reload`, `enable`, or `disable`;
- no CT202 onboot/autostart mutation;
- no public route, Cloudflare, DNS, or tunnel mutation;
- no laptop controller stop/pause;
- no live DB mutation;
- no CT101, model/Ollama, or worker call;
- no destructive GitHub branch/repository deletion.

This phase does not approve any real mutation.

## Current checkpoint

Base checkpoint for this phase:

- Phase: `14J-HZ`
- Commit: `4a4459a`
- Tag: `controller-phase-14j-hz-read-only-bootstrap-ct202-owner-node-non-authority-evidence-2026-06-17`
- HZ result: `PASS_HZ_COMMIT_TAG_PUSH_VERIFIED_WITH_ANNOTATED_TAG_DEREFERENCE`

## Current authority state carried forward

The current authority posture remains:

- laptop controller remains live controller/queue authority;
- laptop-local `edge_queue.sqlite3` remains live primary controller platform data authority;
- CT202 remains a private future controller candidate only;
- CT202 is not public authority;
- CT202 is not data authority;
- no public route points to CT202 from this migration path.

## HZ bootstrap evidence carried forward

Phase 14J-HZ verified:

- CT202 owner node: `pveso`;
- CT202 Proxmox config present on `pveso`;
- CT202 status: `running`;
- CT202 onboot/autostart: `0`;
- CT202 hostname: `edge-controller`;
- CT202 service enabled state: `disabled`;
- CT202 service active state: `inactive`;
- CT202 listener count on checked port `7070`: `0`;
- CT202 listener count on checked port `8787`: `0`;
- CT202 listener count on checked port `8765`: `0`;
- CT202 DB path present: `/srv/edge-controller/data/edge_queue.sqlite3`;
- CT202 DB size: `262144`;
- CT202 DB quick_check: `ok`.

## Backup evidence required before any future real mutation

The following retained backup evidence must be verified again before any future CT202 restore/rebuild/schema apply/data replacement boundary:

- backup directory: `/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z`;
- CT202 backup DB size: `262144`;
- CT202 backup DB sha256: `43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314`;
- manifest sha256: `dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491`;
- rollback checklist sha256: `3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6`.

## Required preflight before opening a future real-mutation boundary

A future real-mutation boundary must first prove all of the following read-only checks:

1. Repo is clean at the latest committed checkpoint.
2. Local `HEAD`, `origin/main`, local tag target, and remote tag target agree.
3. Annotated tag verification uses tag dereference with `^{}` instead of comparing only the annotated tag object SHA.
4. Laptop controller service is active.
5. Laptop wrapper service is active.
6. Laptop-local DB quick_check is `ok`.
7. Laptop-local application table count is still `39`, or any difference is explicitly explained before mutation.
8. CT202 owner node is identified again and is reachable read-only.
9. CT202 owner node is still `pveso`, or any owner-node change is explicitly explained before mutation.
10. CT202 onboot/autostart is still `0`.
11. CT202 service is still `disabled`.
12. CT202 service is still `inactive`.
13. CT202 checked listener count on `7070` is `0`.
14. CT202 checked listener count on `8787` is `0`.
15. CT202 checked listener count on `8765` is `0`.
16. CT202 DB path exists.
17. CT202 DB quick_check is `ok`.
18. HM/HN backup hashes are still verified.
19. Public route ownership is unchanged.
20. No Cloudflare/DNS/tunnel mutation has occurred.
21. No CT101/model/Ollama/worker call is part of the mutation boundary.
22. Exact mutation target is defined.
23. Exact source authority is defined.
24. Exact preservation artifact behavior is defined.
25. Exact rollback stop condition is defined.
26. Exact post-mutation verification is defined.
27. Exact failure handling is defined.
28. A separate explicit approval boundary is requested and granted before any real mutation command is provided.

## Real-mutation boundary requirements

A future real-mutation boundary must be separate from no-apply planning and must name the intended mutation class exactly.

Examples that require a separate explicit real-mutation boundary:

- CT202 restore;
- CT202 candidate DB rebuild;
- CT202 schema apply;
- CT202 data migration/import/copy/dump;
- CT202 runtime start;
- CT202 runtime enable;
- CT202 onboot/autostart mutation;
- public route mutation;
- Cloudflare/DNS/tunnel mutation;
- laptop authority removal;
- laptop controller stop/pause.

## Current recommendation

Continue no-apply planning/artifact work unless the project deliberately opens a separate explicit real-mutation boundary.

This phase does not define an approval phrase and does not approve mutation.
