# Stage 6A Universal Intent Router Foundation Plan

Stage 6A creates the planning checkpoint for the Universal Intent Router.

This stage does not change runtime behavior.

This stage does not modify Study, Companion, Chat, Calendar, Profile, admin, auth, queue, worker, or power automation behavior.

This stage exists so the platform can evolve toward one permanent input-processing architecture without creating technical debt.

## Goal

Every user input should eventually pass through a Universal Intent Router.

Current pattern:

Page input goes directly to page-specific handler.

Target pattern:

User input goes to the router first.

Router resolves intent.

Router safely dispatches to the correct existing service, model, tool, or agent.

## Permanent Router Contract

Input flows through this contract:

1. Receive user input.
2. Load authenticated user context.
3. Load page context.
4. Detect message language.
5. Resolve intent.
6. Check confidence threshold.
7. Check permissions and safety policy.
8. Execute route if allowed.
9. Log router decision and result.
10. Return structured response to the frontend.

## Initial Supported Domains

The router is designed to support:

- Study
- Companion
- Chat
- Calendar
- Profile
- Future AI agents
- Future AI video
- Future tool use
- Future automation

## First Implementation Target

Study should be the first active router integration.

Initial Study intents:

- study.session.start
- study.session.end
- study.card.next
- study.card.skip
- study.card.answer
- study.card.correct
- study.card.incorrect
- study.card.flag
- study.card.note

## Router Layers

The router should evaluate input in this order:

1. Direct action lookup
2. User phrase bank
3. Global phrase bank
4. Fuzzy phrase matching
5. Tiny multilingual intent classifier
6. Medium conversational model
7. Heavy reasoning model
8. Tool or agent workflow

The cheapest accurate layer should win.

## Direct Action Examples

Examples that should not require an LLM:

- next
- skip
- show answer
- correct
- incorrect
- wrong
- end session

These should only execute when the current page/session context allows them.

## Phrase Bank Examples

Global phrase examples:

- next card -> study.card.skip
- move on -> study.card.skip
- show me another -> study.card.skip
- pass -> study.card.skip
- I do not know this one -> study.card.skip
- show the answer -> study.card.answer
- I got it right -> study.card.correct
- I missed it -> study.card.incorrect

User phrase examples:

- let's keep going -> study.card.skip
- next one -> study.card.skip
- move on please -> study.card.skip

## Multilingual Requirements

The router should support:

- English
- Spanish
- French
- German
- Japanese
- Chinese
- future languages

Language support must be data-driven.

Do not create language-specific columns such as phrase_en or phrase_es.

Use language_code fields instead.

Recommended examples:

- en
- es
- fr
- de
- ja
- zh-Hans
- zh-Hant

## User Language Preferences

Each user should eventually have:

- primary language
- secondary languages
- study language
- preferred response language
- auto detect enabled
- mixed language enabled

Example:

Primary language: English

Secondary languages: Spanish, Japanese

Study language: Japanese

Preferred response language: match user input

Auto detect: enabled

## Initial Database Tables

The first database migration should be additive only.

Recommended first tables:

- intent_definitions
- intent_routes
- global_phrase_bank
- user_phrase_bank
- user_language_preferences
- user_secondary_languages
- router_logs
- router_resolution_steps
- router_feedback

Later tables:

- tool_registry
- tool_actions
- user_tool_permissions
- calendar_action_drafts
- calendar_provider_connections
- calendar_event_cache
- agent_definitions
- agent_runs
- agent_run_steps

## Initial API Design

Recommended first endpoints:

- POST /api/router/resolve
- POST /api/router/execute
- POST /api/router/resolve-and-execute
- GET /api/router/intents
- GET /api/router/phrase-bank
- POST /api/router/phrase-bank
- DELETE /api/router/phrase-bank/:id
- GET /api/router/language
- POST /api/router/language

The first endpoint to build should be:

POST /api/router/resolve

Execution should come after resolve-only testing works.

## Safety Rules

Safe reversible Study actions may execute automatically at high confidence.

Calendar writes, email sends, file writes, automation creation, video publishing, and destructive actions must require confirmation.

Suggested thresholds:

- reversible Study action direct execute: 0.86 or higher
- Study action confirmation: 0.70 to 0.85
- Calendar create draft: 0.85 or higher, then confirmation before provider write
- Calendar delete or update: always confirm
- Email send: always confirm
- File delete: always confirm
- Automation create: always confirm
- Video publish: always confirm

## Logging Requirements

Router logs should record:

- user id
- session id
- page context
- input text
- normalized input
- detected language
- language confidence
- resolved intent
- intent confidence
- route type
- model tier
- confirmation required
- execution status
- execution result summary
- latency
- error code if any

Detailed resolution steps should be stored separately for debugging.

## Migration Strategy

Migration should be staged.

1. Add planning doc and smoke test.
2. Add router database tables.
3. Add resolve-only endpoint.
4. Add router logs.
5. Add direct Study intent matching.
6. Add global phrase bank.
7. Add Study shadow mode.
8. Add Study execution mode behind a feature flag.
9. Add user phrase bank UI.
10. Add language preferences UI.
11. Add fuzzy matching.
12. Add tiny multilingual classifier.
13. Route Companion and Chat through the router.
14. Add Calendar draft foundation.
15. Add tool registry.
16. Add agent workflow foundation.

## Feature Flags

Recommended flags:

- ROUTER_ENABLED
- ROUTER_RESOLVE_ENABLED
- ROUTER_EXECUTE_ENABLED
- ROUTER_STUDY_ENABLED
- ROUTER_STUDY_SHADOW_MODE
- ROUTER_COMPANION_ENABLED
- ROUTER_CHAT_ENABLED
- ROUTER_CALENDAR_ENABLED
- ROUTER_TINY_MODEL_ENABLED
- ROUTER_TOOL_EXECUTION_ENABLED
- ROUTER_AGENT_ENABLED

## Rollback Strategy

Every router feature must be disableable.

If Study routing fails, disable ROUTER_STUDY_ENABLED.

If model classification fails, disable ROUTER_TINY_MODEL_ENABLED.

If Companion routing fails, disable ROUTER_COMPANION_ENABLED.

If Calendar routing fails, disable ROUTER_CALENDAR_ENABLED.

If tool execution is unsafe, disable ROUTER_TOOL_EXECUTION_ENABLED.

If the full router causes problems, disable ROUTER_ENABLED.

Existing page-specific handlers must remain available during migration.

## Stage 6A Acceptance Criteria

Stage 6A is complete when:

- this planning document exists
- smoke test exists
- smoke test verifies the required planning sections
- no runtime files are changed
- no database migration is created yet
- no API behavior changes are introduced
