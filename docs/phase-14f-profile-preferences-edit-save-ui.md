# Phase 14F Profile Preferences Edit Save UI

Phase 14F adds editable Profile preference controls to the wrapper UI.

## Behavior

Logged-in users can edit allowed preference fields and save them through:

- `PATCH /api/profile/preferences`

The browser only sends changed fields.

## Editable fields

- preferred language
- study language
- learning style
- study explanation depth
- answer strictness
- study session default mode
- companion behavior
- companion tone
- companion memory scope
- calendar provider preference
- notification preference
- voice preference flags
- accessibility preference flags

## Safety boundaries

This phase does not:

- activate microphone capture
- activate speech output
- authorize Google Calendar
- authorize Apple Calendar
- call models
- enqueue jobs
- dispatch workers
- activate tools
- write calendar events
- change power automation

Voice, listen, speak, auto-listen, and auto-speak controls store preferences only. They do not turn on browser audio behavior.
