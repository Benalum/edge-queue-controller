# Stage 5K-9 Study Wrapper Preview Rollup — 2026-06-10

## Result

/study-wrapper-preview now uses the shared wrapper header and Study dashboard-only partial.

Preview behavior:

- Loads Study counts from /api/study/progress.
- Loads deck summary from /api/study/decks.
- Loads card stats and difficulty buckets from /api/study/decks/{deck_id}/card-stats.
- Shows the recovered deck with 4 cards and 6 reviews.
- Shows New 0, Hard 1, Medium 3, Easy 0.
- Is read-only and points users to the live /study page.

Live /study behavior:

- Still serves the standalone Study page.
- Still loads /study/app.js.
- Still remains the working interactive Study page.

Decision checkpoint:

Do not replace live /study yet. The preview is readable and accurate, but create deck, add card, review queue, and answer grading actions are not wired in the shared wrapper route yet.
