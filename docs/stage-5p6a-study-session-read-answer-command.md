# Stage 5P-6A Study Session Read Answer Command

Adds the first card-level command to the durable Study session command endpoint.

Implemented:

- `read_answer` through `POST /api/study/session/command`
- intent: `study_read_answer`
- session state changes to `reviewing_answer`
- current card answer is returned

Not implemented yet:

- mark correct
- mark incorrect
- skip
- next card
- answer grading
- model routing
- UI wiring

Reading the answer does not automatically mark the card correct or incorrect.
