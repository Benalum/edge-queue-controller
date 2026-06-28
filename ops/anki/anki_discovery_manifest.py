#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import sys
from pathlib import Path
from typing import Any, Dict, List

TOOL_NAME = "apc_anki_discovery_manifest"
SCHEMA_VERSION = 1


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def stable_hash(value: str, length: int = 16) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()[:length]


def as_bool(value: Any) -> bool:
    return bool(value) if value is not None else False


def as_int(value: Any) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


def load_json(path: str) -> Dict[str, Any]:
    raw = sys.stdin.read() if path == "-" else Path(path).read_text(encoding="utf-8")
    data = json.loads(raw)
    if not isinstance(data, dict):
        raise SystemExit("ERROR: input JSON must be an object")
    return data


def write_json(path: str, data: Dict[str, Any]) -> None:
    text = json.dumps(data, indent=2, sort_keys=True) + "\n"
    if path == "-":
        sys.stdout.write(text)
        return
    out = Path(path)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(text, encoding="utf-8")


def make_profile_manifest(profile: Dict[str, Any], include_local_paths: bool) -> Dict[str, Any]:
    profile_name = str(profile.get("name") or "unknown")
    collection_path = str(profile.get("collection_path") or "")

    source_key = "|".join([
        profile_name,
        collection_path,
        str(profile.get("collection_size_bytes") or ""),
        str(profile.get("collection_mtime_epoch") or ""),
    ])
    profile_id = stable_hash(source_key)

    decks: List[Dict[str, Any]] = []
    for deck in profile.get("decks") or []:
        if not isinstance(deck, dict):
            continue

        source_deck_id = str(deck.get("id") or "")
        name = str(deck.get("name") or source_deck_id or "Unnamed deck")
        card_count = as_int(deck.get("card_count"))
        note_count = as_int(deck.get("note_count"))

        decks.append({
            "manifest_deck_id": stable_hash(profile_id + "|" + source_deck_id + "|" + name),
            "source_deck_id": source_deck_id,
            "name": name,
            "card_count": card_count,
            "note_count": note_count,
            "media_present": as_bool(deck.get("media_present_in_profile")),
            "import_status": "available" if card_count > 0 or note_count > 0 else "empty",
            "apc_cards_imported": False,
            "media_copied": False,
        })

    result: Dict[str, Any] = {
        "manifest_profile_id": profile_id,
        "profile_name": profile_name,
        "collection_exists": as_bool(profile.get("collection_exists")),
        "collection_size_bytes": as_int(profile.get("collection_size_bytes")),
        "collection_mtime_epoch": profile.get("collection_mtime_epoch"),
        "read_sqlite": as_bool(profile.get("read_sqlite")),
        "sqlite_blocked_reason": profile.get("sqlite_blocked_reason"),
        "deck_count": len(decks),
        "total_card_count": as_int(profile.get("total_card_count")),
        "total_note_count": as_int(profile.get("total_note_count")),
        "media_present": as_bool(profile.get("media_present")),
        "media_file_count": as_int(profile.get("media_file_count")),
        "decks": decks,
        "warnings": list(profile.get("warnings") or []),
    }

    if include_local_paths:
        result["local_paths"] = {
            "profile_path": str(profile.get("profile_path") or ""),
            "collection_path": collection_path,
            "media_path": str(profile.get("media_path") or ""),
        }

    return result


def build_manifest(discovery: Dict[str, Any], include_local_paths: bool) -> Dict[str, Any]:
    warnings: List[str] = []

    if discovery.get("tool") != "apc_anki_readonly_discovery":
        warnings.append("input tool was not apc_anki_readonly_discovery")

    safety = discovery.get("safety") or {}
    if safety.get("writes_performed") is not False:
        warnings.append("input discovery did not explicitly report writes_performed=false")

    profiles = [
        make_profile_manifest(profile, include_local_paths)
        for profile in (discovery.get("profiles") or [])
        if isinstance(profile, dict)
    ]

    status = "ok"
    if discovery.get("status") == "blocked":
        status = "blocked"
    elif not profiles:
        status = "not_found"

    return {
        "tool": TOOL_NAME,
        "schema_version": SCHEMA_VERSION,
        "created_at": utc_now(),
        "status": status,
        "source": {
            "tool": discovery.get("tool"),
            "schema_version": discovery.get("schema_version"),
            "status": discovery.get("status"),
            "system": discovery.get("system"),
            "platform_system": discovery.get("platform_system"),
            "anki_running": as_bool(discovery.get("anki_running")),
        },
        "profiles": profiles,
        "summary": {
            "profile_count": len(profiles),
            "deck_count": sum(as_int(p.get("deck_count")) for p in profiles),
            "card_count": sum(as_int(p.get("total_card_count")) for p in profiles),
            "note_count": sum(as_int(p.get("total_note_count")) for p in profiles),
            "media_file_count": sum(as_int(p.get("media_file_count")) for p in profiles),
        },
        "safety": {
            "mode": "apc_manifest_from_read_only_discovery",
            "anki_writes_allowed": False,
            "collection_writes_allowed": False,
            "media_writes_allowed": False,
            "destructive_actions_allowed": False,
            "cards_imported": False,
            "media_copied": False,
            "collection_copied": False,
            "apkg_import_performed": False,
            "colpkg_import_performed": False,
            "writes_performed": False,
        },
        "warnings": warnings + list(discovery.get("warnings") or []),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Build APC Anki discovery manifest from read-only discovery JSON.")
    parser.add_argument("--input", "-i", default="-", help="Discovery JSON path, or '-' for stdin.")
    parser.add_argument("--output", "-o", default="-", help="Manifest JSON path, or '-' for stdout.")
    parser.add_argument("--include-local-paths", action="store_true", help="Include local paths for local-only debugging.")
    args = parser.parse_args()

    manifest = build_manifest(load_json(args.input), include_local_paths=args.include_local_paths)
    write_json(args.output, manifest)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
