# Stage 17K-Z-R3 Google Drive Sync Contract Plan

Status: planning only
Date: 2026-06-29
Baseline commit before this stage: ac54c87
Baseline tag before this stage: controller-stage-17k-z-r2-companion-study-source-workflow-plan-2026-06-29

## Purpose

Define the Google Drive sync contract for user-owned personal study data before final Companion stat writeback.

This stage is source-only planning. It does not activate OAuth, Drive sync, backend writes, frontend deployment, workers, schedulers, or model calls.

## SAFETY_NON_ACTIVATION

- No backend deploy.
- No frontend deploy.
- No database writes.
- No Google OAuth activation.
- No Google Drive writes.
- No model calls.
- No worker activation.
- No scheduler activation.
- No service restarts.
- No runtime feature flag changes.

## Current Product Boundary

- Study page is clean and does not show Anki UI.
- Companion page is clean and does not show Anki debug or local-card panels.
- Profile has a minimal Anki panel that reads deck and card counts locally in the browser.
- Global banner says Anki decks can be read locally, Companion study integration is in progress, and Google sync for personal data is planned but not yet enabled.

## DATA_IN_DRIVE

Google Drive is for user-owned personal study data created in AI Platform Control or explicitly imported into APC-native data.

Belongs in Google Drive after consent:

- APC-native decks.
- APC-native cards.
- Deck metadata.
- Study sessions.
- Study history events.
- User stats.
- Deck stats.
- Companion study session summaries.
- User study preferences intended to follow the user across devices.
- Sync manifests.
- Conflict records.
- Consent audit records.
- User-requested exports.

Does not belong in Google Drive by default:

- Raw Anki deck packages.
- Raw Anki collection databases.
- Browser-local Anki deck contents unless explicitly imported into APC-native data.
- Server logs.
- Backend queue rows.
- OAuth tokens.
- Secrets.
- Private server configuration.
- Model prompts or completions unless the user explicitly saves a study artifact.

Anki boundary:

- Browser-local Anki reading remains local-only by default.
- APC must not mutate Anki decks or cards.
- APC must not upload raw Anki files automatically.
- A future Anki import can convert selected content into APC-native decks only after explicit user consent.

## DRIVE_STORAGE_MODEL

Primary personal study data should live in a visible user-owned Google Drive folder.

Use a visible folder because users should be able to inspect, export, copy, move, and delete their own data.

Optional appDataFolder use is limited to opaque app sync state, such as a sync cursor or non-secret device registry, and requires separate consent copy.

Storage split:

- Visible Drive folder: decks, cards, sessions, history, stats, manifests, conflict records, and consent audit records.
- Optional appDataFolder later: sync cursor and non-secret app metadata.
- Browser IndexedDB: local-first working copy and offline outbox.
- Backend database: not used for personal Drive document contents in this contract.

## FOLDER_LAYOUT

Default visible folder:

- AI Platform Control

Folder and file layout:

- AI Platform Control/manifest.apc.json
- AI Platform Control/profile/profile.apc.json
- AI Platform Control/study/decks/index.apc.json
- AI Platform Control/study/decks/by-id/DECK_ID/deck.apc.json
- AI Platform Control/study/decks/by-id/DECK_ID/cards.apc.jsonl
- AI Platform Control/study/decks/by-id/DECK_ID/media/MEDIA_ID
- AI Platform Control/study/sessions/YYYY/MM/SESSION_ID.apc.json
- AI Platform Control/study/history/YYYY/MM/YYYY-MM-DD.apc.jsonl
- AI Platform Control/study/stats/user-current.apc.json
- AI Platform Control/study/stats/decks/DECK_ID.apc.json
- AI Platform Control/sync/sync-state.apc.json
- AI Platform Control/sync/conflicts/YYYY/MM/CONFLICT_ID.apc.json
- AI Platform Control/audit/consent-log.apc.jsonl

Naming rules:

- Use stable IDs in paths.
- Keep user-edited names inside metadata fields.
- Use apc.json for JSON documents.
- Use apc.jsonl for append-friendly event streams.
- Do not use email addresses in file names.
- Do not use raw prompt text in file names.

## COMMON_SCHEMA_RULES

Every APC Drive record should include:

- schema_version.
- record_type.
- record_id.
- owner_subject_hash when signed in.
- created_at.
- updated_at.
- deleted_at.
- device_id.
- revision.
- source.
- content_hash.
- previous_hash when available.
- app_version or source revision.

Schema rules:

- This document uses field lists, not embedded JSON examples.
- Future machine-readable schemas can be added in a separate stage.
- Schema changes should be additive when possible.
- Destructive schema changes require migration docs and smoke.

## SCHEMA_DECK

Deck path:

- study/decks/by-id/DECK_ID/deck.apc.json.

Deck fields:

- record_type: deck.
- deck_id.
- title.
- description.
- tags.
- source_type.
- source_ref.
- card_count_declared.
- card_count_verified_at.
- default_study_mode.
- default_daily_target.
- created_at.
- updated_at.
- deleted_at.

Deck rules:

- Deck title changes do not change deck_id.
- Deleted decks become tombstones first.
- Hard delete from Drive requires a later explicit user action.

## SCHEMA_CARD

Card path:

- study/decks/by-id/DECK_ID/cards.apc.jsonl.

Card fields:

- record_type: card.
- card_id.
- deck_id.
- card_type.
- prompt_text.
- answer_text.
- hint_text.
- extra_text.
- tags.
- media_refs.
- difficulty_label.
- due_at.
- interval_days.
- ease_factor.
- suspended.
- source_type.
- created_at.
- updated_at.
- deleted_at.

Card rules:

- Card content is personal data.
- Card content is not sent to the backend by this Drive sync contract.
- Card content is not written to Drive without user opt-in.
- Card edits use tombstones and revision checks to avoid silent data loss.

## SCHEMA_SESSION

Session path:

- study/sessions/YYYY/MM/SESSION_ID.apc.json.

Session fields:

- record_type: study_session.
- session_id.
- user_id_hash.
- deck_id.
- study_source_type.
- companion_enabled.
- started_at.
- ended_at.
- duration_ms.
- cards_seen.
- cards_answered.
- cards_correct.
- cards_wrong.
- cards_skipped.
- answer_events_ref.
- local_only_source_refs.
- stats_delta_hash.

Session rules:

- Sessions can reference an Anki browser-local source without uploading raw Anki content.
- Anki browser-local sessions store aggregate counts and redacted source labels only unless the user explicitly imports cards into APC-native data.
- Finalized sessions are immutable except for sync metadata.

## SCHEMA_STATS

User stats path:

- study/stats/user-current.apc.json.

User stats fields:

- record_type: user_stats.
- stats_id.
- lifetime_sessions.
- lifetime_cards_seen.
- lifetime_cards_answered.
- lifetime_cards_correct.
- lifetime_cards_wrong.
- total_study_ms.
- current_streak_days.
- longest_streak_days.
- last_session_at.
- by_source_type.
- based_on_history_hash.
- recomputed_at.

Deck stats path:

- study/stats/decks/DECK_ID.apc.json.

Deck stats fields:

- record_type: deck_stats.
- deck_id.
- lifetime_sessions.
- lifetime_cards_seen.
- lifetime_cards_answered.
- lifetime_cards_correct.
- lifetime_cards_wrong.
- total_study_ms.
- due_count.
- mastered_count.
- learning_count.
- last_studied_at.
- based_on_history_hash.
- recomputed_at.

Stats rules:

- Stats are derived, not authoritative.
- History events are the source of truth.
- If stats conflict with history, recompute stats from history.

## SCHEMA_HISTORY

History path:

- study/history/YYYY/MM/YYYY-MM-DD.apc.jsonl.

History fields:

- record_type: study_history_event.
- event_id.
- event_type.
- happened_at.
- actor_type.
- deck_id.
- card_id.
- session_id.
- result.
- duration_ms.
- source_type.
- payload_ref.
- payload_hash.

History rules:

- History is append-only.
- Duplicate event IDs are ignored during merge.
- Duplicate event IDs with different content_hash values create conflicts.
- Anki browser-local history must not include raw card content unless explicitly imported into APC-native data.

## SYNC_DIRECTION

Sync is local-first.

Primary flow:

- User studies locally in the browser.
- Browser writes sessions and history to IndexedDB first.
- Browser places Drive write intents into a local outbox.
- If Drive is connected and online, sync pulls remote manifest before pushing.
- Sync merges remote changes into local IndexedDB.
- Sync writes local events and finalized sessions to Drive.
- Sync recomputes stats locally.
- Sync writes derived stats after history writes succeed.
- Sync updates manifest after data files are durable.

Direction rules:

- Pull before push.
- History before stats.
- Data files before manifest.
- Failed writes stay in the local outbox.
- Local study never blocks on Drive availability.

## CONFLICT_RULES

Priorities:

- Preserve user data.
- Prefer append-only merges.
- Never silently delete local or remote records.
- Preserve losing versions in conflict files.

Record rules:

- History merges by event_id.
- Sessions are immutable after finalization.
- Stats are resolved by recomputation.
- Deck title and description conflicts preserve both values.
- Card prompt, answer, hint, and media conflicts preserve both values.
- Deletes create tombstones first.
- Tombstone conflicts preserve the non-deleted copy until user review.

Conflict record fields:

- conflict_id.
- detected_at.
- record_type.
- record_id.
- local_hash.
- remote_hash.
- chosen_hash.
- local_summary.
- remote_summary.
- resolution_status.

## PRIVACY_CONSENT

Consent requirements:

- Google Drive sync is opt-in.
- Default state is disconnected.
- User must connect Google Drive before any Drive read or write.
- UI must explain what will be stored.
- UI must show the Drive folder name before first write.
- UI must distinguish local Anki reading from APC-native Drive sync.
- UI must allow disconnecting Drive sync.
- Disconnecting stops new sync attempts but does not delete local data.
- Remote deletion requires a separate explicit action.
- Local deletion requires a separate explicit action.

Privacy boundaries:

- Personal card content should not go to the APC backend as part of Drive sync.
- OAuth tokens must not be stored in Drive files.
- Card content must not be sent to model workers unless the user starts a study or Companion action that requires it.
- Platform aggregate metrics remain separate from personal Drive data.

## OAUTH_SCOPES

Planning direction:

- Prefer narrow Drive file access for user-visible APC files and folders.
- Use appdata access only if hidden app sync state is later required.
- Do not request broad Drive access.
- Do not request read access to all Drive files.
- Do not request Gmail or Calendar scopes for this feature.
- Do not activate OAuth in this stage.

Scope candidates for later implementation:

- https://www.googleapis.com/auth/drive.file
- https://www.googleapis.com/auth/drive.appdata

OAuth architecture direction:

- MVP should prefer browser-initiated Drive sync after user consent.
- IndexedDB remains the durable local queue.
- Access tokens are sensitive runtime credentials.
- Long-lived refresh token storage is not part of this planning stage.
- Server-assisted Drive sync requires a separate security design.

## OFFLINE_LOCAL_FIRST

Offline behavior:

- Study works without Google Drive.
- Companion study works without Google Drive after local source selection.
- End-session stats are written locally first.
- Drive outbox keeps pending writes until online and connected.
- UI shows pending sync status.
- UI shows last successful sync time.
- UI offers retry after failures.

Local storage direction:

- Use IndexedDB for decks, cards, sessions, stats, history, manifest cache, and outbox.
- Use localStorage only for small non-sensitive UI preferences.
- Do not store OAuth tokens in localStorage.
- Do not depend on backend DB for personal Drive sync recovery.

Failure behavior:

- If Drive write fails, keep the outbox entry.
- If auth expires, pause sync and ask the user to reconnect.
- If conflict is detected, preserve both copies.
- If stats write fails after history succeeds, recompute and retry stats later.

## END_SESSION_WRITEBACK

Future end-session local transaction:

- Finalize the session record in IndexedDB.
- Append session_ended history event locally.
- Append card_answered events locally if not already durable.
- Recompute user stats locally.
- Recompute deck stats locally when deck_id exists.
- Add Drive outbox entries for session, history, stats, and manifest update.
- Mark UI as saved locally.

Future Drive sync transaction:

- Run only when Drive sync is connected and consent is active.
- Pull manifest before pushing.
- Upload history changes.
- Upload finalized session file.
- Upload recomputed stats files.
- Update manifest after data files succeed.
- Mark outbox entries as synced only after Drive confirms writes.

Non-blocking rule:

- End-session UI must not wait for Google Drive.
- Show Saved locally immediately.
- Show Synced to Google Drive after sync succeeds.
- Show Pending Google Drive sync when queued.
- Show Local save complete, Google sync needs attention after sync failure.

Server boundary:

- Do not queue personal Drive writes in the backend for this contract.
- Do not write personal card or session content into the backend DB for Drive sync.
- Future server-assisted Drive writeback requires a separate approved stage.

## IMPLEMENTATION_PHASES

- Phase A: contract doc and smoke only.
- Phase B: local machine-readable schemas and validators only.
- Phase C: disabled or mock consent UI only.
- Phase D: browser-local IndexedDB outbox only.
- Phase E: dev-only OAuth setup docs only.
- Phase F: explicit-consent Drive sync MVP.

## ACCEPTANCE_CRITERIA_FOR_THIS_STAGE

- Planning doc exists.
- Focused smoke exists.
- Smoke verifies required contract markers.
- Smoke verifies the doc contains no Markdown code fences.
- Smoke verifies only narrow Drive scope URLs are present.
- Smoke verifies all safety non-activation lines are present.
- No backend files are changed.
- No frontend files are changed.
- No database writes happen.
- No OAuth or Drive calls happen.

## NEXT_RECOMMENDED_STAGE

Next recommended stage:

- Stage 17K-Z-R4 local Drive sync schema validators, no OAuth, no Drive writes.
