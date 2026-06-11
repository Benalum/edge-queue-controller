# Stage 5N-6 Calendar Direction — Google / Apple Only — 2026-06-11

## Decision

Do not build or use a local first-party calendar event store.

The AI Platform Calendar feature should use external calendar providers only:

- Google Calendar
- Apple Calendar

## Reverted path

A minimal local `/api/calendar/events` controller API was attempted during Stage 5N-6, but this is not the desired product direction.

The local calendar API/table approach was reverted before commit.

## Desired future design

Calendar should become an integration surface, not a separate local calendar database.

The future Calendar tab should support:

- Connect Google Calendar
- Connect Apple Calendar
- Read upcoming events from connected providers
- Create/update/delete events through the connected provider APIs
- Provide Companion with calendar context from connected providers only

## Temporary UI behavior

Until Google/Apple calendar integrations are implemented, the Calendar tab should show a clear setup/coming-soon state instead of relying on a local `/api/calendar/events` store.

## Safety note

Do not store calendar events in a local `calendar_events` table as the primary source of truth.
