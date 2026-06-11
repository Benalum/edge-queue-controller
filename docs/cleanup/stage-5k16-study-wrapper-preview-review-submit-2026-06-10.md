# Stage 5K-16 Study Wrapper Preview Review Submit — 2026-06-10

## Result

Enabled Correct/Wrong review submit actions on /study-wrapper-preview.

The wrapper preview now POSTs to /api/study/cards/{card_id}/reviews with:

- was_correct
- confidence

## Smoke result

Submitted one review against the wrapper-created test deck.

Deck 11 review count increased from 0 to 1.

## Safety boundary

Review submit is now wired in preview.

Delete actions remain disabled/unwired.

Live /study remains unchanged.
