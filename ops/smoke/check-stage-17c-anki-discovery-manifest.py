#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
MANIFEST = REPO_ROOT / "ops" / "anki" / "anki_discovery_manifest.py"


def run_cmd(args: list[str]) -> None:
    subprocess.run(args, check=True)


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        tmp_dir = Path(tmp)
        discovery_path = tmp_dir / "discovery.json"
        manifest_path = tmp_dir / "manifest.json"
        manifest_paths_path = tmp_dir / "manifest-with-paths.json"

        discovery = {
            "tool": "apc_anki_readonly_discovery",
            "schema_version": 1,
            "status": "ok",
            "system": "linux",
            "platform_system": "Linux",
            "anki_running": False,
            "profiles": [
                {
                    "name": "User 1",
                    "profile_path": "/home/example/.local/share/Anki2/User 1",
                    "collection_path": "/home/example/.local/share/Anki2/User 1/collection.anki2",
                    "collection_exists": True,
                    "collection_size_bytes": 139264,
                    "collection_mtime_epoch": 1782669654,
                    "media_path": "/home/example/.local/share/Anki2/User 1/collection.media",
                    "media_present": True,
                    "media_file_count": 1,
                    "read_sqlite": True,
                    "sqlite_blocked_reason": None,
                    "deck_count": 2,
                    "total_card_count": 3,
                    "total_note_count": 3,
                    "decks": [
                        {
                            "id": "1",
                            "name": "Anki Deck1",
                            "card_count": 2,
                            "note_count": 2,
                            "media_present_in_profile": True,
                        },
                        {
                            "id": "1782669587926",
                            "name": "Anki Deck2",
                            "card_count": 1,
                            "note_count": 1,
                            "media_present_in_profile": True,
                        },
                    ],
                    "warnings": [],
                }
            ],
            "safety": {
                "writes_performed": False,
                "collection_writes_allowed": False,
                "media_writes_allowed": False,
                "import_export_performed": False,
            },
            "warnings": [],
        }

        discovery_path.write_text(json.dumps(discovery, indent=2), encoding="utf-8")

        run_cmd([
            sys.executable,
            str(MANIFEST),
            "--input",
            str(discovery_path),
            "--output",
            str(manifest_path),
        ])

        data = json.loads(manifest_path.read_text(encoding="utf-8"))

        assert data["tool"] == "apc_anki_discovery_manifest", data
        assert data["schema_version"] == 1, data
        assert data["status"] == "ok", data
        assert data["source"]["tool"] == "apc_anki_readonly_discovery", data
        assert data["source"]["anki_running"] is False, data
        assert data["safety"]["writes_performed"] is False, data
        assert data["safety"]["anki_writes_allowed"] is False, data
        assert data["safety"]["media_copied"] is False, data
        assert data["safety"]["cards_imported"] is False, data
        assert data["summary"]["profile_count"] == 1, data
        assert data["summary"]["deck_count"] == 2, data
        assert data["summary"]["card_count"] == 3, data
        assert data["summary"]["note_count"] == 3, data
        assert data["summary"]["media_file_count"] == 1, data

        profile = data["profiles"][0]
        assert profile["profile_name"] == "User 1", profile
        assert profile["read_sqlite"] is True, profile
        assert profile["media_present"] is True, profile
        assert "local_paths" not in profile, profile

        decks = {deck["name"]: deck for deck in profile["decks"]}
        assert decks["Anki Deck1"]["card_count"] == 2, decks
        assert decks["Anki Deck1"]["note_count"] == 2, decks
        assert decks["Anki Deck1"]["media_present"] is True, decks
        assert decks["Anki Deck1"]["apc_cards_imported"] is False, decks
        assert decks["Anki Deck1"]["media_copied"] is False, decks
        assert decks["Anki Deck2"]["card_count"] == 1, decks
        assert decks["Anki Deck2"]["note_count"] == 1, decks

        text = manifest_path.read_text(encoding="utf-8")
        assert "/home/example" not in text, text

        print("PASS: Stage 17C Anki discovery manifest smoke passed")

        run_cmd([
            sys.executable,
            str(MANIFEST),
            "--input",
            str(discovery_path),
            "--output",
            str(manifest_paths_path),
            "--include-local-paths",
        ])

        with_paths = json.loads(manifest_paths_path.read_text(encoding="utf-8"))
        profile_with_paths = with_paths["profiles"][0]
        assert "local_paths" in profile_with_paths, profile_with_paths
        assert profile_with_paths["local_paths"]["collection_path"].endswith("collection.anki2"), profile_with_paths

        print("PASS: Stage 17C optional local paths smoke passed")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
