# Stage 16 Companion Local-First Google Drive Storage Plan R3O

This checkpoint records a read-only architecture direction for moving Companion study data toward user-owned storage.

## Goal

Move decks, cards, study sessions, flags, review history, and progress toward a local-first model where the user's browser is the active working cache and the user's Google Drive is the durable user-owned sync location.

The platform should keep only the minimum server-side data needed for login, site access, billing/roles, feature flags, and safe account operation.

## Proposed storage split

### Platform server stores

- User account identifier
- Login provider link
- Plan, role, and feature flags
- Website preferences
- Minimal sync metadata
- Optional audit/security/session metadata
- Optional model job metadata

The server should not be the long-term authority for user deck/card/study content once Drive sync is implemented and migrated.

### User Google Drive stores

- Deck records
- Card records
- Study sessions
- Review history
- Flagged cards
- Progress state
- Import/export files
- Recovery snapshots

Preferred initial target is an app-owned Drive application data area or a user-selected Drive folder, depending on consent and product UX.

### Browser stores

- Active IndexedDB cache
- Current selected deck
- Current study session
- Offline mutation queue
- Last sync cursor or revision metadata
- Local UI preferences such as voice/listen controls

## Why this direction fits the product

- Reduces platform storage burden.
- Keeps user study content closer to the user.
- Supports offline-first study flows.
- Lets Companion remain useful even when model/runtime paths are unavailable.
- Makes export/import easier.
- Aligns with the current browser-only voice/listen MVP direction.

## Important clarification

This does not remove responsibility for user data. The platform must still protect login sessions, OAuth authorization, account metadata, sync metadata, and any temporary data passing through the app.

## Suggested implementation phases

### Phase 1: Keep current platform storage stable

Do not move authority yet. Keep current CT203-backed Companion behavior stable while the UI and command handling mature.

### Phase 2: Define portable study data schema

Create versioned JSON structures for:

- decks
- cards
- sessions
- review events
- flags
- sync metadata

Add export/import before sync.

### Phase 3: Add browser IndexedDB cache

Make the browser the active working store. Continue syncing to the existing backend until Drive sync is proven.

### Phase 4: Add Google sign-in and Drive authorization behind a feature flag

Treat sign-in and Drive authorization as separate user consent moments.

### Phase 5: Add opt-in Google Drive sync

Sync one user's decks/cards/sessions to Drive. Keep platform fallback and recovery export.

### Phase 6: Add conflict handling

Define predictable behavior for:

- same card edited on two browsers
- deleted deck with unsynced cards
- revoked Drive access
- failed sync
- offline changes
- schema migration

### Phase 7: Migrate default authority

After tests pass, make Drive-backed storage the default for new users and keep platform storage only as metadata/fallback.

## UI banner added in this checkpoint

The Companion page now includes a static data ownership notice:

> We’re working toward Google Drive sync so decks, cards, sessions, and study history can stay in each user’s own Google account.
>
> This is a planned storage direction. Current Companion data still uses the existing platform storage until Drive sync is built, tested, and enabled.

## Scope of this checkpoint

- Adds this architecture plan.
- Adds a static Companion banner only.
- Updates static cachebust.

No backend changes, no DB writes, no OAuth implementation, no Google API integration, no service restarts, no CT/VM restart, and no runtime/model/scheduler mutation.
