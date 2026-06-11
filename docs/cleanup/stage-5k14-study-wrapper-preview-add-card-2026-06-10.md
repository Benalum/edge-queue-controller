# Stage 5K-14 Study Wrapper Preview Add Card — 2026-06-10

## Result

Enabled add-card action on /study-wrapper-preview.

The wrapper preview now POSTs to /api/study/decks/{deck_id}/cards with the existing Study payload shape:

- question
- answer
- explanation
- difficulty
- tags

After adding a card, the preview reloads Study progress/decks/card stats and keeps the selected deck active.

## Smoke result

Added a test card to the wrapper-created test deck.

Observed DB result:

- deck_id: 11
- question: wrapper
- answer: works
- explanation: does it
- tags_json: ["test"]

## Safety boundary

Create deck and add card are wired in the wrapper preview.

Review queue, review submit, and delete actions remain disabled/unwired.

Live /study remains unchanged and fully interactive.
