#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import sqlite3
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any
from urllib.parse import quote


def connect_readonly(path: Path) -> sqlite3.Connection:
    resolved = path.expanduser().resolve()
    uri = "file:" + quote(str(resolved)) + "?mode=ro"
    conn = sqlite3.connect(uri, uri=True)
    conn.row_factory = sqlite3.Row
    conn.create_collation(
        "unicase",
        lambda a, b: (str(a).casefold() > str(b).casefold()) - (str(a).casefold() < str(b).casefold()),
    )
    return conn


def read_sqlite_header(path: Path) -> dict[str, Any]:
    with path.open("rb") as fh:
        sample = fh.read(1024 * 1024)
    header = sample[:16]
    return {
        "header_text": "".join(chr(b) if 32 <= b <= 126 else "." for b in header),
        "header_kind": "sqlite-anki-collection" if header.startswith(b"SQLite format 3") else "unknown",
        "sample_bytes": len(sample),
        "sample_sha256": hashlib.sha256(sample).hexdigest(),
        "size_bytes": path.stat().st_size,
    }


def load_json_object_tolerant(raw: str | bytes | None, label: str) -> tuple[dict[str, Any], dict[str, Any] | None]:
    if raw is None:
        return {}, {"field": label, "warning": "missing"}
    if isinstance(raw, bytes):
        raw = raw.decode("utf-8", errors="replace")
    text = str(raw).strip()
    if not text:
        return {}, {"field": label, "warning": "empty"}
    try:
        parsed = json.loads(text)
    except json.JSONDecodeError as exc:
        return {}, {
            "field": label,
            "warning": "json_decode_error",
            "message": str(exc),
            "preview": text[:120],
        }
    if not isinstance(parsed, dict):
        return {}, {"field": label, "warning": "not_json_object"}
    return parsed, None


def fetch_scalar(conn: sqlite3.Connection, sql: str) -> int:
    row = conn.execute(sql).fetchone()
    return int(row[0] if row else 0)


def int_sort_key(value: str) -> tuple[int, str]:
    try:
        return (0, f"{int(value):030d}")
    except ValueError:
        return (1, value)


def table_names(conn: sqlite3.Connection) -> set[str]:
    return {
        str(row["name"])
        for row in conn.execute("SELECT name FROM sqlite_master WHERE type = 'table'")
    }


def load_deck_names_from_table(conn: sqlite3.Connection, tables: set[str]) -> dict[str, str]:
    if "decks" not in tables:
        return {}
    return {
        str(row["id"]): str(row["name"])
        for row in conn.execute('SELECT id, name FROM decks')
    }


def load_note_type_names_from_table(conn: sqlite3.Connection, tables: set[str]) -> dict[str, str]:
    if "notetypes" not in tables:
        return {}
    return {
        str(row["id"]): str(row["name"])
        for row in conn.execute('SELECT id, name FROM notetypes')
    }


def load_fields_by_note_type(conn: sqlite3.Connection, tables: set[str]) -> dict[str, list[str]]:
    fields: dict[str, list[tuple[int, str]]] = defaultdict(list)
    if "fields" not in tables:
        return {}
    for row in conn.execute('SELECT ntid, ord, name FROM fields'):
        fields[str(row["ntid"])].append((int(row["ord"]), str(row["name"])))
    return {
        ntid: [name for _, name in sorted(values)]
        for ntid, values in fields.items()
    }


def load_templates_by_note_type(conn: sqlite3.Connection, tables: set[str]) -> dict[str, list[str]]:
    templates: dict[str, list[tuple[int, str]]] = defaultdict(list)
    if "templates" not in tables:
        return {}
    for row in conn.execute('SELECT ntid, ord, name FROM templates'):
        templates[str(row["ntid"])].append((int(row["ord"]), str(row["name"])))
    return {
        ntid: [name for _, name in sorted(values)]
        for ntid, values in templates.items()
    }


def summarize_collection(path: Path, include_empty_decks: bool = False, include_unused_note_types: bool = True) -> dict[str, Any]:
    header = read_sqlite_header(path)
    if header["header_kind"] != "sqlite-anki-collection":
        raise SystemExit(f"Not a SQLite Anki collection file: {path}")

    conn = connect_readonly(path)
    parse_warnings: list[dict[str, Any]] = []

    try:
        tables = table_names(conn)

        required = {"col", "cards", "notes"}
        missing = sorted(required - tables)
        if missing:
            raise SystemExit(f"Missing expected Anki tables: {', '.join(missing)}")

        col = conn.execute("SELECT decks, models FROM col LIMIT 1").fetchone()
        if not col:
            raise SystemExit("Anki collection table col is empty")

        decks_raw, decks_warning = load_json_object_tolerant(col["decks"], "decks")
        models_raw, models_warning = load_json_object_tolerant(col["models"], "models")
        if decks_warning:
            parse_warnings.append(decks_warning)
        if models_warning:
            parse_warnings.append(models_warning)

        deck_names_table = load_deck_names_from_table(conn, tables)
        note_type_names_table = load_note_type_names_from_table(conn, tables)
        fields_by_note_type = load_fields_by_note_type(conn, tables)
        templates_by_note_type = load_templates_by_note_type(conn, tables)

        cards_total = fetch_scalar(conn, "SELECT COUNT(*) FROM cards")
        notes_total = fetch_scalar(conn, "SELECT COUNT(*) FROM notes")

        card_counts = {
            str(row["did"]): int(row["card_count"])
            for row in conn.execute("SELECT did, COUNT(*) AS card_count FROM cards GROUP BY did")
        }

        note_counts = {
            str(row["did"]): int(row["note_count"])
            for row in conn.execute("SELECT did, COUNT(DISTINCT nid) AS note_count FROM cards GROUP BY did")
        }

        model_note_counts = {
            str(row["mid"]): int(row["note_count"])
            for row in conn.execute("SELECT mid, COUNT(*) AS note_count FROM notes GROUP BY mid")
        }

        deck_ids = set(card_counts) | set(note_counts) | set(deck_names_table) | set(str(k) for k in decks_raw.keys())
        decks: list[dict[str, Any]] = []

        for deck_id in sorted(deck_ids, key=int_sort_key):
            if deck_id in deck_names_table:
                name = deck_names_table[deck_id]
                name_source = "decks_table"
            else:
                deck_obj = decks_raw.get(deck_id)
                if isinstance(deck_obj, dict):
                    name = str(deck_obj.get("name", deck_id))
                    name_source = "col.decks"
                else:
                    name = "Default" if str(deck_id) == "1" else f"Deck {deck_id}"
                    name_source = "fallback_cards_did"

            cards = int(card_counts.get(deck_id, 0))
            notes = int(note_counts.get(deck_id, 0))
            if not include_empty_decks and cards == 0 and notes == 0:
                continue

            decks.append({
                "id": deck_id,
                "name": name,
                "name_source": name_source,
                "card_count": cards,
                "note_count": notes,
            })

        model_ids = set(model_note_counts) | set(note_type_names_table) | set(str(k) for k in models_raw.keys())
        note_types: list[dict[str, Any]] = []

        for model_id in sorted(model_ids, key=int_sort_key):
            note_count = int(model_note_counts.get(model_id, 0))
            if not include_unused_note_types and note_count == 0:
                continue

            if model_id in note_type_names_table:
                name = note_type_names_table[model_id]
                name_source = "notetypes_table"
            else:
                model = models_raw.get(model_id)
                if isinstance(model, dict):
                    name = str(model.get("name", model_id))
                    name_source = "col.models"
                else:
                    name = f"Note Type {model_id}"
                    name_source = "fallback_notes_mid"

            field_names = fields_by_note_type.get(model_id, [])
            template_names = templates_by_note_type.get(model_id, [])

            note_types.append({
                "id": model_id,
                "name": name,
                "name_source": name_source,
                "note_count": note_count,
                "field_count": len(field_names),
                "field_names": field_names,
                "template_count": len(template_names),
                "template_names": template_names,
            })

        tag_counter: Counter[str] = Counter()
        for row in conn.execute("SELECT tags FROM notes"):
            tag_counter.update(str(row["tags"] or "").strip().split())

        return {
            "source": {
                "path": str(path.expanduser()),
                "filename": path.name,
                **header,
            },
            "summary": {
                "deck_count_with_cards": sum(1 for deck in decks if deck["card_count"] > 0),
                "deck_count_total_in_collection": len(deck_ids),
                "card_count": cards_total,
                "note_count": notes_total,
                "note_type_count_with_notes": sum(1 for note_type in note_types if note_type["note_count"] > 0),
                "note_type_count_total_in_collection": len(model_ids),
                "tag_count": len(tag_counter),
            },
            "decks": decks,
            "note_types": note_types,
            "top_tags": [{"tag": tag, "count": count} for tag, count in tag_counter.most_common(25)],
            "parse_warnings": parse_warnings,
            "schema_features": {
                "has_decks_table": "decks" in tables,
                "has_notetypes_table": "notetypes" in tables,
                "has_fields_table": "fields" in tables,
                "has_templates_table": "templates" in tables,
                "deck_name_source": "decks_table" if deck_names_table else "col.decks_or_fallback",
                "note_type_name_source": "notetypes_table" if note_type_names_table else "col.models_or_fallback",
            },
            "safety": {
                "sqlite_open_mode": "mode=ro",
                "writes_performed": False,
                "uploads_performed": False,
                "anki_file_modified": False,
            },
        }
    finally:
        conn.close()


def main() -> int:
    parser = argparse.ArgumentParser(description="Summarize an Anki collection read-only.")
    parser.add_argument("--collection", required=True, help="Path to collection.anki2 or collection.anki21")
    parser.add_argument("--json-out", help="Optional output JSON path")
    parser.add_argument("--include-empty-decks", action="store_true")
    parser.add_argument("--used-note-types-only", action="store_true")
    args = parser.parse_args()

    collection = Path(args.collection).expanduser()
    if not collection.exists():
        raise SystemExit(f"Collection file not found: {collection}")
    if collection.suffix.lower() not in {".anki2", ".anki21"}:
        raise SystemExit("This proof supports collection.anki2 / collection.anki21 only")

    result = summarize_collection(
        collection,
        include_empty_decks=args.include_empty_decks,
        include_unused_note_types=not args.used_note_types_only,
    )
    text = json.dumps(result, indent=2, sort_keys=True)

    if args.json_out:
        Path(args.json_out).write_text(text + "\n", encoding="utf-8")

    print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
