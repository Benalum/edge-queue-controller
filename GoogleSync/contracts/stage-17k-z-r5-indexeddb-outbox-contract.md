# Stage 17K-Z-R5 GoogleSync IndexedDB Outbox Contract

Status: contract only
Date: 2026-06-29
Baseline commit before this stage: 45bc0a4

## Purpose

Define the browser-local GoogleSync IndexedDB outbox contract before any OAuth activation or Google Drive writes.

This stage creates source-side contract artifacts only. It does not implement frontend runtime behavior, does not deploy, does not activate OAuth, and does not write to Google Drive.

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

## GOOGLE_SYNC_FOLDER_BOUNDARY

- Google Drive sync planning and local validation artifacts live under the top-level GoogleSync folder.
- This stage adds a contract under GoogleSync/contracts.
- This stage adds a validator under GoogleSync/validators.
- This stage adds a local fixture under GoogleSync/fixtures/valid.
- The only file outside GoogleSync is the focused smoke under ops/smoke.

## LOCAL_FIRST_RULE

End-session study data must be saved locally before any future remote sync attempt.

Local-first means:

- Study completion does not wait for Google Drive.
- Companion study completion does not wait for Google Drive.
- The browser stores session, history, stats, and outbox entries in IndexedDB first.
- The UI can show Saved locally as soon as the local transaction succeeds.
- Future Drive sync can run later from pending outbox entries after consent is active.

## INDEXEDDB_DATABASE

Database name:

- apc_google_sync

Initial contract version:

- 1

Database ownership:

- Browser-local only.
- User-owned personal sync working copy.
- Not a backend database.
- Not a Google Drive database.

## INDEXEDDB_STORES

Required stores:

- google_sync_manifest_cache.
- google_sync_outbox.
- google_sync_history_pending.
- google_sync_sessions_pending.
- google_sync_stats_pending.
- google_sync_conflicts.
- google_sync_consent_audit.
- google_sync_device_state.

Store purposes:

- google_sync_manifest_cache stores the last known local view of the remote manifest after sync is later enabled.
- google_sync_outbox stores pending write intents.
- google_sync_history_pending stores local append-only history records not yet confirmed by future sync.
- google_sync_sessions_pending stores finalized local session records not yet confirmed by future sync.
- google_sync_stats_pending stores derived stats snapshots not yet confirmed by future sync.
- google_sync_conflicts stores preserved local and remote conflict summaries.
- google_sync_consent_audit stores local consent decision events.
- google_sync_device_state stores non-secret local device sync state.

## STORE_KEYS

- google_sync_manifest_cache key: manifest_id.
- google_sync_outbox key: outbox_entry_id.
- google_sync_history_pending key: event_id.
- google_sync_sessions_pending key: session_id.
- google_sync_stats_pending key: stats_key.
- google_sync_conflicts key: conflict_id.
- google_sync_consent_audit key: consent_event_id.
- google_sync_device_state key: device_id.

## OUTBOX_ENTRY_CONTRACT

Outbox entry required fields:

- outbox_entry_id.
- created_at.
- updated_at.
- operation.
- target_path.
- record_type.
- record_id.
- payload_hash.
- payload_local_ref.
- status.
- attempt_count.
- last_attempt_at.
- last_error.
- created_from_event_id.
- requires_consent.
- requires_network.
- oauth_activated.
- drive_write_performed.

Allowed operations:

- write_session.
- append_history.
- write_user_stats.
- write_deck_stats.
- update_manifest.
- write_conflict.
- write_consent_event.

Allowed statuses:

- pending.
- paused_for_consent.
- paused_offline.
- syncing.
- synced.
- failed_retryable.
- failed_needs_user.

R5 status rule:

- In this stage, new entries may be pending or paused_for_consent in contract examples only.
- No runtime code creates entries in this stage.
- No runtime code syncs entries in this stage.

## END_SESSION_LOCAL_TRANSACTION

Future end-session local transaction order:

- Begin IndexedDB transaction.
- Finalize session record in google_sync_sessions_pending.
- Append session_ended history event in google_sync_history_pending.
- Append any missing card_answered events in google_sync_history_pending.
- Recompute user stats and store in google_sync_stats_pending.
- Recompute deck stats and store in google_sync_stats_pending when deck_id exists.
- Create write_session outbox entry.
- Create append_history outbox entry.
- Create write_user_stats outbox entry.
- Create write_deck_stats outbox entry when deck_id exists.
- Create update_manifest outbox entry.
- Commit IndexedDB transaction.
- Mark UI as Saved locally.

Failure rule:

- If the IndexedDB transaction fails, the UI must not claim local save success.
- If only future remote sync fails, the UI may still claim local save success.

## CONSENT_GATE

- Outbox creation is allowed before Drive sync is connected.
- Outbox execution is not allowed until the user has connected Drive and consent is active.
- Any entry requiring Drive sync must have requires_consent set to true.
- Consent events are stored locally before future sync execution.
- OAuth tokens are never stored in outbox entries.

## NETWORK_GATE

- Outbox execution requires online browser state.
- R5 does not implement network detection.
- Future implementation may mark entries paused_offline when the browser is offline.
- Local save remains available while offline.

## PRIVACY_BOUNDARY

- Browser-local Anki data remains local-only by default.
- Anki local sessions may create aggregate session and stats records without uploading raw Anki cards.
- Raw Anki package files are not stored in GoogleSync outbox entries.
- Personal card content must not be written into backend queue rows for GoogleSync.
- OAuth tokens must not be stored in IndexedDB outbox records.

## REPLAY_RULES

- Outbox replay is idempotent by outbox_entry_id and payload_hash.
- Synced entries are not replayed unless explicitly reset by a future recovery flow.
- Failed retryable entries keep attempt_count and last_error.
- User-action failures become failed_needs_user.
- Conflict detection creates a conflict record and does not delete the local pending record silently.

## STATS_WRITEBACK_BOUNDARY

Final Companion stat writeback should later use this order:

- Save session locally.
- Save history locally.
- Recompute stats locally.
- Queue GoogleSync outbox entries locally.
- Show Saved locally.
- Sync later only after Drive consent and availability.

The backend durable job queue is not part of this personal Drive writeback contract.

## ACCEPTANCE_CRITERIA_FOR_THIS_STAGE

- GoogleSync/contracts/stage-17k-z-r5-indexeddb-outbox-contract.md exists.
- GoogleSync/contracts/indexeddb-outbox-contract.apc.json exists.
- GoogleSync/validators/validate_indexeddb_outbox_contract.py exists and passes.
- Focused smoke exists and passes.
- Existing GoogleSync schema validator still passes.
- Changed files are limited to GoogleSync and the focused smoke.
- No OAuth activation text appears as executable code.
- No Drive API call text appears as executable code.
- No backend files are changed.
- No frontend files are changed.
- No database writes happen.
- No Drive writes happen.

## NEXT_RECOMMENDED_STAGE

Recommended next stage:

- Stage 17K-Z-R6 disabled GoogleSync consent UI contract, no OAuth, no Drive writes.
