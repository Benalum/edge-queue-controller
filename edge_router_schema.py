"""Universal Intent Router SQLite schema foundation.

Stage 6AA adds the persistent schema definition for the router foundation.

This module is intentionally not wired into edge_controller.py yet.
It only provides reusable schema initialization logic that can be tested
against a temporary SQLite database.

Runtime behavior should not change until a later explicit wiring stage.
"""

from __future__ import annotations

import sqlite3


ROUTER_FOUNDATION_TABLES = (
    "intent_definitions",
    "intent_routes",
    "global_phrase_bank",
    "user_phrase_bank",
    "user_language_preferences",
    "user_secondary_languages",
    "router_logs",
    "router_resolution_steps",
    "router_feedback",
)


def init_router_foundation_schema(conn: sqlite3.Connection) -> None:
    """Create the Universal Intent Router foundation tables.

    The schema is additive and safe for SQLite. It does not drop or rewrite
    existing application tables.
    """

    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS intent_definitions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            intent_key TEXT NOT NULL UNIQUE,
            domain TEXT NOT NULL,
            object_name TEXT,
            action_name TEXT NOT NULL,
            description TEXT,
            default_route_type TEXT NOT NULL DEFAULT 'direct_action',
            default_model_tier TEXT NOT NULL DEFAULT 'none',
            requires_auth INTEGER NOT NULL DEFAULT 1,
            requires_confirmation_default INTEGER NOT NULL DEFAULT 0,
            reversible INTEGER NOT NULL DEFAULT 1,
            enabled INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS intent_routes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            intent_key TEXT NOT NULL,
            route_type TEXT NOT NULL,
            target_service TEXT NOT NULL DEFAULT '',
            target_handler TEXT NOT NULL DEFAULT '',
            tool_name TEXT NOT NULL DEFAULT '',
            agent_name TEXT NOT NULL DEFAULT '',
            min_confidence REAL NOT NULL DEFAULT 0.86,
            confirmation_required INTEGER NOT NULL DEFAULT 0,
            enabled INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            UNIQUE(intent_key, route_type, target_service, target_handler, tool_name, agent_name),
            FOREIGN KEY(intent_key) REFERENCES intent_definitions(intent_key)
        );

        CREATE TABLE IF NOT EXISTS global_phrase_bank (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phrase TEXT NOT NULL,
            normalized_phrase TEXT NOT NULL,
            language_code TEXT NOT NULL DEFAULT 'en',
            intent_key TEXT NOT NULL,
            context_domain TEXT NOT NULL DEFAULT 'global',
            confidence_boost REAL NOT NULL DEFAULT 0.0,
            priority INTEGER NOT NULL DEFAULT 100,
            enabled INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            UNIQUE(normalized_phrase, language_code, context_domain),
            FOREIGN KEY(intent_key) REFERENCES intent_definitions(intent_key)
        );

        CREATE TABLE IF NOT EXISTS user_phrase_bank (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            phrase TEXT NOT NULL,
            normalized_phrase TEXT NOT NULL,
            language_code TEXT NOT NULL DEFAULT 'en',
            intent_key TEXT NOT NULL,
            context_domain TEXT NOT NULL DEFAULT 'global',
            priority INTEGER NOT NULL DEFAULT 100,
            enabled INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            UNIQUE(user_id, normalized_phrase, language_code, context_domain),
            FOREIGN KEY(user_id) REFERENCES app_users(id),
            FOREIGN KEY(intent_key) REFERENCES intent_definitions(intent_key)
        );

        CREATE TABLE IF NOT EXISTS user_language_preferences (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL UNIQUE,
            primary_language TEXT NOT NULL DEFAULT 'en',
            preferred_response_language TEXT NOT NULL DEFAULT 'match_input',
            study_language TEXT,
            auto_detect_enabled INTEGER NOT NULL DEFAULT 1,
            mixed_language_enabled INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES app_users(id)
        );

        CREATE TABLE IF NOT EXISTS user_secondary_languages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            language_code TEXT NOT NULL,
            priority INTEGER NOT NULL DEFAULT 100,
            enabled INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            UNIQUE(user_id, language_code),
            FOREIGN KEY(user_id) REFERENCES app_users(id)
        );

        CREATE TABLE IF NOT EXISTS router_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            session_id TEXT,
            page_context TEXT,
            input_text TEXT,
            normalized_input TEXT,
            detected_language TEXT,
            language_confidence REAL,
            resolved_intent TEXT,
            intent_confidence REAL,
            route_type TEXT,
            model_tier TEXT,
            required_confirmation INTEGER NOT NULL DEFAULT 0,
            execution_status TEXT NOT NULL DEFAULT 'resolved',
            execution_result_summary TEXT,
            error_code TEXT,
            latency_ms INTEGER,
            metadata_json TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES app_users(id)
        );

        CREATE TABLE IF NOT EXISTS router_resolution_steps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            router_log_id INTEGER NOT NULL,
            layer_name TEXT NOT NULL,
            candidate_intent TEXT,
            confidence REAL,
            reason TEXT,
            accepted INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY(router_log_id) REFERENCES router_logs(id)
        );

        CREATE TABLE IF NOT EXISTS router_feedback (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            router_log_id INTEGER,
            input_text TEXT,
            predicted_intent TEXT,
            corrected_intent TEXT,
            feedback_type TEXT NOT NULL,
            notes TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES app_users(id),
            FOREIGN KEY(router_log_id) REFERENCES router_logs(id)
        );

        CREATE INDEX IF NOT EXISTS idx_intent_definitions_domain
            ON intent_definitions(domain);

        CREATE INDEX IF NOT EXISTS idx_intent_routes_intent_key
            ON intent_routes(intent_key);

        CREATE INDEX IF NOT EXISTS idx_global_phrase_bank_lookup
            ON global_phrase_bank(normalized_phrase, language_code, context_domain, enabled);

        CREATE INDEX IF NOT EXISTS idx_user_phrase_bank_lookup
            ON user_phrase_bank(user_id, normalized_phrase, language_code, context_domain, enabled);

        CREATE INDEX IF NOT EXISTS idx_user_language_preferences_user_id
            ON user_language_preferences(user_id);

        CREATE INDEX IF NOT EXISTS idx_user_secondary_languages_user_id
            ON user_secondary_languages(user_id);

        CREATE INDEX IF NOT EXISTS idx_router_logs_user_created
            ON router_logs(user_id, created_at);

        CREATE INDEX IF NOT EXISTS idx_router_logs_intent_created
            ON router_logs(resolved_intent, created_at);

        CREATE INDEX IF NOT EXISTS idx_router_resolution_steps_log
            ON router_resolution_steps(router_log_id);

        CREATE INDEX IF NOT EXISTS idx_router_feedback_user_created
            ON router_feedback(user_id, created_at);
        """
    )


def router_foundation_table_names() -> tuple[str, ...]:
    """Return the expected router foundation table names."""

    return ROUTER_FOUNDATION_TABLES
