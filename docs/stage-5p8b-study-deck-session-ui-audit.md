# Stage 5P-8B Study Deck / Session UI Audit

Audit-only stage before wiring Study session command buttons.

Current conclusion:

- Stage 5P-8A added a read-only Study session status card.
- Backend Study session command flow is working.
- The next UI step should not guess a deck id.
- Start button wiring should wait until we identify a reliable selected/current deck id source.
- Pause, Resume, Stop, and Refresh can be safely wired from existing session status.
- Start should either use an existing selected deck id or a small deck selector.

This stage does not change runtime behavior.
