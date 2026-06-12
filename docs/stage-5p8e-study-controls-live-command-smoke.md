# Stage 5P-8E Study Controls Live Command Smoke

Adds a test-only smoke for the Study session control command strings used by the frontend.

The smoke verifies:

- Stage 5P-8C frontend control markers are present.
- The frontend command strings are present:
  - Study Session Pause
  - Study Session Resume
  - Study Session Stop
- The live backend command endpoint accepts those same strings.
- A session can be started, paused, resumed, and stopped.

This stage does not change runtime behavior.
