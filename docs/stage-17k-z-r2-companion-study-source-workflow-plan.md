# Stage 17K-Z-R2 — Companion Study Source Workflow Plan

Date: 2026-06-29

## Summary

Stage 17K-Z-R2 defines the clean Companion study architecture before adding Companion-Anki or Companion-local-card functionality back into the UI.

The direction is to separate deck/card management from guided study.

- Study owns deck/card creation, editing, deletion, import, export, and source management.
- Profile owns user/source connection and inventory visibility, such as local Anki deck counts.
- Companion owns study orchestration only.

## Product decision

Companion should not create, edit, delete, import, export, or remove decks/cards.

Companion may read deck inventory and guide study sessions.

This keeps Companion simple, safer, and easier to extend to future sources such as Anki, local APC decks, Google Drive synced decks, or another supported platform.

## Source-agnostic deck model

Companion should see all supported decks through one source-agnostic inventory interface.

Initial source types:

- apc_local
- anki_local_browser
- google_drive_synced
- future_external_source

Normalized deck fields for Companion:

- source_type
- source_id
- deck_id
- deck_name
- card_count
- stats_available
- study_supported
- write_supported

Companion should not care whether the deck came from Anki, APC local cards, Google Drive, or a future integration. It should only care whether the deck can be studied.

## Study ownership boundaries

### Study tab owns

- Create deck
- Edit deck
- Delete deck
- Create card
- Edit card
- Delete card
- Import cards
- Export cards
- Manage local cards
- Manage future synced cards
- Show detailed deck/card stats
- Resolve source conflicts

### Profile tab owns

- Connect or select a source
- Choose local Anki file
- Show source status
- Show deck count
- Show card count per deck
- Show sync/account connection state later

### Companion tab owns

- List studyable decks
- Ask user to choose deck or decks
- Ask user to choose study style
- Start study session
- Pause study session
- Resume study session
- Stop/end study session
- Present questions
- Repeat questions
- Compare user answers
- Reveal/tell answer
- Flag cards
- Skip cards
- Summarize session results

## Required session inputs

A study session requires:

1. One or more selected decks.
2. A study style.

Initial study styles:

- all cards
- easy cards
- medium cards
- hard cards
- new cards
- balanced

Current local card data only supports limited stats. More complete stats can be added after Google Drive sync supports durable user-owned study history.

## Session state machine

Companion study sessions should use a simple explicit state machine.

### Idle / no active session

Allowed command:

- start study

### Running / started session

Allowed session commands:

- pause study
- stop study

Allowed card-study commands:

- repeat question
- flag card
- skip card
- tell me the answer
- answer the question
- pause study session
- end study session

### Paused session

Allowed commands:

- resume study
- stop study

### Resumed session

A resumed session is the same operational state as running.

Allowed session commands:

- pause study
- stop study

Allowed card-study commands:

- repeat question
- flag card
- skip card
- tell me the answer
- answer the question
- pause study session
- end study session

### Ended session

When a user ends a study session:

- calculate card results
- calculate deck/session stats
- update local stats if available
- queue or prepare Google Drive sync when enabled
- show the user a session summary

## Companion workflow function

Companion should call a workflow-style function instead of scattered deck/card commands.

Conceptual function name:

- runCompanionStudyWorkflow

Recommended workflow inputs:

- command
- currentSessionState
- selectedDecks
- studyStyle
- userAnswer
- sourceRegistry
- statsStore
- syncAdapter

Recommended workflow outputs:

- ok
- next_state
- assistant_message
- visible_card_prompt
- allowed_commands
- stats_delta
- sync_required

This makes future changes easier because the Companion UI can stay simple while the workflow function controls the study logic.

## Google Drive sync sequencing decision

Google Drive sync does not need to be fully working before defining Companion study workflow.

Recommended order:

1. Define source registry, deck inventory model, and session state machine.
2. Implement browser-local prototype using APC local cards and Anki local inventory.
3. Define Google Drive sync data contract for decks, cards, session stats, and user study history.
4. Add Google Drive sync writeback for ended sessions.
5. Expand stats-based study styles once durable stats are available.

Before implementing final end-session stat persistence, the Google Drive sync contract should be defined so the data model does not need to be rewritten later.

## Near-term implementation recommendation

Next implementation should be small and source-safe:

1. Add a source-agnostic deck inventory adapter.
2. Expose APC local decks and Anki local deck inventory through the same normalized shape.
3. Keep Companion read-only.
4. Add Companion session planner that requires selected deck/decks and study style.
5. Add state machine only.
6. Do not add card mutation commands to Companion.

## Safety

This stage is planning only.

No source patch, frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
