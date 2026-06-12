# Stage 5P-11I Companion Study Command Routing

Routes typed Study phrases from Companion directly to the Study session command endpoint.

This keeps Companion clean:

- No extra buttons.
- No debug UI.
- No testing controls.

Behavior:

- User types a Study phrase in Companion.
- Frontend recognizes deterministic Study phrases.
- The message is routed to `/api/study/session/command`.
- Companion displays a normal assistant-style response.
- Non-Study messages still go through `/api/chat/queued`.

Examples:

- Study session start
- Study session pause
- Study session resume
- Study session stop
- Read the answer
- Correct
- Wrong
- Skip
