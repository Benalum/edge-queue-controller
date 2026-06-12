# Stage 5P-11J Companion Study Answer Capture

Captures plain user answers in Companion during an active Study session.

Before:

- Companion Study commands were routed to Study.
- Plain answers like `2` still went to `/api/chat/queued`.

After:

- If a Study session is active and the user types a non-command answer:
  - exact/high-confidence match marks Correct
  - clearly numeric mismatch marks Wrong
  - uncertain match asks user to say Correct, Wrong, or Skip

No Companion buttons.
No debug UI.
Normal chat still uses the queued AI endpoint when no active Study answer is being attempted.

Future improvement:

- Add model-based semantic grading for non-exact answers.
