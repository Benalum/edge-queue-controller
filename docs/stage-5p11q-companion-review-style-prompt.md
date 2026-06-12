# Stage 5P-11Q Companion Review Style Prompt

Companion now asks for a review style after deck selection when none is selected.

Supported review styles:

- Balanced
- New
- Hard
- Medium
- Easy

The selected review style is stored in localStorage under `stage5p11qSelectedStudyReviewStyle`.

Session start sends `review_mode` with `deck_id`.
