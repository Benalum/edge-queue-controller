# Phase 13L Disabled Study Card Flagging Contract

Phase 13L adds a disabled backend contract for future Study card flagging.

## Goal

Users need a way to flag cards that have wrong answers, confusing wording, bad images, duplicates, missing explanations, typos, or bad difficulty.

This phase does not create a table, enable routes, write to the database, call models, enqueue jobs, or change card state.

## Added helper

- _stage5p13l_disabled_study_card_flagging_contract

The helper is source-only, disabled, and unwired.

## Future routes

- POST /api/study/cards/{card_id}/flag
- POST /api/study/cards/{card_id}/unflag
- GET /api/study/card-flags

Public route aliases may mirror the same API paths later if needed.

## Future table

- study_card_flags

The table should support soft unflagging instead of destructive deletes.

## Allowed reasons

- wrong_answer
- confusing_wording
- bad_image
- duplicate
- needs_explanation
- typo
- too_easy
- too_hard
- other

Unknown reasons should normalize to other.

## Required ownership checks

- card_owner_required
- deck_owner_required

A user must not be able to flag, unflag, or list another user’s cards.

## Future UI behavior

- show_flag_button_on_card
- show_flag_reason_picker
- allow_optional_note
- show_flagged_state_on_review_card
- do_not_interrupt_study_session

Flagging should not interrupt the active Study session.

## Future response contracts

Flag response fields should include ok, card_id, flagged, reason, and flagged_at.

Unflag response fields should include ok, card_id, flagged, and unflagged_at.

List response fields should include ok, count, and flags.

Flag list entries should include card preview and deck title when safe.

## Activation gates

- requires_schema_migration_or_table_create
- requires_card_owner_validation
- requires_flag_route_smoke
- requires_unflag_route_smoke
- requires_flag_list_route_smoke
- requires_ui_button_smoke
- requires_live_smoke_before_enable

## Disabled safety contract

- no model call
- no queue write
- no database write
- no card state change
- no tool call
- no Ollama direct call
- no live Study route integration
- no Companion live flow integration
