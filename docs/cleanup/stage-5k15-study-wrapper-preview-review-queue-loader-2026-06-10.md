# Stage 5K-15 Study Wrapper Preview Review Queue Loader — 2026-06-10

## Result

Enabled review queue loading on /study-wrapper-preview.

The wrapper preview now fetches /api/study/decks/{deck_id}/review-queue?mode={mode}&limit=10.

The preview can show a card, reveal the answer, and skip to the next card.

## Safety boundary

Correct/Wrong review submit actions remain disabled/unwired.

No study_reviews rows should be created by this stage.

Create deck and add card remain wired.

Live /study remains unchanged and fully interactive.
