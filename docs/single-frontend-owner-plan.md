# Single Frontend Owner Plan — Stage 5A

## Purpose

The public website should have one visible UI owner.

The laptop/controller public wrapper should own all user-facing tabs on alexhartel.com, whether the user is logged in or logged out.

CT101 should remain the backend/API/job/model server.

## Problem being solved

The current platform has split UI ownership:

- The laptop/controller wrapper owns the public shell, login-aware routing, system pages, and platform/account UI.
- CT101 owns several full frontend pages such as Study, Chat, Companion, Calendar, Jobs, and Workers.

This causes confusing routing and login behavior because some tabs are wrapper pages while other tabs are proxied CT101 frontend pages.

Examples of confusion:

- /companion is where companion chat historically lived.
- /chat is a separate normal AI Chat route.
- /chats may fall back to the homepage.
- Direct CT101 frontend login/session behavior may not match alexhartel.com wrapper login/session behavior.

## Target architecture

The intended user-facing flow is:

1. User opens alexhartel.com.
2. The laptop/controller public wrapper loads the visible website UI.
3. Wrapper-owned tabs call CT101 backend APIs through the existing backend proxy.
4. CT101 handles backend APIs, job queue, workers, Ollama, and database state.

The laptop/controller wrapper owns the visible website shell and user-facing tabs.

CT101 owns backend APIs, database-backed app state, jobs, workers, and model execution.

## Laptop/controller wrapper owns

- Home
- Study
- Chat
- Calendar
- Jobs
- Workers
- System
- Profile
- Settings
- Support
- Credits/Admin as needed

## CT101 owns

- study API
- chat/companion API
- calendar API
- jobs API
- worker API
- database-backed app state
- Ollama/model execution
- job queue processing

## User-facing route rule

All visible tabs should load from the laptop/controller wrapper, logged in or logged out.

Logged-out protected tabs should show a login prompt or public explanation.

Logged-in protected tabs should call CT101 APIs through the existing backend proxy.

If CT101 is offline, the wrapper tab should still load and show server offline, booting, or error state.

## Route ownership target

Wrapper-owned UI routes:

- /
- /study
- /chat
- /calendar
- /jobs
- /workers
- /system
- /profile
- /settings
- /support
- /credits
- /admin

Compatibility routes:

- /companion should route to the unified Chat tab in Companion mode, or show a wrapper-owned compatibility page.
- /chats should not silently look like the homepage; it should redirect to /chat or show a clear route hint.

CT101 frontend routes should eventually be dev-only, internal-only, or fallback-only.

## API ownership remains unchanged

The UI centralization does not move data ownership.

CT101 remains source of truth for:

- /api/study/*
- /api/chats/*
- /api/companion/*
- /api/calendar/*
- /api/jobs*
- /api/workers*

Controller/laptop remains source of truth for:

- public wrapper shell
- login/session wrapper behavior
- system/public status
- power automation controls
- credits
- public route mapping

## Migration plan

### Stage 5A

Documentation and smoke checks only.

No runtime route changes.

### Stage 5B

Make wrapper navigation show the final tab set consistently.

Do not proxy protected routes to CT101 frontend automatically.

Show wrapper-owned placeholder, loading, login, or offline states for all tabs.

### Stage 5C

Move Chat UI into wrapper first.

The wrapper Chat tab should support:

- AI Chat mode
- Companion mode
- queued AI Chat toggle only for AI Chat mode
- Companion remains synchronous initially

### Stage 5D

Move Study UI into wrapper.

The wrapper Study tab should call CT101 study APIs through the public backend proxy.

### Stage 5E

Move Calendar, Profile, Jobs, and Workers UI into wrapper.

### Stage 5F

Treat CT101 frontend as dev-only or remove public dependency on it.

## Stage 5A constraints

Do not:

- change runtime behavior
- change route proxy behavior yet
- remove CT101 frontend routes
- migrate schemas
- restart services
- deploy
- change chat/study/companion behavior
- change power automation
