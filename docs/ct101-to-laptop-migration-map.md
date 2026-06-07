# CT101 to Laptop Data Migration Map — Stage 5C

## Purpose

Stage 5C maps current CT101 database models and controller tables into the future laptop-owned data architecture.

This is planning and documentation only.

Do not migrate data in this stage.

## Current source snapshots

Controller/laptop repo checkpoint:

- 4bec1de Document laptop-owned data architecture plan

CT101 ai-platform repo checkpoint:

- a157cf6 Unify Chat and Companion under Chat tab

## Target ownership rule

Laptop/controller becomes the source of truth for user-facing data.

CT101 becomes a worker/model execution node.

## CT101 tables found

The CT101 SQLAlchemy models currently define:

- users
- user_sessions
- chats
- messages
- companion_study_sessions
- workers
- jobs
- user_profiles
- companion_profiles
- worker_nodes
- study_decks
- study_cards
- study_reviews
- calendar_events

## Controller tables found

The controller currently uses SQLite tables for controller/runtime state, including:

- jobs
- workers
- worker_events
- power_idle_state
- power_events
- power_auto_state

## Migration map

### users

Future owner: laptop/controller.

Reason: auth and account identity should remain available even when CT101 is offline.

Migration notes:

- Move email, display_name, password_hash, is_active, is_admin, created_at, updated_at, last_login_at.
- Preserve user ids if possible so study/chat/calendar foreign keys remain stable.
- Do not keep CT101 as alternate auth source after migration.

Risk:

- Authentication lockout if password hashes or session behavior are mishandled.

### user_sessions

Future owner: laptop/controller.

Reason: login/session state must work when CT101 is offline.

Migration notes:

- Move token_hash, created_at, expires_at, revoked_at.
- Decide whether old sessions are migrated or users are asked to log in again.
- Prefer forcing re-login during production cutover if safer.

Risk:

- Session mismatch between wrapper and CT101 direct frontend.

### user_profiles

Future owner: laptop/controller.

Reason: profile and safety context are user-facing and should be available offline.

Migration notes:

- Move display_name, age_years, country_code, region_code, is_minor, safety_notes.
- Preserve user_id uniqueness.

Risk:

- Safety behavior depends on profile state.

### companion_profiles

Future owner: laptop/controller.

Reason: companion personalization is user-facing data.

Migration notes:

- Move companion_name, personality_prompt, avatar paths, avatar_style, voice_id.
- File assets should be handled separately from database rows.

Risk:

- Avatar file paths may not exist on laptop unless asset migration is planned.

### chats

Future owner: laptop/controller.

Reason: chat threads should be visible and editable when CT101 is offline.

Migration notes:

- Move id, user_id, mode, title, model, created_at, updated_at, deleted_at.
- Keep mode values such as chat and companion.
- Normal chat and companion chat can share the same table.

Risk:

- Current CT101 direct frontend and wrapper routing may both touch chat state during migration.

### messages

Future owner: laptop/controller.

Reason: chat history should persist on the laptop and not require CT101 to be online.

Migration notes:

- Move chat_id, role, content, risk_level, created_at.
- Preserve ordering.
- Ensure queued worker results create assistant messages on laptop.

Risk:

- Duplicate assistant messages if worker completion is not idempotent.

### companion_study_sessions

Future owner: laptop/controller.

Reason: active companion study state is part of the user experience.

Migration notes:

- Move user_id, chat_id, deck_id, current_card_id, last_job_id, awaiting_answer, awaiting_confirmation.
- May be acceptable to reset active sessions during cutover if documented.

Risk:

- Active study flow can become inconsistent if card ids change.

### study_decks

Future owner: laptop/controller.

Reason: decks are durable user study data.

Migration notes:

- Move id, user_id, title, description, created_at, updated_at.
- Preserve integer ids if possible, or migrate cards/reviews with remapped ids.

Risk:

- Foreign-key remapping can break cards/reviews if not planned.

### study_cards

Future owner: laptop/controller.

Reason: cards are durable user study data.

Migration notes:

- Move id, deck_id, user_id, question, answer, explanation, tags, created_at, updated_at.
- Preserve relationship to decks.

Risk:

- Card stats and review queues depend on review history.

### study_reviews

Future owner: laptop/controller.

Reason: review history drives difficulty and deck stats.

Migration notes:

- Move id, card_id, deck_id, user_id, correct, user_answer, created_at.
- Preserve review counts exactly.

Risk:

- Difficulty ratings change if any review rows are lost.

### calendar_events

Future owner: laptop/controller.

Reason: calendar should be visible and editable even when CT101 is offline.

Migration notes:

- Move id, user_id, title, description, location, start_at, end_at, all_day, source, created_at, updated_at.
- Preserve timezone-aware timestamps.

Risk:

- Calendar date/time handling must stay consistent.

### jobs

Future owner: laptop/controller.

Reason: users should be able to queue work while CT101 is offline.

Migration notes:

- Merge or replace controller SQLite jobs with a durable laptop-owned queue table.
- Preserve job_type, status, requested_model, assigned_worker_id, payload_json, result_json, error_text, created_at, updated_at, started_at, finished_at.
- Add future fields later for priority, retries, lease timeout, idempotency, and cancellation.

Risk:

- Job duplication if CT101 and laptop both own active queues.

### workers

Future owner: laptop/controller for durable registry/status summary.

Reason: controller needs to know whether workers are available and when to wake/stop systems.

Migration notes:

- Move or mirror worker id, name, status, capabilities_json, current_job_id, worker_node_id, last_heartbeat_at, idle_shutdown_seconds, created_at, updated_at.
- CT101 worker runtime may still keep local process state.

Risk:

- Worker status can become stale unless heartbeat ownership is clear.

### worker_nodes

Future owner: laptop/controller.

Reason: node configuration belongs with power/status orchestration.

Migration notes:

- Move name, node_type, host_machine, tailscale_ip, lan_ip, compose_path, start_command, stop_command, wake_method, wake_target, enabled, status, capabilities, notes, last_seen_at.
- Align with existing controller worker registry and power automation.

Risk:

- Sensitive start/stop commands and wake targets must be handled carefully.

### worker_events

Future owner: laptop/controller.

Reason: useful for observability and debugging.

Migration notes:

- Controller already has worker_events in SQLite.
- Future Postgres app DB should have worker event/audit history.

Risk:

- Can grow large; retention policy needed.

### power_idle_state, power_events, power_auto_state

Future owner: laptop/controller.

Reason: these are already controller/power orchestration state.

Migration notes:

- Keep laptop-owned.
- Eventually move from SQLite to laptop Postgres if the controller database is consolidated.

Risk:

- Power automation must remain guarded during database migration.

## Keep CT101 runtime-only

The following should not become laptop-owned app data:

- Ollama model files
- GPU/CPU runtime process state
- temporary model scratch files
- transient worker logs
- local caches
- container runtime state

## Recommended migration phases

### Stage 5D

Add laptop database foundation and backup plan.

No CT101 data migration yet.

### Stage 5E

Create laptop-owned job queue facade.

CT101 workers should eventually claim from laptop/controller.

### Stage 5F

Move chat/chats/messages first.

Reason: queued chat already has good smoke coverage.

### Stage 5G

Move study data after chat.

Reason: study has more related tables and stats logic.

### Stage 5H

Move calendar/profile data.

### Stage 5I

Move worker registry and node config into laptop source of truth.

### Stage 5J

Make CT101 API worker/model-only.

## Cutover rules

During migration:

- only one system may be source of truth for a table
- do not run dual writes without idempotency
- do not delete CT101 data until backup and restore are tested
- preserve user ids and foreign keys when possible
- add read-only comparison smokes before write migration
- add rollback instructions before each table migration

## Stage 5C constraints

Do not:

- migrate production data
- change schemas
- restart services
- deploy
- change auth behavior
- change worker behavior
- change power automation
- remove CT101 frontend
