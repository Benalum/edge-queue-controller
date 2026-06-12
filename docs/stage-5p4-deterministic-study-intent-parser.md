# Stage 5P-4 Deterministic Study Intent Parser

Adds a backend deterministic intent parser for Study/Companion routing.

This stage adds:

- `_study_parse_deterministic_intent`
- `_study_normalize_intent_text`
- `POST /api/study/intent/parse`
- `POST /public/study/intent/parse`

This stage does not execute commands. It only classifies messages.

No model calls, queue lanes, UI wiring, or calendar changes are added.
