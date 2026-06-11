# Stage 5K-13 Study Wrapper Preview Create Deck — 2026-06-10

## Result

Enabled create-deck action on /study-wrapper-preview.

The wrapper preview now POSTs to /api/study/decks with the existing Study payload shape:

- title
- description

After creating a deck, the preview reloads Study progress/decks/card stats and selects the new deck.

## Smoke result

Created a test deck from the wrapper preview.

Observed DB result:

- id 11
- title: test
- description: test
- archived_at: null

## Safety boundary

Only create deck is wired in the wrapper preview.

Add card, review queue, review submit, and delete actions remain disabled/unwired.

Live /study remains unchanged and fully interactive.
