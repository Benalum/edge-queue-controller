# Phase 13O Disabled Immersive Study Mode UI Contract

Phase 13O adds a disabled backend contract for future immersive Study mode UI support.

## Goal

Immersive Study mode is a future focused review surface that hides distractions and shows only the current study task.

The intended future screen should show the latest Companion message, the current card question, the card image if present, an answer input, progress, and minimal controls.

This phase does not edit frontend files, enable routes, write to the database, call models, enqueue jobs, upload files, write storage, change voice runtime, or change card state.

## Added helper

- _stage5p13o_disabled_immersive_study_mode_ui_contract

The helper is source-only, disabled, and unwired.

## Current UI surfaces

- frontend/study-ui/app.js
- frontend/study-ui/index.html
- frontend/study-ui/styles.css
- frontend/wrapper-ui/app.js
- frontend/wrapper-ui/styles.css

Current live Study review rendering is centered around renderReviewCard.

Current Companion card prompting is centered around companionAskCurrentCard.

Future immersive rendering should be isolated behind renderImmersiveStudyMode.

## Future immersive layout

- hide_deck_dashboard_in_immersive_mode
- hide_card_stats_in_immersive_mode
- hide_extra_navigation_in_immersive_mode
- show_latest_companion_message_only
- show_current_card_question
- show_current_card_image_if_present
- show_answer_input
- show_minimal_controls
- show_progress_counter
- show_exit_immersive_button
- preserve_existing_review_flow
- do_not_interrupt_study_session

Immersive mode must not replace the normal Study page. It should be an optional focused surface.

## Future minimal controls

- answer_input
- submit_answer
- show_answer
- correct
- wrong
- skip
- exit_immersive

Exit immersive should keep the study session active.

## Future keyboard shortcuts

- enter_submit
- space_show_answer
- arrow_right_skip
- escape_exit

Keyboard shortcuts are later-only and must not be enabled by this phase.

## Future API dependencies

- /api/study/session/status
- /api/study/decks/{deck_id}/review-queue
- /api/study/cards/{card_id}/reviews
- /api/study/cards/{card_id}/flag
- /api/study/cards/{card_id}/image

Future job dependencies may include study_answer_judge and study_answer_reasoning_escalation.

## Voice boundary

Voice behavior belongs to a later phase.

- voice_settings_phase_later: phase_13p
- listen_button_later
- speak_current_card_later
- auto_tts_default_off
- auto_stt_default_off
- current_voice_change_enabled: false

Phase 13O must not enable STT, TTS, browser microphone behavior, or automatic speaking.

## Activation gates

- requires_live_study_ui_file_patch
- requires_css_focus_layout_smoke
- requires_review_queue_render_smoke
- requires_answer_input_focus_smoke
- requires_show_answer_regression_smoke
- requires_skip_correct_wrong_regression_smoke
- requires_exit_immersive_keeps_session_active_smoke
- requires_mobile_layout_smoke
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
- no voice runtime change
- no tool call
- no Ollama direct call
