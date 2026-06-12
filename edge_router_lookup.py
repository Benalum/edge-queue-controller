"""Read-only Universal Intent Router SQLite lookup helpers.

Stage 6AE adds exact phrase lookup helpers for the router foundation tables.

This module does not dispatch actions.
This module does not call models.
This module does not mutate application state.
"""

from __future__ import annotations

import re
import sqlite3
import unicodedata
from typing import Any


def normalize_router_phrase(text: str | None) -> str:
    """Normalize user phrase text for exact phrase-bank lookup."""

    value = (text or "").strip().casefold()
    value = unicodedata.normalize("NFKD", value)
    value = "".join(ch for ch in value if not unicodedata.combining(ch))
    value = value.replace("'", "").replace("’", "").replace("`", "")
    value = re.sub(r"[^\w\s]", " ", value)
    value = re.sub(r"\s+", " ", value).strip()
    return value


def _row_to_dict(row: sqlite3.Row | None) -> dict[str, Any] | None:
    if row is None:
        return None
    return {key: row[key] for key in row.keys()}


def lookup_global_phrase(
    conn: sqlite3.Connection,
    input_text: str,
    *,
    language_code: str = "en",
    context_domain: str = "study",
) -> dict[str, Any]:
    """Look up an exact global phrase-bank match.

    Returns a read-only resolution object. It never dispatches.
    """

    normalized = normalize_router_phrase(input_text)
    language = (language_code or "en").strip().casefold()
    context = (context_domain or "global").strip().casefold()

    result: dict[str, Any] = {
        "ok": True,
        "matched": False,
        "source": "global_phrase_bank",
        "input_text": input_text,
        "normalized_phrase": normalized,
        "language_code": language,
        "context_domain": context,
        "intent_key": None,
        "intent": None,
        "route": None,
        "dispatch_performed": False,
        "model_call_required": False,
    }

    if not normalized:
        result["ok"] = False
        result["error_code"] = "empty_input"
        return result

    conn.row_factory = sqlite3.Row

    candidates: list[tuple[str, str]] = []
    for pair in (
        (language, context),
        (language, "global"),
        ("en", context),
        ("en", "global"),
    ):
        if pair not in candidates:
            candidates.append(pair)

    phrase_row: sqlite3.Row | None = None

    for candidate_language, candidate_context in candidates:
        phrase_row = conn.execute(
            """
            SELECT *
            FROM global_phrase_bank
            WHERE normalized_phrase = ?
              AND language_code = ?
              AND context_domain = ?
              AND enabled = 1
            ORDER BY priority ASC, confidence_boost DESC, id ASC
            LIMIT 1
            """,
            (normalized, candidate_language, candidate_context),
        ).fetchone()

        if phrase_row is not None:
            result["language_code"] = candidate_language
            result["context_domain"] = candidate_context
            break

    if phrase_row is None:
        result["error_code"] = "no_phrase_match"
        return result

    intent_key = phrase_row["intent_key"]

    intent_row = conn.execute(
        """
        SELECT *
        FROM intent_definitions
        WHERE intent_key = ?
          AND enabled = 1
        LIMIT 1
        """,
        (intent_key,),
    ).fetchone()

    route_row = conn.execute(
        """
        SELECT *
        FROM intent_routes
        WHERE intent_key = ?
          AND enabled = 1
        ORDER BY confirmation_required ASC, min_confidence ASC, id ASC
        LIMIT 1
        """,
        (intent_key,),
    ).fetchone()

    result.update(
        {
            "matched": True,
            "phrase": _row_to_dict(phrase_row),
            "intent_key": intent_key,
            "intent": _row_to_dict(intent_row),
            "route": _row_to_dict(route_row),
            "error_code": None,
        }
    )

    return result


def lookup_router_exact_phrase(
    conn: sqlite3.Connection,
    input_text: str,
    *,
    language_code: str = "en",
    context_domain: str = "study",
) -> dict[str, Any]:
    """Resolve an exact phrase-bank router lookup without dispatching."""

    return lookup_global_phrase(
        conn,
        input_text,
        language_code=language_code,
        context_domain=context_domain,
    )
