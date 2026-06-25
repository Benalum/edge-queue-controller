# Stage 16 FC-O45-E-CH-C — Backend Companion Study Action Endpoint

Date: 2026-06-25

## Scope

Backend source/docs/smoke only.

No frontend patch. No frontend deploy. No public `/var/www` mutation. No backend deploy. No CT203 runtime patch. No DB write by this checkpoint. No job mutation. No result insert. No model/helper/Ollama call. No scheduler/timer/persistent-worker activation. No service change. No CT/VM restart.

## Reason

The frontend became unstable from repeated wrapper patches. Direction changed to backend-first.

CH-A and CH-B confirmed that the existing backend already has Study session, deck, card, review, and deterministic Study command capabilities. CH-C adds a narrow Companion-facing Study action route that delegates to those existing backend capabilities instead of creating a new Study system.

## Added routes

- `POST /api/companion/study/action`
- `POST /public/companion/study/action`

## Supported actions

- `study_status`
- `list_decks`
- `list_cards`
- `start_study`
- `pause_study`
- `resume_study`
- `stop_study`
- `study_command`
- `add_card`
- `make_flashcards`

## Behavior

The endpoint delegates to existing Study route functions:

- Study status delegates to the existing Study session status backend.
- Start/pause/resume/stop delegate to existing Study lifecycle backend.
- Study command delegates to existing deterministic Study session command routing.
- Add card delegates to existing Study card creation backend.
- List decks/cards delegate to existing Study deck/card listing backend.

`make_flashcards` is conservative in this source-only patch: it creates deterministic card candidates without saving them. Saving uses the explicit `add_card` action so Companion cannot silently create many cards from arbitrary text.

## Later runtime steps

This checkpoint does not deploy the backend. A later bounded runtime phase should deploy to CT203, restart only the controller service, and smoke the new route with signed-in/session auth.
