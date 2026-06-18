# Phase 14J-HF - Read-only schema-detail preflight, no migration/no apply

Date: 2026-06-17  
Type: approved read-only live preflight / docs-smoke record  
Previous checkpoint: Phase 14J-HE at commit `da185c2`  
Approval phrase used: `APPROVE_PHASE_14J_HF_READ_ONLY_SCHEMA_DETAIL_PREFLIGHT_NO_MIGRATION_NO_APPLY`

## Purpose

Record the approved read-only schema-detail preflight comparing safe schema metadata between:

- laptop-local live controller DB: `edge_queue.sqlite3`;
- CT202 candidate DB: `/srv/edge-controller/data/edge_queue.sqlite3`.

This phase collected column/index/foreign-key metadata only. It did not print row content, SQL dumps, full CREATE TABLE dumps, default values, or secrets.

## Mutation boundary

This phase was read-only.

It did not perform:

- CT202 authority cutover;
- data authority path selection;
- CT202 data migration or import;
- schema migration;
- SQLite copy;
- SQL dump;
- full CREATE TABLE dump;
- table data dump;
- row content output;
- default value output;
- live laptop DB mutation;
- CT202 DB mutation;
- backup creation;
- restore operation;
- `systemctl start`;
- `systemctl enable`;
- CT202 onboot/autostart mutation;
- VM start, stop, or reboot;
- Cloudflare, DNS, or tunnel mutation;
- public route mutation;
- laptop controller stop or pause;
- CT101 call;
- model/Ollama endpoint call;
- worker start;
- production DB/job mutation;
- secret generation, printing, or installation;
- destructive GitHub branch or repository deletion.

## Repo guard

The read-only preflight started from:

- HEAD: `da185c2`;
- local `origin/main`: `da185c2`;
- working tree: clean.

## Tooling note

The first HF attempt failed safely before CT202 schema collection because a temporary collector script was copied to the Proxmox host `/tmp`, but `pct exec` looked for it inside CT202 `/tmp`.

HF-R2 corrected this by streaming the collector through `pct exec` stdin.

HF-R2 completed successfully and did not create a CT202 temp script file.

## Laptop schema-detail result

Laptop DB safe metadata:

- quick_check: `ok`;
- table count: `39`;
- overall schema-detail hash SHA256: `e2d8ac2fc582791e6e995cd2d8d84f4df47ee14d67fdac0a2d6b9eb62c21ef6d`.

Focus table details recorded:

- `app_users`: columns=`19`, indexes=`1`, unique indexes=`1`, foreign keys=`0`, hash=`82d155cf76d4c461e75ae9f9f9b6f0e6f1fa98cdabe3819f19ca090238c7ac87`;
- `user_sessions`: columns=`8`, indexes=`1`, unique indexes=`1`, foreign keys=`1`, hash=`f5291e7d8cca2ceecd547cbbeb6112f287e396227796b23a7bc6524b1033574c`;
- `jobs`: columns=`11`, indexes=`0`, unique indexes=`0`, foreign keys=`0`, hash=`dd3f7500ab0d4b72661e0d20504badd41ba33f1ab43a5030b6afda9358bb521e`;
- `workers`: columns=`29`, indexes=`1`, unique indexes=`1`, foreign keys=`0`, hash=`054294d8d611e84254cb899d119551d9ec389ca4f0c109e1e25257879af56898`;
- `user_credit_ledger`: columns=`9`, indexes=`0`, unique indexes=`0`, foreign keys=`1`, hash=`dcad612a081fdf710c9925c7f94fa80054018941cc098ea3b4ce588b8d4eb746`;
- `credit_ledger`: missing;
- `user_credit_wallets`: missing;
- `study_decks`: columns=`7`, indexes=`0`, unique indexes=`0`, foreign keys=`1`, hash=`3b734ce6cb8e805da65ca562a9446ba2b2e5ad10099b5c036205f6f3a9614b41`;
- `study_cards`: columns=`11`, indexes=`0`, unique indexes=`0`, foreign keys=`2`, hash=`5168d464723204c2b9409a87d3ee41dfcc23843ff6c207245f922bdfd8b27a39`;
- `study_sessions`: columns=`14`, indexes=`1`, unique indexes=`0`, foreign keys=`3`, hash=`b7f7a0f77469f56fc5147c1adac8b33b4b8572c5fbe3784c298f7e10e94f5f40`;
- `calendar_events`: columns=`9`, indexes=`1`, unique indexes=`1`, foreign keys=`0`, hash=`94afdadb5abbb1b334313a3fea315ebd23686ee25ea6236ba327daf3a6d6e391`;
- `power_auto_state`: columns=`3`, indexes=`1`, unique indexes=`1`, foreign keys=`0`, hash=`fbc2f58748378d7553087c3547533f7dcdce695a7b7a843442caf16836765529`;
- `web_presence`: columns=`13`, indexes=`3`, unique indexes=`1`, foreign keys=`1`, hash=`e39e3e01b267f64471f9379676f2f2d6d6e90954782c7fc4cf8778b967d7ac92`.

## CT202 safety posture before schema-detail comparison

CT202 was checked before reading schema details:

- container status: running;
- hostname: `edge-controller`;
- onboot: `0`;
- service enabled state: `disabled`;
- service active state: `inactive`;
- no checked controller/smoke listener active.

CT202 remained private and non-authoritative throughout the preflight.

## CT202 schema-detail result

CT202 DB safe metadata:

- quick_check: `ok`;
- table count: `25`;
- overall schema-detail hash SHA256: `e3163d66a597658b76a2b031a28c4abff220cca194191a7f0e873c58ce31a171`.

Focus table details recorded:

- `app_users`: columns=`19`, indexes=`1`, unique indexes=`1`, foreign keys=`0`, hash=`82d155cf76d4c461e75ae9f9f9b6f0e6f1fa98cdabe3819f19ca090238c7ac87`;
- `user_sessions`: columns=`8`, indexes=`1`, unique indexes=`1`, foreign keys=`1`, hash=`f5291e7d8cca2ceecd547cbbeb6112f287e396227796b23a7bc6524b1033574c`;
- `jobs`: columns=`11`, indexes=`0`, unique indexes=`0`, foreign keys=`0`, hash=`dd3f7500ab0d4b72661e0d20504badd41ba33f1ab43a5030b6afda9358bb521e`;
- `workers`: columns=`21`, indexes=`1`, unique indexes=`1`, foreign keys=`0`, hash=`5733a69b71c323e6280b9fd5757d80ac26c9642dc0353babf0f8fc0a4dad3f0c`;
- `user_credit_ledger`: columns=`9`, indexes=`0`, unique indexes=`0`, foreign keys=`1`, hash=`dcad612a081fdf710c9925c7f94fa80054018941cc098ea3b4ce588b8d4eb746`;
- `credit_ledger`: columns=`7`, indexes=`1`, unique indexes=`0`, foreign keys=`0`, hash=`91cc6432ae4f4861459eb25565b71efbae1a626c86abc403ea165d6fc2be5d5b`;
- `user_credit_wallets`: columns=`5`, indexes=`0`, unique indexes=`0`, foreign keys=`0`, hash=`edac15d4153d38f97040d4475b79bcd8c183c7942c3cc092af9eea350762408f`;
- `study_decks`: missing;
- `study_cards`: missing;
- `study_sessions`: missing;
- `calendar_events`: missing;
- `power_auto_state`: missing;
- `web_presence`: columns=`13`, indexes=`3`, unique indexes=`1`, foreign keys=`1`, hash=`e39e3e01b267f64471f9379676f2f2d6d6e90954782c7fc4cf8778b967d7ac92`.

## Shared-table schema-detail comparison

Comparison result:

- tables on both: `23`;
- tables only on laptop: `16`;
- tables only on CT202: `2`;
- shared-table schema-detail hash match count: `21`;
- shared-table schema-detail hash mismatch count: `2`;
- overall schema-detail hash match: `no`.

Shared tables with matching detail hash:

- `app_user_preferences`;
- `app_users`;
- `global_phrase_bank`;
- `intent_definitions`;
- `intent_routes`;
- `jobs`;
- `password_reset_tokens`;
- `pending_email_signups`;
- `router_feedback`;
- `router_logs`;
- `router_resolution_steps`;
- `support_messages`;
- `support_tickets`;
- `user_credit_ledger`;
- `user_language_preferences`;
- `user_phrase_bank`;
- `user_secondary_languages`;
- `user_sessions`;
- `user_usage_limits`;
- `web_presence`;
- `worker_events`.

Shared tables with mismatched detail hash:

- `credit_reservations`: laptop columns=`15`, CT202 columns=`17`, laptop indexes=`1`, CT202 indexes=`3`, laptop foreign keys=`1`, CT202 foreign keys=`1`;
- `workers`: laptop columns=`29`, CT202 columns=`21`, laptop indexes=`1`, CT202 indexes=`1`, laptop foreign keys=`0`, CT202 foreign keys=`0`.

Tables only on laptop:

- `ad_reward_events`;
- `calendar_events`;
- `gpu_session_quotes`;
- `gpu_sessions`;
- `job_results`;
- `power_auto_state`;
- `power_events`;
- `power_idle_state`;
- `study_cards`;
- `study_deck_totals`;
- `study_decks`;
- `study_reviews`;
- `study_session_events`;
- `study_sessions`;
- `study_user_totals`;
- `web_power_policy_events`.

Tables only on CT202:

- `credit_ledger`;
- `user_credit_wallets`.

## Critical table presence and hash

Critical table status:

- `app_users`: laptop=present, CT202=present, detail hash match=`yes`;
- `user_sessions`: laptop=present, CT202=present, detail hash match=`yes`;
- `jobs`: laptop=present, CT202=present, detail hash match=`yes`;
- `workers`: laptop=present, CT202=present, detail hash match=`no`;
- `user_credit_ledger`: laptop=present, CT202=present, detail hash match=`yes`;
- `credit_ledger`: laptop=missing, CT202=present;
- `user_credit_wallets`: laptop=missing, CT202=present;
- `study_decks`: laptop=present, CT202=missing;
- `study_cards`: laptop=present, CT202=missing;
- `study_sessions`: laptop=present, CT202=missing;
- `calendar_events`: laptop=present, CT202=missing;
- `web_presence`: laptop=present, CT202=present, detail hash match=`yes`.

## Data-authority conclusion

HF-R2 narrowed the schema reconciliation problem:

1. Most shared tables match at safe schema-detail level.
2. Two shared tables require reconciliation:
   - `credit_reservations`;
   - `workers`.
3. CT202 is missing user-facing Study and Calendar tables that exist on the laptop.
4. CT202 has wallet/ledger credit tables that are missing on the laptop.
5. Laptop and CT202 overall schema-detail hashes do not match.
6. CT202 must not be promoted as-is under the assumption that it has equivalent schema/data authority.

No data authority path was selected by this phase.

## Recommended next safe step

Recommended next safe step:

- record a no-apply schema reconciliation decision plan focused on:
  - adding or omitting Study/Calendar tables;
  - reconciling `workers` lane metadata columns;
  - reconciling `credit_reservations`;
  - deciding whether CT202-only `credit_ledger` and `user_credit_wallets` are intended future schema;
  - deciding whether laptop should receive wallet tables before any migration;
  - deciding whether CT202 should be rebuilt from laptop schema or forward-migrated.

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

This phase does not open the cutover gate.

No data authority path is selected by this phase.

Do not run migration/import/copy/dump from this phase.
