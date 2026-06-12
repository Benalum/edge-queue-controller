# Stage 5P-8G Companion Refresh Loop Guard

Fixes a frontend Companion refresh/update loop risk.

Companion does not need server push yet. The current queued flow can safely:

- submit to /api/chat/queued
- poll /api/chat/queued/{job_id}
- render the assistant message after completion

The issue was the Stage 5O-35 Companion visual enhancer observing DOM changes that it also caused itself.

Fix:

- throttle Companion enhance calls
- throttle Companion side-card updates
- keep queued chat behavior unchanged
- keep backend behavior unchanged
