#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HELPER="${REPO_ROOT}/ops/anki/anki_readonly_discovery.py"

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

FAKE_HOME="${TMP_DIR}/home"
FAKE_XDG="${TMP_DIR}/xdg-data"
ANKI_ROOT="${FAKE_HOME}/.local/share/Anki2"
PROFILE="${ANKI_ROOT}/User 1"
MEDIA="${PROFILE}/collection.media"
COLLECTION="${PROFILE}/collection.anki2"
OUT="${TMP_DIR}/discovery.json"

mkdir -p "${MEDIA}" "${FAKE_XDG}"

python3 - "${COLLECTION}" <<'PY'
import sqlite3
import sys

collection = sys.argv[1]
conn = sqlite3.connect(collection)
try:
    conn.execute("CREATE TABLE col (decks TEXT)")
    conn.execute(
        "CREATE TABLE decks (id INTEGER PRIMARY KEY, name TEXT NOT NULL, mtime_secs INTEGER NOT NULL, usn INTEGER NOT NULL, common BLOB NOT NULL, kind BLOB NOT NULL)"
    )
    conn.execute("CREATE TABLE notes (id INTEGER PRIMARY KEY)")
    conn.execute("CREATE TABLE cards (id INTEGER PRIMARY KEY, nid INTEGER, did INTEGER)")
    conn.execute("INSERT INTO col (decks) VALUES (?)", ("",))
    conn.executemany(
        "INSERT INTO decks (id, name, mtime_secs, usn, common, kind) VALUES (?, ?, ?, ?, ?, ?)",
        [
            (1001, "Anki Deck1", 1700000000, -1, b"", b""),
            (1002, "Anki Deck2", 1700000001, -1, b"", b""),
        ],
    )
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

printf 'fake image bytes\n' > "${MEDIA}/diagram.png"

HOME="${FAKE_HOME}" \
XDG_DATA_HOME="${FAKE_XDG}" \
python3 "${HELPER}" --json-only > "${OUT}"

python3 - "${OUT}" "${FAKE_HOME}" <<'PY'
import json
import sys
from pathlib import Path

out_path = Path(sys.argv[1])
fake_home = Path(sys.argv[2])
data = json.loads(out_path.read_text())

assert data["tool"] == "apc_anki_readonly_discovery", data
assert data["status"] == "ok", data
assert data["anki_running"] is False, data
assert data["safety"]["writes_performed"] is False, data
assert data["safety"]["collection_writes_allowed"] is False, data
assert data["safety"]["media_writes_allowed"] is False, data

profiles = data["profiles"]
assert len(profiles) == 1, profiles

profile = profiles[0]
assert profile["read_sqlite"] is True, profile
assert str(profile["profile_path"]).startswith(str(fake_home)), profile
assert "/home/alex/.local/share/Anki2" not in str(profile), profile
assert profile["media_present"] is True, profile
assert profile["media_file_count"] == 1, profile
assert profile["deck_count"] == 2, profile
assert profile["total_card_count"] == 3, profile
assert profile["total_note_count"] == 3, profile

decks = {deck["name"]: deck for deck in profile["decks"]}
assert decks["Anki Deck1"]["card_count"] == 2, decks
assert decks["Anki Deck1"]["note_count"] == 2, decks
assert decks["Anki Deck2"]["card_count"] == 1, decks
assert decks["Anki Deck2"]["note_count"] == 1, decks
assert decks["Anki Deck1"]["media_present_in_profile"] is True, decks
assert "col.decks is empty" not in profile.get("warnings", []), profile

print("PASS: Stage 17B Anki2 read-only discovery helper smoke passed")
PY
