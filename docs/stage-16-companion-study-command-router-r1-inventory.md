# Stage 16 Companion Study Command Router R1 Inventory

This checkpoint records the read-only inventory before implementing the deterministic Companion Study command router.

## Goal

Build Companion commands that can operate the same durable Study features already proven through `APC_STUDY_STORE`:

- start/pause/resume/stop study session
- select deck
- create/edit/delete/archive deck
- create/edit/delete/archive card
- flag/unflag card
- show/list current study context
- multi-turn confirmation for destructive actions
- multi-turn card creation/editing prompts

## Design direction

Use a deterministic state machine first. Do not send these commands to the model until command routing is stable.

Initial command states:

- `idle`
- `studying`
- `paused`
- `creating_card.awaiting_deck`
- `creating_card.awaiting_question`
- `creating_card.awaiting_answer`
- `editing_card.awaiting_field`
- `deleting_card.awaiting_confirm`
- `selecting_deck`

## Data authority

Companion should call `window.APC_STUDY_STORE` functions so Study and Companion share the same CT203-backed persistence path.
