# Stage 6B Universal Intent Router Input Surface Audit

Stage 6B audits every current user-input surface before implementing the Universal Intent Router.

This stage does not change runtime behavior.

This stage does not modify Study, Companion, Chat, Calendar, Profile, Admin, auth, queue, worker, or power automation behavior.

## Why this stage exists

The platform is moving toward one permanent input-processing architecture:

User input → Universal Intent Router → intent decision → safe dispatch to existing services/tools/models.

Before adding the router, we need to know where user input currently enters the system.

## Stage 6A baseline

Stage 6A created the foundation plan.

Stage 6B continues that plan by mapping current input surfaces.

## Current input surface categories

The platform currently has several types of input:

1. Page-level chat/input boxes.
2. Study actions.
3. Companion messages.
4. Legacy Chat messages.
5. Calendar-related future inputs.
6. Profile/preferences inputs.
7. Admin/system actions.
8. Queue job creation.
9. Worker/agent messages.
10. Auth/session/presence events.

Not all of these should go through the same runtime model yet.

## Router migration principle

Do not break working pages.

Do not replace existing handlers immediately.

Add the router in front of existing handlers only after the current handler contract is understood.

The first runtime router should be an adapter layer, not a rewrite.

## Proposed permanent router contract

Every user-facing input should eventually become:

1. Receive input.
2. Load authenticated user context.
3. Load page context.
4. Load optional user preferences.
5. Detect language.
6. Detect intent.
7. Decide model/tool/handler.
8. Apply safety and permission rules.
9. Dispatch to existing service.
10. Return structured response.
11. Log non-sensitive routing metadata.

## Intent decision categories

Initial router categories should be small:

- `study.answer`
- `study.next`
- `study.skip`
- `study.hint`
- `study.create_material`
- `companion.chat`
- `companion.study_help`
- `companion.calendar_request`
- `calendar.read_request`
- `calendar.write_request`
- `profile.preference_update`
- `admin.system_status`
- `unknown.general_chat`

## LLM routing tiers

The platform should support multiple model tiers:

### Fast intent model

Purpose:

- Interpret short user commands.
- Normalize phrases such as "next", "skip", "move on", "I don't know", or other languages.
- Route obvious actions without using a larger model.

Expected use:

- Study card controls.
- Simple page commands.
- Language detection.
- Intent classification.

### Medium conversation model

Purpose:

- General Companion conversation.
- Study explanations.
- User support.
- Calendar phrasing in the future.
- Profile preference reasoning.

Expected use:

- Companion surface.
- Study help.
- User asks questions instead of pressing buttons.

### Larger/specialized model

Purpose:

- Complex reasoning.
- Creating study material.
- Long-form editing.
- Multi-step planning.
- Future tool/agent workflows.

Expected use:

- Expensive operations only.
- Never needed for simple button-like commands.

## Preferred language handling

Preferred language should be stored in Profile eventually.

The router should still auto-detect input language.

Recommended behavior:

1. Use profile preferred language as default response language.
2. Auto-detect if the user input is clearly in another language.
3. Allow multiple learning/working languages later.
4. Avoid hard-coding English-only command phrases.
5. Keep canonical internal intents language-neutral.

Example:

A Spanish input like "siguiente" should map to the same internal intent as "next":

`study.next`

## Router should not own every feature yet

The router should decide where input goes.

Existing services should still do the actual work.

Examples:

- Study answer checking remains Study-owned.
- Queue job management remains queue-owned.
- Calendar write operations require explicit user approval.
- Profile updates remain profile-owned.
- Admin power actions remain admin/system-owned.

## Safety and permissions

The router must know whether an action is:

- read-only
- user-visible write
- admin-only write
- external provider write
- infrastructure/power action
- model-only response
- tool/agent action

High-risk actions must never happen from casual text alone.

Examples requiring explicit confirmation:

- Calendar writes
- Deleting data
- Admin/system actions
- Power shutdown
- Account/security changes
- Sending emails/messages if added later

## Stage 6B audit targets

The audit should identify:

- Current route/function name.
- Current page/surface.
- Input payload shape.
- Existing handler behavior.
- Whether the future router should sit in front of it.
- Whether the route is safe to migrate early.
- Whether the route should remain direct/admin-only.

## Early migration candidates

Good early candidates:

- Study "next/skip/I don't know" style commands.
- Companion general chat dispatch.
- Language normalization.
- Simple Study help requests.

Bad early candidates:

- Auth/login.
- Billing/account.
- Admin power controls.
- Worker internal queue routes.
- Infrastructure execution routes.
- Anything that can delete, send, shutdown, or mutate critical state.

## Stage 6B deliverable

Stage 6B creates a document and smoke check that verify:

- The Stage 6A plan still exists.
- The Stage 6B audit document exists.
- No runtime code was changed by this stage.
- The next stage can safely inspect route handlers.
