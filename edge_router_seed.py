"""Universal Intent Router seed data foundation.

Stage 6AC adds deterministic seed data for the router foundation tables.

This module is intentionally safe and idempotent.
It does not wire router dispatch.
It does not call models.
It does not change frontend behavior.
"""

from __future__ import annotations

import sqlite3
from datetime import datetime, timezone


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


INTENT_DEFINITIONS = (
    # Study session intents
    {
        "intent_key": "study.session.start",
        "domain": "study",
        "object_name": "session",
        "action_name": "start",
        "description": "Start a study session.",
        "default_route_type": "service_action",
        "default_model_tier": "none",
        "requires_confirmation_default": 0,
        "reversible": 1,
    },
    {
        "intent_key": "study.session.end",
        "domain": "study",
        "object_name": "session",
        "action_name": "end",
        "description": "End the active study session.",
        "default_route_type": "service_action",
        "default_model_tier": "none",
        "requires_confirmation_default": 0,
        "reversible": 1,
    },

    # Study card intents
    {
        "intent_key": "study.card.next",
        "domain": "study",
        "object_name": "card",
        "action_name": "next",
        "description": "Move to the next study card.",
        "default_route_type": "service_action",
        "default_model_tier": "none",
        "requires_confirmation_default": 0,
        "reversible": 1,
    },
    {
        "intent_key": "study.card.skip",
        "domain": "study",
        "object_name": "card",
        "action_name": "skip",
        "description": "Skip the current study card.",
        "default_route_type": "service_action",
        "default_model_tier": "none",
        "requires_confirmation_default": 0,
        "reversible": 1,
    },
    {
        "intent_key": "study.card.answer",
        "domain": "study",
        "object_name": "card",
        "action_name": "answer",
        "description": "Reveal the current study card answer.",
        "default_route_type": "service_action",
        "default_model_tier": "none",
        "requires_confirmation_default": 0,
        "reversible": 1,
    },
    {
        "intent_key": "study.card.correct",
        "domain": "study",
        "object_name": "card",
        "action_name": "correct",
        "description": "Mark the current study card correct.",
        "default_route_type": "service_action",
        "default_model_tier": "none",
        "requires_confirmation_default": 0,
        "reversible": 1,
    },
    {
        "intent_key": "study.card.incorrect",
        "domain": "study",
        "object_name": "card",
        "action_name": "incorrect",
        "description": "Mark the current study card incorrect.",
        "default_route_type": "service_action",
        "default_model_tier": "none",
        "requires_confirmation_default": 0,
        "reversible": 1,
    },
    {
        "intent_key": "study.card.flag",
        "domain": "study",
        "object_name": "card",
        "action_name": "flag",
        "description": "Flag the current study card for review.",
        "default_route_type": "service_action",
        "default_model_tier": "none",
        "requires_confirmation_default": 0,
        "reversible": 1,
    },
    {
        "intent_key": "study.card.note",
        "domain": "study",
        "object_name": "card",
        "action_name": "note",
        "description": "Add a note to the current study card.",
        "default_route_type": "service_action",
        "default_model_tier": "none",
        "requires_confirmation_default": 0,
        "reversible": 1,
    },

    # Companion / chat intents
    {
        "intent_key": "companion.chat.message",
        "domain": "companion",
        "object_name": "chat",
        "action_name": "message",
        "description": "Handle a normal Companion conversation message.",
        "default_route_type": "conversation",
        "default_model_tier": "medium",
        "requires_confirmation_default": 0,
        "reversible": 1,
    },
    {
        "intent_key": "chat.message",
        "domain": "chat",
        "object_name": "chat",
        "action_name": "message",
        "description": "Handle a normal Chat conversation message.",
        "default_route_type": "conversation",
        "default_model_tier": "medium",
        "requires_confirmation_default": 0,
        "reversible": 1,
    },

    # Calendar placeholder intents
    {
        "intent_key": "calendar.event.create",
        "domain": "calendar",
        "object_name": "event",
        "action_name": "create",
        "description": "Create a calendar event draft for confirmation.",
        "default_route_type": "tool_action",
        "default_model_tier": "medium",
        "requires_confirmation_default": 1,
        "reversible": 0,
    },
    {
        "intent_key": "calendar.reminder.create",
        "domain": "calendar",
        "object_name": "reminder",
        "action_name": "create",
        "description": "Create a reminder draft for confirmation.",
        "default_route_type": "tool_action",
        "default_model_tier": "medium",
        "requires_confirmation_default": 1,
        "reversible": 0,
    },

    # Unknown fallback
    {
        "intent_key": "unknown.unsupported",
        "domain": "unknown",
        "object_name": "unknown",
        "action_name": "unsupported",
        "description": "Input could not be mapped safely.",
        "default_route_type": "none",
        "default_model_tier": "none",
        "requires_confirmation_default": 1,
        "reversible": 1,
    },
)


INTENT_ROUTES = (
    ("study.session.start", "service_action", "study", "start_session", "", "", 0.90, 0),
    ("study.session.end", "service_action", "study", "end_session", "", "", 0.86, 0),
    ("study.card.next", "service_action", "study", "next_card", "", "", 0.86, 0),
    ("study.card.skip", "service_action", "study", "skip_card", "", "", 0.86, 0),
    ("study.card.answer", "service_action", "study", "reveal_answer", "", "", 0.86, 0),
    ("study.card.correct", "service_action", "study", "mark_correct", "", "", 0.90, 0),
    ("study.card.incorrect", "service_action", "study", "mark_incorrect", "", "", 0.90, 0),
    ("study.card.flag", "service_action", "study", "flag_card", "", "", 0.86, 0),
    ("study.card.note", "service_action", "study", "add_note", "", "", 0.86, 0),
    ("companion.chat.message", "conversation", "companion", "message", "", "", 0.60, 0),
    ("chat.message", "conversation", "chat", "message", "", "", 0.60, 0),
    ("calendar.event.create", "tool_action", "calendar", "create_event_draft", "calendar", "", 0.85, 1),
    ("calendar.reminder.create", "tool_action", "calendar", "create_reminder_draft", "calendar", "", 0.85, 1),
    ("unknown.unsupported", "none", "", "", "", "", 1.00, 1),
)


GLOBAL_PHRASES = (
    # English Study navigation
    ("next", "next", "en", "study.card.next", "study", 0.0, 10),
    ("n", "n", "en", "study.card.next", "study", 0.0, 10),
    ("next card", "next card", "en", "study.card.next", "study", 0.0, 10),
    ("go on", "go on", "en", "study.card.next", "study", 0.0, 20),
    ("move on", "move on", "en", "study.card.skip", "study", 0.0, 20),
    ("skip", "skip", "en", "study.card.skip", "study", 0.0, 10),
    ("pass", "pass", "en", "study.card.skip", "study", 0.0, 10),
    ("I don't know", "i dont know", "en", "study.card.skip", "study", 0.0, 20),
    ("I do not know", "i do not know", "en", "study.card.skip", "study", 0.0, 20),
    ("not sure", "not sure", "en", "study.card.skip", "study", 0.0, 20),
    ("don't know this one", "dont know this one", "en", "study.card.skip", "study", 0.0, 20),

    # English Study answer / scoring
    ("show answer", "show answer", "en", "study.card.answer", "study", 0.0, 10),
    ("show the answer", "show the answer", "en", "study.card.answer", "study", 0.0, 10),
    ("answer", "answer", "en", "study.card.answer", "study", 0.0, 20),
    ("flip", "flip", "en", "study.card.answer", "study", 0.0, 20),
    ("correct", "correct", "en", "study.card.correct", "study", 0.0, 10),
    ("right", "right", "en", "study.card.correct", "study", 0.0, 20),
    ("I got it", "i got it", "en", "study.card.correct", "study", 0.0, 20),
    ("wrong", "wrong", "en", "study.card.incorrect", "study", 0.0, 10),
    ("incorrect", "incorrect", "en", "study.card.incorrect", "study", 0.0, 10),
    ("I missed it", "i missed it", "en", "study.card.incorrect", "study", 0.0, 20),
    ("flag this", "flag this", "en", "study.card.flag", "study", 0.0, 20),
    ("add note", "add note", "en", "study.card.note", "study", 0.0, 20),
    ("end session", "end session", "en", "study.session.end", "study", 0.0, 10),

    # Spanish Study aliases
    ("siguiente", "siguiente", "es", "study.card.next", "study", 0.0, 10),
    ("próximo", "próximo", "es", "study.card.next", "study", 0.0, 10),
    ("proximo", "proximo", "es", "study.card.next", "study", 0.0, 10),
    ("omitir", "omitir", "es", "study.card.skip", "study", 0.0, 10),
    ("pasar", "pasar", "es", "study.card.skip", "study", 0.0, 10),
    ("no sé", "no se", "es", "study.card.skip", "study", 0.0, 20),
    ("mostrar respuesta", "mostrar respuesta", "es", "study.card.answer", "study", 0.0, 10),
    ("respuesta", "respuesta", "es", "study.card.answer", "study", 0.0, 20),
    ("correcto", "correcto", "es", "study.card.correct", "study", 0.0, 10),
    ("incorrecto", "incorrecto", "es", "study.card.incorrect", "study", 0.0, 10),
)


def seed_router_foundation_data(conn: sqlite3.Connection) -> None:
    """Seed initial Universal Intent Router definitions and global phrases."""

    now = _now()

    for item in INTENT_DEFINITIONS:
        conn.execute(
            """
            INSERT INTO intent_definitions (
                intent_key,
                domain,
                object_name,
                action_name,
                description,
                default_route_type,
                default_model_tier,
                requires_auth,
                requires_confirmation_default,
                reversible,
                enabled,
                created_at,
                updated_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?, 1, ?, ?)
            ON CONFLICT(intent_key) DO UPDATE SET
                domain = excluded.domain,
                object_name = excluded.object_name,
                action_name = excluded.action_name,
                description = excluded.description,
                default_route_type = excluded.default_route_type,
                default_model_tier = excluded.default_model_tier,
                requires_confirmation_default = excluded.requires_confirmation_default,
                reversible = excluded.reversible,
                enabled = 1,
                updated_at = excluded.updated_at
            """,
            (
                item["intent_key"],
                item["domain"],
                item["object_name"],
                item["action_name"],
                item["description"],
                item["default_route_type"],
                item["default_model_tier"],
                item["requires_confirmation_default"],
                item["reversible"],
                now,
                now,
            ),
        )

    for (
        intent_key,
        route_type,
        target_service,
        target_handler,
        tool_name,
        agent_name,
        min_confidence,
        confirmation_required,
    ) in INTENT_ROUTES:
        conn.execute(
            """
            INSERT INTO intent_routes (
                intent_key,
                route_type,
                target_service,
                target_handler,
                tool_name,
                agent_name,
                min_confidence,
                confirmation_required,
                enabled,
                created_at,
                updated_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
            ON CONFLICT(intent_key, route_type, target_service, target_handler, tool_name, agent_name)
            DO UPDATE SET
                min_confidence = excluded.min_confidence,
                confirmation_required = excluded.confirmation_required,
                enabled = 1,
                updated_at = excluded.updated_at
            """,
            (
                intent_key,
                route_type,
                target_service,
                target_handler,
                tool_name,
                agent_name,
                min_confidence,
                confirmation_required,
                now,
                now,
            ),
        )

    for (
        phrase,
        normalized_phrase,
        language_code,
        intent_key,
        context_domain,
        confidence_boost,
        priority,
    ) in GLOBAL_PHRASES:
        conn.execute(
            """
            INSERT INTO global_phrase_bank (
                phrase,
                normalized_phrase,
                language_code,
                intent_key,
                context_domain,
                confidence_boost,
                priority,
                enabled,
                created_at,
                updated_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
            ON CONFLICT(normalized_phrase, language_code, context_domain)
            DO UPDATE SET
                phrase = excluded.phrase,
                intent_key = excluded.intent_key,
                confidence_boost = excluded.confidence_boost,
                priority = excluded.priority,
                enabled = 1,
                updated_at = excluded.updated_at
            """,
            (
                phrase,
                normalized_phrase,
                language_code,
                intent_key,
                context_domain,
                confidence_boost,
                priority,
                now,
                now,
            ),
        )


def router_seed_counts(conn: sqlite3.Connection) -> dict[str, int]:
    """Return row counts for seeded router tables."""

    names = (
        "intent_definitions",
        "intent_routes",
        "global_phrase_bank",
    )
    return {
        name: int(conn.execute(f"SELECT COUNT(*) FROM {name}").fetchone()[0])
        for name in names
    }
