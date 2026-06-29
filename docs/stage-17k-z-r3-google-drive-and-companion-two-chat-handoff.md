# Stage 17K-Z-R3 — Google Drive and Companion Two-Chat Handoff

Date: 2026-06-29

## Current chat title

AI Platform Control — Stage 17K Study/Profile Cleanup + Companion Study Workflow Handoff

## Summary

Stage 17K-Z-R3 records the current clean source checkpoint and splits the next work into two focused chats.

Chat 1 should focus on the Google Drive sync contract plan.

Chat 2 should focus on Companion source adapters and workflow implementation after the Google Drive sync contract is defined.

## Current cleaned product state

- Study no longer shows Anki UI.
- Companion no longer shows Anki debug or local-card panels.
- Profile has a minimal Anki panel with file-location help, Choose File, deck count, total card count, and per-deck card counts.
- The global banner now says Anki decks can be read locally, Companion study integration is in progress, and Google sync is planned but not enabled.
- Companion is planned as a study orchestrator only.
- Study owns create, edit, delete, import, export, and deck/card management.
- Profile owns source connection and source inventory visibility.

## Latest known checkpoint before this handoff

- Commit: 028e3e4
- Tag: controller-stage-17k-z-r2-companion-study-source-workflow-plan-2026-06-29

## Important product decisions

Companion should not create, edit, delete, import, export, or remove decks/cards.

Companion may read source-agnostic deck inventory and guide study sessions.

All deck/card mutation stays in the Study tab.

Profile handles source selection and source inventory.

Google Drive sync should get a data contract before final Companion end-session stat writeback is implemented.

## Next chat 1 title

AI Platform Control — Google Drive Sync Contract Plan

## Next chat 1 prompt

Continue AI Platform Control from Stage 17K-Z-R3. We need a Google Drive sync contract plan before final Companion stat writeback.

Current state:

- Study page is clean and no longer shows Anki UI.
- Companion page is clean and no longer shows Anki debug/local-card panels.
- Profile has a minimal Anki panel that reads deck/card counts locally in the browser.
- Global banner says Anki decks can be read locally, Companion study integration is in progress, and Google sync for personal data is planned but not yet enabled.
- Latest known commit before this handoff: 028e3e4.
- Latest known tag before this handoff: controller-stage-17k-z-r2-companion-study-source-workflow-plan-2026-06-29.

Goal for this chat:

Create a Google Drive sync contract plan for user-owned personal data.

Scope:

- Define what data belongs in Google Drive.
- Define folder/file layout.
- Define deck, card, session, stats, and study history schemas.
- Define sync direction and conflict rules.
- Define privacy and consent boundaries.
- Define OAuth/scopes direction.
- Define offline/local-first behavior.
- Define how end-session stats will later be queued or written to Google Drive.
- Keep this planning-only first with docs and smoke.

Safety:

- No backend deploy.
- No frontend deploy.
- No DB writes.
- No Google OAuth activation.
- No Drive writes.
- No model calls.
- No worker or scheduler activation.
- No service restarts.

Style preference:

Use Python line-list writers for generated docs and smokes. Avoid nested Markdown code fences and embedded JSON blocks in generated docs because those broke earlier copy/paste commands.

## Next chat 2 title

AI Platform Control — Companion Source Adapters and Study Workflow

## Next chat 2 prompt

Continue AI Platform Control after the Google Drive sync contract plan. We need to implement Companion source adapters and the Companion study workflow.

Current product direction:

- Study owns create, edit, delete, import, export, and deck/card management.
- Profile owns source connection and source inventory display.
- Companion is read-only over deck sources and only orchestrates study sessions.
- Companion should not create, edit, delete, import, export, or remove decks/cards.
- Companion should see all studyable decks through one source-agnostic inventory interface.

Source types to support or plan for:

- apc_local
- anki_local_browser
- google_drive_synced
- future_external_source

Study session requirements:

- User selects one or more decks.
- User selects a study style.
- Initial study styles are all cards, easy cards, medium cards, hard cards, new cards, and balanced.

Session state machine:

- Idle allows start study.
- Running allows pause study and stop study.
- Paused allows resume study and stop study.
- Resumed is operationally the same as running.
- Ended calculates session/card/deck stats and prepares sync when enabled.

Running or resumed card commands:

- repeat question
- flag card
- skip card
- tell me the answer
- answer the question
- pause study session
- end study session

Implementation direction:

- Build small source-safe adapters first.
- Keep Companion UI clean and do not restore old debug panels.
- Prefer a workflow-style function named runCompanionStudyWorkflow.
- Keep card mutation commands out of Companion.
- Use the Google Drive sync contract for future stat persistence.

Safety:

- Start with source/docs/smoke or small frontend-only changes unless explicitly approved.
- No backend deploy, DB write, Google Drive write, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation without explicit approval.

Style preference:

Use Python line-list writers for generated docs and smokes. Avoid nested Markdown code fences and embedded JSON blocks in generated docs because those broke earlier copy/paste commands.

## Recommended order

1. Open the Google Drive sync contract plan chat first.
2. Define the storage and sync data contract.
3. Return to the Companion source adapters and workflow implementation chat.
4. Implement source inventory adapters.
5. Implement Companion session state machine.
6. Implement stat writeback only after the sync contract is stable.

## Safety

This stage is docs and smoke only.

No source runtime patch, frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
