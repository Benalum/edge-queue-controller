# Phase 13N Disabled Study Review UI Support Contract

Phase 13N adds a disabled backend contract for future Study review UI support.

## Goal

Study review needs a better card experience that can later show flag controls, image blocks, answer reveal state, progress metadata, and Companion feedback without breaking the current review flow.

This phase does not edit frontend files, enable routes, write to the database, call models, enqueue jobs, upload files, write storage, or change card state.

## Added helper

- _stage5p13n_disabled_study_review_ui_support_contract

The helper is source-only, disabled, and unwired.

## Current UI surfaces

- frontend/study-ui/app.js
- frontend/study-ui/index.html
- frontend/study-ui/styles.css
- frontend/wrapper-ui/app.js
- frontend/wrapper-ui/styles.css

Current live Study review rendering is centered around renderReviewCard.

Companion study card prompting is centered around companionAskCurrentCard.

## Current actions

- show_answer
- wrong
- correct
- skip

These actions must keep working before any new UI behavior becomes live.

## Future review card components

- review_card
- answer_reveal_panel
- correct_button
- wrong_button
- skip_button
- flag_button
- flag_reason_picker
- card_image_block
- card_progress_meta
- study_companion_feedback_area

## Future UI behavior

- show_question
- show_answer_after_reveal
- show_explanation_after_reveal
- show_difficulty_bucket
- show_review_count
- show_accuracy
- show_flag_button_on_card
- show_flag_reason_picker
- show_image_on_review_card
- show_image_on_answer_reveal
- image_display_only_first_release
- do_not_require_multimodal_model
- do_not_interrupt_study_session

The first release should display image metadata only. Multimodal grading comes later.

## Future API dependencies

- /api/study/decks/{deck_id}/review-queue
- /api/study/cards/{card_id}/reviews
- /api/study/cards/{card_id}/flag
- /api/study/cards/{card_id}/unflag
- /api/study/cards/{card_id}/image
- /api/study/session/status

Future backend payload fields should include id, question, answer, explanation, difficulty, tags, image_metadata, and flag_state.

## Activation gates

- requires_live_study_ui_file_patch
- requires_flag_endpoint_before_flag_button_live
- requires_image_payload_before_image_render_live
- requires_css_render_smoke
- requires_review_queue_render_smoke
- requires_answer_reveal_render_smoke
- requires_skip_correct_wrong_regression_smoke
- requires_no_login_redirect_regression
- requires_live_smoke_before_enable

## Disabled safety contract

- no frontend mutation
- no live Study UI connection
- no live Study route connection
- no Companion live flow connection
- no model call
- no queue write
- no database write
- no schema migration
- no storage write
- no file upload
- no card state change
- no tool call
- no Ollama direct call
