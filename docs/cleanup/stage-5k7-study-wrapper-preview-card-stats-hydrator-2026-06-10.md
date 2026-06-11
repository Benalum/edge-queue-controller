# Stage 5K-7 Study Wrapper Preview Card Stats Hydrator — 2026-06-10

Added preview-only hydration for selected deck card stats and difficulty buckets on /study-wrapper-preview.

The preview fetches /api/study/decks/{deck_id}/card-stats from the laptop controller.

The preview now shows the same visible bucket counts as the real Study page: New 0, Hard 1, Medium 3, Easy 0.

Study JavaScript is still not loaded in the preview.

Live /study remains unchanged and continues to use the standalone Study page.
