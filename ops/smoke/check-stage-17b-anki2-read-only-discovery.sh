#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

TMPDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

ANKI_ROOT="$TMPDIR/Anki2"
PROFILE="$ANKI_ROOT/User 1"
MEDIA="$PROFILE/collection.media"
mkdir -p "$MEDIA"
printf 'fake image bytes not read by smoke\n' > "$MEDIA/cell-diagram.png"

python3 - "$PROFILE/collection.anki2" <<'PY'
import json
import sqlite3
import sys
from pathlib import Path

collection_path = Path(sys.argv[1])
conn = sqlite3.connect(collection_path)
try:
    conn.execute("CREATE TABLE col (decks TEXT)")
    conn.execute("CREATE TABLE notes (id INTEGER PRIMARY KEY)")
    conn.execute("CREATE TABLE cards (id INTEGER PRIMARY KEY, nid INTEGER, did INTEGER)")
    decks = {
        "1001": {"id": 1001, "name": "Biology"},
        "1002": {"id": 1002, "name": "Biology::Cells"},
    }
    conn.execute("INSERT INTO col (decks) VALUES (?)", (json.dumps(decks),))
    conn.executemany("INSERT INTO notes (id) VALUES (?)", [(2001,), (2002,), (2003,)])
    conn.executemany(
        "INSERT INTO cards (id, nid, did) VALUES (?, ?, ?)",
        [
            (3001, 2001, 1001),
            (3002, 2002, 1001),
            (3003, 2003, 1002),
        ],
    )
    conn.commit()
finally:
    conn.close()
PY

OUT="$TMPDIR/discovery.json"
python3 ops/anki/anki_readonly_discovery.py --json-only --root "$ANKI_ROOT" > "$OUT"

python3 - "$OUT" "$ANKI_ROOT" <<'PY'
import json
import sys
from pathlib import Path

out = Path(sys.argv[1])
expected_root = str(Path(sys.argv[2]))
data = json.loads(out.read_text())

assert data["schema_version"] == 1, data
assert data["tool"] == "apc_anki_readonly_discovery", data
assert data["status"] in {"ok", "not_found"}, data
assert data["anki_running"] is False, data.get("anki_process_matches")
assert data["safety"]["writes_performed"] is False, data
assert data["safety"]["collection_writes_allowed"] is False, data
assert data["safety"]["media_writes_allowed"] is False, data
assert data["safety"]["import_export_performed"] is False, data

root_records = [r for r in data["roots"] if r["path"] == expected_root]
assert root_records, data["roots"]
assert root_records[0]["exists"] is True, root_records[0]
assert root_records[0]["profile_count"] == 1, root_records[0]

profiles = data["profiles"]
assert len(profiles) == 1, profiles
profile = profiles[0]
assert profile["name"] == "User 1", profile
assert profile["read_sqlite"] is True, profile
assert profile["media_present"] is True, profile
assert profile["media_file_count"] == 1, profile
assert profile["deck_count"] == 2, profile
assert profile["total_card_count"] == 3, profile
assert profile["total_note_count"] == 3, profile

decks = {deck["name"]: deck for deck in profile["decks"]}
assert decks["Biology"]["card_count"] == 2, decks
assert decks["Biology"]["note_count"] == 2, decks
assert decks["Biology::Cells"]["card_count"] == 1, decks
assert decks["Biology::Cells"]["note_count"] == 1, decks
assert decks["Biology"]["media_present_in_profile"] is True, decks

# Confirm the smoke stayed inside the temp fixture and did not depend on a real profile.
assert all(expected_root in p["profile_path"] for p in profiles), profiles

print("PASS: Stage 17B Anki2 read-only discovery helper smoke passed")
PY
