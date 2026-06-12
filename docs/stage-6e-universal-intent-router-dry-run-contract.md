# Stage 6E Universal Intent Router Dry-Run Contract

Stage 6E defines the disabled/dry-run Universal Intent Router contract.

This stage does not change runtime behavior.

This stage does not add a runtime router endpoint.

## Router request contract

Required request sections:

- input
- context
- page_context
- router_options

## Router response contract

Required response fields:

- ok
- dry_run
- dispatch_performed
- language
- intent
- target
- model_routing
- safety
- actions
- errors

## Canonical intent names

- study.answer
- study.next
- study.skip
- study.hint
- study.explain
- study.create_material
- companion.chat
- companion.study_help
- companion.calendar_request
- calendar.read_request
- calendar.write_request
- profile.preference_update
- admin.system_status
- unknown.general_chat
- unknown.unsupported

## Model tiers

- fast_intent
- medium_conversation
- large_reasoning

## Dispatch rules

Dry-run router must not dispatch.

A future router may dispatch only to approved router_candidate routes.

## Never dispatch directly

The router must never directly execute:

- power routes
- internal routes
- auth/security routes
- password routes
- admin/system mutation routes
- infrastructure routes
- delete routes without explicit confirmation
- external provider writes without explicit confirmation

## Language policy

Use profile language as default, auto-detect input language, and keep canonical internal intent names language-neutral.

## Stage 6E boundary

Stage 6E is contract-only.
