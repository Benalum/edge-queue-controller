# Stage 8B Universal Intent Router Decision-Maker Contract

Stage 8B defines the contract for the router decision maker.

This is a docs-only planning stage. It does not enable live routing, dispatch, model calls, or production behavior.

## Goal

The decision maker receives one user input and decides what should handle it.

Examples:

- Study command
- Companion chat
- General chat
- Calendar request later
- Unsupported/unknown input
- Confirmation-needed input

The decision maker should eventually become the first lightweight layer before any expensive model call.

## Core Principle

The router should answer this question:

> What is the safest and cheapest correct next step for this user input?

The answer should not always be an LLM call.

Many inputs should be resolved locally:

- `next`
- `skip`
- `show answer`
- `I don't know`
- `correct`
- `wrong`
- `help`
- `open companion`
- `start study`

## Required Inputs

A decision request should include:

- `text`: the raw user input
- `surface`: where the input came from, such as `study`, `companion`, `chat`, `calendar`, or `global`
- `user_id`: optional authenticated user id
- `session_id`: optional app session id
- `locale`: optional language/locale hint
- `active_route`: optional browser route
- `active_feature`: optional feature context
- `study_session_id`: optional active study session id
- `conversation_id`: optional companion/chat conversation id
- `profile_language`: optional preferred user language from profile
- `allowed_tools`: optional tool allow-list
- `dry_run`: defaults true until later activation

## Required Output

A decision response should include:

- `ok`
- `dry_run`
- `dispatch_performed`
- `model_call_required`
- `selected_path`
- `intent_key`
- `legacy_intent_name`
- `confidence`
- `needs_confirmation`
- `reason`
- `surface`
- `context_domain`
- `language_code`
- `decision_trace`
- `candidate_routes`
- `dispatch_plan`

## selected_path Values

The selected path should be one of:

- `study_command`
- `companion_chat`
- `general_chat`
- `calendar_command`
- `navigation`
- `profile_or_settings`
- `unsupported`
- `needs_confirmation`
- `no_action`

## Confidence Policy

Suggested initial thresholds:

- `>= 0.90`: safe local dispatch candidate
- `0.70 - 0.89`: dry-run/shadow or confirmation required
- `< 0.70`: ask clarification or route to general chat, depending on surface

Until activation, even high-confidence decisions must remain dry-run/shadow-only.

## Model Call Policy

The decision maker should avoid an LLM call when a local phrase, alias, or route rule is enough.

Use deterministic lookup first:

1. normalize text
2. check user phrase bank
3. check global phrase bank
4. check route/surface policy
5. check confidence threshold
6. decide local path or fallback

Only require a model call when:

- deterministic lookup fails
- user intent is conversational
- input is complex or ambiguous
- user requests explanation, tutoring, brainstorming, or general companion behavior

## Study Examples

| User input | Surface | Expected selected_path | Expected intent_key | Model call |
|---|---|---|---|---|
| next | study | study_command | study.card.next | no |
| next card | companion | study_command | study.card.next | no |
| skip | study | study_command | study.card.skip | no |
| I don't know | study | study_command | study.card.skip | no |
| show answer | study | study_command | study.card.answer | no |
| give me a hint | study | study_command | study.card.hint | maybe later |
| explain this card | study | companion_chat | companion.chat | yes/maybe |

## Companion Examples

| User input | Surface | Expected selected_path | Expected intent_key | Model call |
|---|---|---|---|---|
| how are you | companion | companion_chat | companion.chat | yes |
| explain this | companion | companion_chat | companion.chat | yes |
| next card | companion | study_command | study.card.next | no if active study session |
| skip this one | companion | study_command | study.card.skip | no if active study session |
| add this to calendar | companion | calendar_command | calendar.event.create | later/confirmation |

## Language Policy

The router should support language hints from:

- explicit `locale`
- user profile preferred language
- auto-detection later

The system should not rely only on hard-coded English phrases forever.

Initial strategy:

1. seed English phrase bank first
2. add user profile language support
3. add language-specific phrase banks
4. add user-specific phrase overrides
5. add optional lightweight language detection

## User Phrase Learning

The router should eventually learn user-specific aliases safely.

Example:

- User says `next please` several times while pressing Next.
- System can add a user phrase suggestion.
- User-specific phrase bank maps `next please` → `study.card.next`.

This should be logged and reversible.

## Dispatch Safety

No decision-maker stage should dispatch until a later activation stage explicitly enables it.

Before dispatch is allowed, the response must prove:

- `dry_run = false`
- `allowed_to_dispatch = true`
- `eligible_for_dispatch = true`
- `dispatch_performed = true`
- route policy allows the selected path
- user/session auth is valid
- confirmation is not required

## Stage 8B Decision

Stage 8B only records the contract.

Stage 8C should inspect the existing dry-run response schema and compare it to this contract.

Stage 8D should add a source-only helper or adapter if the schema needs alignment.

Stage 8E should run local disabled/temporary-enabled smokes without production dispatch.
