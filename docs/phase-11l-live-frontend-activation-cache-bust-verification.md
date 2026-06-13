# Phase 11L Live Frontend Activation / Cache-Bust Verification

Phase 11L verifies that the Phase 11K deterministic answer normalizer is being served by the live frontend.

## Goal

Confirm the deployed frontend serves the Phase 11K marker from the active `app.js` file.

Phase 11K marker:

- `STAGE_5P11K_DETERMINISTIC_NUMBER_WORD_NORMALIZER_BEGIN`

## Findings

The local repo contains the Phase 11K marker in:

- `frontend/wrapper-ui/app.js`

The local static server serves the marker from:

- `http://127.0.0.1:8787/app.js`

The public site serves the marker from:

- `https://alexhartel.com/app.js`

The public root page currently references:

- `/app.js?v=2026061208l`

Phase 11L smoke verifies both the plain app URL and the exact query URL referenced by the page.

## Runtime changes

None.

This phase only documents and smokes live frontend activation.

## Router rollout status

Router rollout remains parked:

- no backend dry-run env
- no frontend router POST traffic
- no persistent rollout mutation routes
- no rollout mutation routes
