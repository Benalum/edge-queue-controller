#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import sqlite3
from collections import Counter
from pathlib import Path
from typing import Any
from urllib.parse import quote


def connect_readonly(path: Path) -> sqlite3.Connection:
    resolved = path.expanduser().resolve()
    uri = "file:" + quote(str(resolved)) + "?mode=ro"
    return sqlite3.connect(uri, uri=True)


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


def load_json_object(raw: str | bytes | None, label: str) -> dict[str, Any]:
    if raw is None:
        return {}
    if isinstance(raw, bytes):
        raw = raw.decode("utf-8", errors="replace")
    parsed = json.loads(raw)
    if not isinstance(parsed, dict):
        raise SystemExit(f"Expected Anki {label} JSON to be an object")
    return parsed


def fetch_scalar(conn: sqlite3.Connection, sql: str) -> int:
    row = conn.execute(sql).fetchone()
    return int(row[0] if row else 0)


def summarize_collection(path: Path, include_empty_decks: bool = False) -> dict[str, Any]:
    header = read_sqlite_header(path)
    if header["header_kind"] != "sqlite-anki-collection":
        raise SystemExit(f"Not a SQLite Anki collection file: {path}")

    conn = connect_readonly(path)
    conn.row_factory = sqlite3.Row

    try:
        tables = {
            row["name"]
            for row in conn.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name"
            )
        }

        required = {"col", "cards", "notes"}
        missing = sorted(required - tables)
        if missing:
            raise SystemExit(f"Missing expected Anki tables: {', '.join(missing)}")

        col = conn.execute("SELECT decks, models FROM col LIMIT 1").fetchone()
        if not col:
            raise SystemExit("Anki collection table col is empty")

        decks_raw = load_json_object(col["decks"], "decks")
        models_raw = load_json_object(col["models"], "models")

        cards_total = fetch_scalar(conn, "SELECT COUNT(*) FROM cards")
        notes_total = fetch_scalar(conn, "SELECT COUNT(*) FROM notes")

        card_counts = {
            str(row["did"]): int(row["card_count"])
            for row in conn.execute(
                "SELECT did, COUNT(*) AS card_count FROM cards GROUP BY did ORDER BY did"
            )
        }

        note_counts = {
            str(row["did"]): int(row["note_count"])
            for row in conn.execute(
                "SELECT did, COUNT(DISTINCT nid) AS note_count FROM cards GROUP BY did ORDER BY did"
            )
        }

        model_note_counts = {
            str(row["mid"]): int(row["note_count"])
            for row in conn.execute(
                "SELECT mid, COUNT(*) AS note_count FROM notes GROUP BY mid ORDER BY mid"
            )
        }

        decks = []
        for deck_id, deck in sorted(
            decks_raw.items(),
            key=lambda item: str(item[1].get("name", item[0])).lower() if isinstance(item[1], dict) else str(item[0]),
        ):
            if not isinstance(deck, dict):
                continue
            cards = int(card_counts.get(str(deck_id), 0))
            notes = int(note_counts.get(str(deck_id), 0))
            if not include_empty_decks and cards == 0 and notes == 0:
                continue
            decks.append({
                "id": str(deck_id),
                "name": str(deck.get("name", deck_id)),
                "card_count": cards,
                "note_count": notes,
            })

        note_types = []
        for model_id, model in sorted(
            models_raw.items(),
            key=lambda item: str(item[1].get("name", item[0])).lower() if isinstance(item[1], dict) else str(item[0]),
        ):
            if not isinstance(model, dict):
                continue
            fields = model.get("flds") or []
            templates = model.get("tmpls") or []
            note_types.append({
                "id": str(model_id),
                "name": str(model.get("name", model_id)),
                "note_count": int(model_note_counts.get(str(model_id), 0)),
                "field_count": len(fields) if isinstance(fields, list) else 0,
                "template_count": len(templates) if isinstance(templates, list) else 0,
            })

        tag_counter: Counter[str] = Counter()
        for row in conn.execute("SELECT tags FROM notes"):
            tags = str(row["tags"] or "").strip().split()
            tag_counter.update(tags)

        return {
            "source": {
                "path": str(path.expanduser()),
                "filename": path.name,
                **header,
            },
            "summary": {
                "deck_count_with_cards": len(decks),
                "deck_count_total_in_collection": len(decks_raw),
                "card_count": cards_total,
                "note_count": notes_total,
                "note_type_count": len(note_types),
                "tag_count": len(tag_counter),
            },
            "decks": decks,
            "note_types": note_types,
            "top_tags": [
                {"tag": tag, "count": count}
                for tag, count in tag_counter.most_common(25)
            ],
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
    args = parser.parse_args()

    collection = Path(args.collection).expanduser()
    if not collection.exists():
        raise SystemExit(f"Collection file not found: {collection}")
    if collection.suffix.lower() not in {".anki2", ".anki21"}:
        raise SystemExit("This proof supports collection.anki2 / collection.anki21 only")

    result = summarize_collection(collection, include_empty_decks=args.include_empty_decks)
    text = json.dumps(result, indent=2, sort_keys=True)

    if args.json_out:
        Path(args.json_out).write_text(text + "\n", encoding="utf-8")

    print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
