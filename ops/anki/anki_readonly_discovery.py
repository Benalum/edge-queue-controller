#!/usr/bin/env python3
"""APC Anki2 read-only discovery helper.

This helper discovers local Anki profile folders and, only when Anki appears
closed, reads deck/card/note metadata from collection.anki2 using SQLite
read-only mode. It never writes, deletes, imports, exports, or copies user data.
"""

from __future__ import annotations

import argparse
import csv
import io
import json
import os
import platform
import sqlite3
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Sequence, Tuple

TOOL_NAME = "apc_anki_readonly_discovery"
SCHEMA_VERSION = 1

ANKI_PROCESS_NAMES = {
    "anki",
    "anki-bin",
    "anki.exe",
    "anki-console",
    "anki-console.exe",
}
SELF_MARKERS = {
    "anki_readonly_discovery.py",
    "check-stage-17b-anki2-read-only-discovery.sh",
}


def normalize_system(value: Optional[str] = None) -> str:
    raw = (value or platform.system() or "unknown").strip().lower()
    if raw == "darwin":
        return "macos"
    if raw.startswith("win"):
        return "windows"
    if raw == "linux":
        return "linux"
    return raw or "unknown"


def path_str(path: Path) -> str:
    return str(path.expanduser())


def unique_paths(paths: Iterable[Path]) -> List[Path]:
    seen = set()
    unique: List[Path] = []
    for raw in paths:
        try:
            path = raw.expanduser()
        except RuntimeError:
            path = raw
        key = os.path.normcase(os.path.abspath(os.fspath(path)))
        if key not in seen:
            seen.add(key)
            unique.append(path)
    return unique


def candidate_anki_roots(extra_roots: Optional[Sequence[str]] = None) -> List[Path]:
    """Return OS-specific Anki2 roots, plus any user-supplied overrides."""
    roots: List[Path] = []
    for item in extra_roots or []:
        roots.append(Path(item))

    system = normalize_system()
    home = Path.home()

    if system == "linux":
        anki_base = os.environ.get("ANKI_BASE")
        if anki_base:
            roots.append(Path(anki_base))

        xdg_data_home = os.environ.get("XDG_DATA_HOME")
        if xdg_data_home:
            roots.append(Path(xdg_data_home) / "Anki2")

        roots.extend(
            [
                home / ".local" / "share" / "Anki2",
                home / ".var" / "app" / "net.ankiweb.Anki" / "data" / "Anki2",
            ]
        )
    elif system == "macos":
        anki_base = os.environ.get("ANKI_BASE")
        if anki_base:
            roots.append(Path(anki_base))
        roots.append(home / "Library" / "Application Support" / "Anki2")
    elif system == "windows":
        anki_base = os.environ.get("ANKI_BASE")
        if anki_base:
            roots.append(Path(anki_base))
        appdata = os.environ.get("APPDATA")
        if appdata:
            roots.append(Path(appdata) / "Anki2")
        localappdata = os.environ.get("LOCALAPPDATA")
        if localappdata:
            # Not the usual Anki data root, but useful for unusual installs.
            roots.append(Path(localappdata) / "Anki2")
    else:
        anki_base = os.environ.get("ANKI_BASE")
        if anki_base:
            roots.append(Path(anki_base))
        roots.append(home / "Anki2")

    return unique_paths(roots)


def safe_stat(path: Path) -> Dict[str, Any]:
    try:
        st = path.stat()
    except OSError as exc:
        return {"exists": False, "error": str(exc)}
    return {
        "exists": True,
        "size_bytes": st.st_size,
        "mtime_epoch": int(st.st_mtime),
    }


def count_files(path: Path) -> Tuple[Optional[int], Optional[str]]:
    if not path.exists():
        return 0, None
    if not path.is_dir():
        return None, "media path exists but is not a directory"
    count = 0
    try:
        for item in path.iterdir():
            try:
                if item.is_file():
                    count += 1
            except OSError:
                continue
    except OSError as exc:
        return None, str(exc)
    return count, None


def command_basename(command: str) -> str:
    cleaned = command.strip().strip('"').strip("'")
    if not cleaned:
        return ""
    return Path(cleaned).name.lower()


def looks_like_self(cmdline: str) -> bool:
    lowered = cmdline.lower()
    return any(marker.lower() in lowered for marker in SELF_MARKERS)


def command_looks_like_anki(comm: str, cmdline_parts: Sequence[str]) -> bool:
    comm_base = command_basename(comm)
    if comm_base in ANKI_PROCESS_NAMES:
        return True

    if cmdline_parts:
        first_base = command_basename(cmdline_parts[0])
        if first_base in ANKI_PROCESS_NAMES:
            return True

    joined = " ".join(cmdline_parts).lower()
    if not joined or looks_like_self(joined):
        return False

    # Flatpak and macOS app bundle signatures that avoid matching this helper.
    signatures = [
        "net.ankiweb.anki",
        "/anki.app/",
        "\\anki.exe",
        "/bin/anki",
        "/app/bin/anki",
    ]
    return any(sig in joined for sig in signatures)


def detect_anki_running_linux() -> Tuple[bool, List[Dict[str, Any]], List[str]]:
    proc = Path("/proc")
    matches: List[Dict[str, Any]] = []
    warnings: List[str] = []
    if not proc.exists():
        return False, matches, ["/proc is unavailable; unable to inspect Linux processes"]

    for entry in proc.iterdir():
        if not entry.name.isdigit():
            continue
        comm = ""
        cmdline_parts: List[str] = []
        try:
            comm = (entry / "comm").read_text(errors="replace").strip()
        except OSError:
            pass
        try:
            raw = (entry / "cmdline").read_bytes()
            cmdline_parts = [part.decode("utf-8", "replace") for part in raw.split(b"\0") if part]
        except OSError:
            pass
        if command_looks_like_anki(comm, cmdline_parts):
            matches.append(
                {
                    "pid": int(entry.name),
                    "comm": comm,
                    "cmdline_preview": " ".join(cmdline_parts)[:240],
                }
            )
    return bool(matches), matches, warnings


def detect_anki_running_ps() -> Tuple[bool, List[Dict[str, Any]], List[str]]:
    warnings: List[str] = []
    matches: List[Dict[str, Any]] = []
    try:
        proc = subprocess.run(
            ["ps", "-axo", "pid=,comm=,args="],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=5,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        return False, matches, [f"process inspection failed: {exc}"]

    if proc.returncode != 0:
        return False, matches, [f"ps returned {proc.returncode}: {proc.stderr.strip()[:200]}"]

    for line in proc.stdout.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        parts = stripped.split(None, 2)
        if len(parts) < 2:
            continue
        pid = parts[0]
        comm = parts[1]
        args = parts[2] if len(parts) > 2 else ""
        if looks_like_self(args):
            continue
        if command_looks_like_anki(comm, args.split() if args else [comm]):
            try:
                pid_value: Any = int(pid)
            except ValueError:
                pid_value = pid
            matches.append({"pid": pid_value, "comm": comm, "cmdline_preview": args[:240]})
    return bool(matches), matches, warnings


def detect_anki_running_windows() -> Tuple[bool, List[Dict[str, Any]], List[str]]:
    warnings: List[str] = []
    matches: List[Dict[str, Any]] = []
    try:
        proc = subprocess.run(
            ["tasklist", "/fo", "csv", "/nh"],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=8,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        return False, matches, [f"process inspection failed: {exc}"]

    if proc.returncode != 0:
        return False, matches, [f"tasklist returned {proc.returncode}: {proc.stderr.strip()[:200]}"]

    reader = csv.reader(io.StringIO(proc.stdout))
    for row in reader:
        if not row:
            continue
        image_name = row[0].strip()
        if image_name.lower() in ANKI_PROCESS_NAMES:
            matches.append({"image_name": image_name, "pid": row[1] if len(row) > 1 else None})
    return bool(matches), matches, warnings


def detect_anki_running() -> Tuple[bool, List[Dict[str, Any]], List[str]]:
    system = normalize_system()
    if system == "linux":
        return detect_anki_running_linux()
    if system == "macos":
        return detect_anki_running_ps()
    if system == "windows":
        return detect_anki_running_windows()
    return False, [], [f"unsupported system for Anki process detection: {system}"]


def discover_profile_paths(root: Path) -> List[Path]:
    try:
        root = root.expanduser()
    except RuntimeError:
        pass
    profiles: List[Path] = []
    if (root / "collection.anki2").is_file():
        profiles.append(root)
        return profiles
    if not root.is_dir():
        return profiles
    try:
        for child in sorted(root.iterdir(), key=lambda p: p.name.lower()):
            if child.is_dir() and (child / "collection.anki2").is_file():
                profiles.append(child)
    except OSError:
        return profiles
    return profiles


def table_exists(conn: sqlite3.Connection, table_name: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=? LIMIT 1",
        (table_name,),
    ).fetchone()
    return row is not None


def read_decks_table(conn: sqlite3.Connection) -> Tuple[Dict[str, Dict[str, Any]], List[str]]:
    """Read modern Anki normalized decks table when available."""
    warnings: List[str] = []
    decks_by_id: Dict[str, Dict[str, Any]] = {}
    if not table_exists(conn, "decks"):
        return decks_by_id, ["modern decks table missing"]
    try:
        rows = conn.execute(
            "SELECT CAST(id AS TEXT), name FROM decks ORDER BY name COLLATE NOCASE"
        ).fetchall()
    except sqlite3.Error as exc:
        return decks_by_id, [f"unable to read modern decks table: {exc}"]

    for deck_id, name in rows:
        deck_id_str = str(deck_id)
        deck_name = str(name or deck_id_str)
        decks_by_id[deck_id_str] = {
            "id": deck_id_str,
            "name": deck_name,
            "card_count": 0,
            "note_count": 0,
        }
    if not decks_by_id:
        warnings.append("modern decks table is empty")
    return decks_by_id, warnings


def read_decks_json(conn: sqlite3.Connection) -> Tuple[Dict[str, Dict[str, Any]], List[str]]:
    warnings: List[str] = []
    decks_by_id: Dict[str, Dict[str, Any]] = {}
    if not table_exists(conn, "col"):
        return decks_by_id, ["missing col table"]
    try:
        row = conn.execute("SELECT decks FROM col LIMIT 1").fetchone()
    except sqlite3.Error as exc:
        return decks_by_id, [f"unable to read col.decks: {exc}"]
    if not row or row[0] in (None, ""):
        return decks_by_id, ["col.decks is empty"]
    try:
        raw = json.loads(row[0])
    except json.JSONDecodeError as exc:
        return decks_by_id, [f"col.decks JSON decode failed: {exc}"]
    if not isinstance(raw, dict):
        return decks_by_id, ["col.decks JSON was not an object"]
    for key, value in raw.items():
        if not isinstance(value, dict):
            continue
        deck_id = str(value.get("id", key))
        name = str(value.get("name", deck_id))
        decks_by_id[deck_id] = {
            "id": deck_id,
            "name": name,
            "card_count": 0,
            "note_count": 0,
        }
    return decks_by_id, warnings

def read_count_map(conn: sqlite3.Connection, sql: str) -> Tuple[Dict[str, int], Optional[str]]:
    counts: Dict[str, int] = {}
    try:
        rows = conn.execute(sql).fetchall()
    except sqlite3.Error as exc:
        return counts, str(exc)
    for deck_id, count in rows:
        counts[str(deck_id)] = int(count or 0)
    return counts, None


def read_collection_metadata(collection_path: Path, media_file_count: Optional[int]) -> Tuple[Dict[str, Any], List[str]]:
    warnings: List[str] = []
    metadata: Dict[str, Any] = {
        "read_sqlite": False,
        "decks": [],
        "deck_count": 0,
        "total_card_count": 0,
        "total_note_count": 0,
        "sqlite_tables_present": [],
    }

    try:
        uri = collection_path.resolve().as_uri() + "?mode=ro"
    except ValueError:
        uri = "file:" + str(collection_path) + "?mode=ro"

    try:
        conn = sqlite3.connect(uri, uri=True)
    except sqlite3.Error as exc:
        warnings.append(f"unable to open collection.anki2 read-only: {exc}")
        metadata["sqlite_error"] = str(exc)
        return metadata, warnings

    try:
        conn.execute("PRAGMA query_only=ON")
        tables = [
            row[0]
            for row in conn.execute(
                "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
            ).fetchall()
        ]
        metadata["sqlite_tables_present"] = tables

        decks_by_id, deck_warnings = read_decks_table(conn)
        if not decks_by_id:
            fallback_decks_by_id, fallback_warnings = read_decks_json(conn)
            decks_by_id = fallback_decks_by_id
            warnings.extend(deck_warnings)
            warnings.extend(fallback_warnings)
        else:
            warnings.extend(deck_warnings)

        if table_exists(conn, "cards"):
            card_counts, card_err = read_count_map(
                conn, "SELECT did, COUNT(*) FROM cards GROUP BY did"
            )
            if card_err:
                warnings.append(f"unable to count cards by deck: {card_err}")
            for deck_id, count in card_counts.items():
                decks_by_id.setdefault(
                    deck_id,
                    {"id": deck_id, "name": deck_id, "card_count": 0, "note_count": 0},
                )["card_count"] = count

            if table_exists(conn, "notes"):
                note_counts, note_err = read_count_map(
                    conn,
                    "SELECT cards.did, COUNT(DISTINCT notes.id) "
                    "FROM cards JOIN notes ON cards.nid = notes.id GROUP BY cards.did",
                )
            else:
                note_counts, note_err = read_count_map(
                    conn,
                    "SELECT did, COUNT(DISTINCT nid) FROM cards GROUP BY did",
                )
            if note_err:
                warnings.append(f"unable to count notes by deck: {note_err}")
            for deck_id, count in note_counts.items():
                decks_by_id.setdefault(
                    deck_id,
                    {"id": deck_id, "name": deck_id, "card_count": 0, "note_count": 0},
                )["note_count"] = count
        else:
            warnings.append("missing cards table")

        decks = sorted(decks_by_id.values(), key=lambda item: item.get("name", ""))
        media_present = bool(media_file_count and media_file_count > 0)
        for deck in decks:
            deck["media_present_in_profile"] = media_present

        metadata.update(
            {
                "read_sqlite": True,
                "decks": decks,
                "deck_count": len(decks),
                "total_card_count": sum(int(deck.get("card_count") or 0) for deck in decks),
                "total_note_count": sum(int(deck.get("note_count") or 0) for deck in decks),
            }
        )
    except sqlite3.Error as exc:
        warnings.append(f"SQLite metadata read failed: {exc}")
        metadata["sqlite_error"] = str(exc)
    finally:
        conn.close()

    return metadata, warnings


def build_profile_record(profile_path: Path, anki_running: bool, allow_sqlite: bool) -> Dict[str, Any]:
    collection_path = profile_path / "collection.anki2"
    media_path = profile_path / "collection.media"
    collection_stat = safe_stat(collection_path)
    media_file_count, media_error = count_files(media_path)
    warnings: List[str] = []
    if media_error:
        warnings.append(f"media count warning: {media_error}")

    record: Dict[str, Any] = {
        "name": profile_path.name,
        "profile_path": path_str(profile_path),
        "collection_path": path_str(collection_path),
        "collection_exists": collection_path.exists(),
        "collection_size_bytes": collection_stat.get("size_bytes"),
        "collection_mtime_epoch": collection_stat.get("mtime_epoch"),
        "media_path": path_str(media_path),
        "media_present": media_path.is_dir(),
        "media_file_count": media_file_count,
        "read_sqlite": False,
        "sqlite_blocked_reason": None,
        "decks": [],
        "warnings": warnings,
    }

    if not allow_sqlite:
        if anki_running:
            record["sqlite_blocked_reason"] = "Anki appears to be running; close Anki before reading collection.anki2."
        else:
            record["sqlite_blocked_reason"] = "SQLite reads disabled."
        return record

    metadata, read_warnings = read_collection_metadata(collection_path, media_file_count)
    record.update(metadata)
    record["warnings"].extend(read_warnings)
    return record


def run_discovery(extra_roots: Optional[Sequence[str]] = None) -> Dict[str, Any]:
    system = normalize_system()
    anki_running, process_matches, process_warnings = detect_anki_running()
    roots = candidate_anki_roots(extra_roots)

    root_records: List[Dict[str, Any]] = []
    profiles: List[Dict[str, Any]] = []
    seen_profiles = set()

    for root in roots:
        expanded = root.expanduser()
        root_record: Dict[str, Any] = {
            "path": path_str(expanded),
            "exists": expanded.exists(),
            "is_dir": expanded.is_dir(),
            "profile_count": 0,
        }
        profile_paths = discover_profile_paths(expanded)
        root_record["profile_count"] = len(profile_paths)
        root_records.append(root_record)

        for profile_path in profile_paths:
            key = os.path.normcase(os.path.abspath(os.fspath(profile_path)))
            if key in seen_profiles:
                continue
            seen_profiles.add(key)
            profiles.append(build_profile_record(profile_path, anki_running, allow_sqlite=not anki_running))

    warnings = list(process_warnings)
    if anki_running:
        warnings.append("Anki appears to be running; SQLite collection reads were blocked.")

    status = "blocked" if anki_running else "ok"
    if not profiles:
        status = "not_found" if not anki_running else "blocked"

    return {
        "schema_version": SCHEMA_VERSION,
        "tool": TOOL_NAME,
        "status": status,
        "system": system,
        "platform_system": platform.system(),
        "anki_running": anki_running,
        "anki_process_matches": process_matches,
        "roots": root_records,
        "profiles": profiles,
        "warnings": warnings,
        "safety": {
            "mode": "read_only_discovery",
            "writes_performed": False,
            "collection_writes_allowed": False,
            "media_writes_allowed": False,
            "import_export_performed": False,
        },
    }


def parse_args(argv: Optional[Sequence[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Discover Anki2 profiles/deck metadata safely.")
    parser.add_argument(
        "--root",
        action="append",
        default=[],
        help="Additional Anki2 root or direct profile path to inspect. May be passed more than once.",
    )
    parser.add_argument(
        "--json-only",
        action="store_true",
        help="Emit JSON only. This is the default output style and is kept for scripts.",
    )
    return parser.parse_args(argv)


def main(argv: Optional[Sequence[str]] = None) -> int:
    args = parse_args(argv)
    result = run_discovery(args.root)
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
