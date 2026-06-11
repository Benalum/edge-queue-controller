# Stage 5O-22 Remove Study Extra Stylesheet Link — 2026-06-11

## Result

The wrapper now uses one shared stylesheet for Study and all other wrapper pages.

## Why

Study still looked visually different because the document retained a separate `/study/styles.css` link and Study-specific JS stylesheet toggles.

## Change

Removed:

- `studyPreviewStyles` link from `index.html`
- JS references that toggled `studyPreviewStyles`

Added:

- route-scoped Study logo/header normalization in the shared wrapper stylesheet

## Expected behavior

Study should use the same logo/header colors and page shell styling as Companion, Profile, Admin, System, and Credits.
