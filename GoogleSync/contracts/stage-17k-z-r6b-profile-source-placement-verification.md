# Stage 17K-Z-R6B Profile GoogleSync Source Placement Verification

Status: verification only
Date: 2026-06-29
Baseline commit before this stage: 70da675

## Purpose

Verify whether the Stage 17K-Z-R6 Profile-only GoogleSync login UI shell was placed in an acceptable source file before any deploy, OAuth activation, or Drive access.

This stage does not move source code. It records evidence and recommends the next source-only cleanup step.

## SAFETY_NON_ACTIVATION

- No backend deploy.
- No frontend deploy.
- No database writes.
- No Google OAuth activation.
- No Drive reads.
- No Drive writes.
- No model calls.
- No worker activation.
- No scheduler activation.
- No service restarts.
- No source relocation in this stage.

## VERIFIED_SOURCE

- Selected source: frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js
- Placement class: profile_adjacent_anki_panel_source
- Recommendation: acceptable_temporarily_then_split_before_oauth
- Reason: The selected source is Profile-adjacent because the current Profile local Anki panel lives there, but GoogleSync should be split into a clearer Profile GoogleSync module before real OAuth activation.

## VERIFIED_RUNTIME_GUARDS

- The GoogleSync marker is present only in the selected source.
- The UI block includes the Profile runtime guard.
- The UI block includes Profile-only data attributes.
- The UI block marks OAuth inactive.
- The UI block marks Drive reads false.
- The UI block marks Drive writes false.
- The Connect Google Drive control remains disabled.
- The Sync now control remains disabled.

## SOURCE_PLACEMENT_DECISION

The current placement is acceptable for a source-only UI shell when the selected source is Profile-adjacent and guarded by runtime Profile checks.

Before real OAuth activation, the safer long-term structure is to split GoogleSync UI code into a clearer Profile-specific module, such as a Profile GoogleSync panel source file, then load or invoke it from the Profile route only.

## PROFILE_ONLY_RULE

- Study must not render GoogleSync login controls.
- Companion must not render GoogleSync login controls.
- Admin must not render GoogleSync login controls.
- Global banner must not render GoogleSync login controls.
- Global navigation must not render GoogleSync login controls.

## ACCEPTANCE_CRITERIA_FOR_THIS_STAGE

- R6 selected source path file exists.
- R6 selected source exists.
- R6 marker is present.
- R6 block delimiters are present.
- R6 marker appears only in the selected source.
- R6 block has no network, navigation, OAuth, or Drive API activation text.
- Existing GoogleSync validators pass.
- Changed files are limited to GoogleSync contracts and the focused smoke.

## NEXT_RECOMMENDED_STAGE

Recommended next stage:

- Stage 17K-Z-R6C split Profile GoogleSync UI shell into a cleaner Profile-specific module, no OAuth activation, no Drive reads, no Drive writes.
