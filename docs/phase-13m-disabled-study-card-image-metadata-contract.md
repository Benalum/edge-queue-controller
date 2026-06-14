# Phase 13M Disabled Study Card Image Metadata Contract

Phase 13M adds a disabled backend contract for future Study card image metadata.

## Goal

Study cards need optional image support so a card can show a picture, diagram, chart, or visual prompt during review.

This phase does not create tables, add columns, enable routes, upload files, write storage, write to the database, call models, enqueue jobs, or change card state.

## Added helper

- _stage5p13m_disabled_study_card_image_metadata_contract

The helper is source-only, disabled, and unwired.

## Future table or column options

- study_card_images
- image_metadata_json

The first live release should prefer metadata-only support before raw file upload.

## Future routes

- POST /api/study/cards/{card_id}/image
- POST /api/study/cards/{card_id}/image/remove
- GET /api/study/cards/{card_id}/images

Public route aliases may mirror the same API paths later if needed.

## Required ownership checks

- card_owner_required
- deck_owner_required

A user must not be able to add, remove, view, or list private image metadata for another user’s cards.

## Allowed metadata

- image_url
- image_alt_text
- image_mime_type
- image_source

Allowed MIME types for the initial contract are image/jpeg, image/png, image/webp, and image/gif.

## Public card payload behavior

- include_image_metadata_on_card
- include_image_metadata_on_current_session_card
- include_image_metadata_on_review_queue_card
- do_not_expose_private_storage_paths
- hide_raw_upload_storage_details

Private filesystem paths and raw storage details must not be exposed to the browser.

## Future UI behavior

- show_image_on_review_card
- show_image_on_answer_reveal
- allow_add_image_from_card_editor
- allow_remove_image_from_card_editor
- image_is_display_only_for_first_release
- multimodal_grading_later

The first release should display images only. Multimodal grading comes later.

## Activation gates

- requires_schema_migration_or_table_create
- requires_card_owner_validation
- requires_storage_policy_decision
- requires_image_url_validation
- requires_public_payload_update_smoke
- requires_current_session_payload_update_smoke
- requires_ui_render_smoke
- requires_live_smoke_before_enable

## Disabled safety contract

- no model call
- no queue write
- no database write
- no schema migration
- no storage write
- no file upload
- no card state change
- no tool call
- no Ollama direct call
- no live Study route integration
- no Companion live flow integration
