#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
import ast
from pathlib import Path

path = Path("edge_controller.py")
tree = ast.parse(path.read_text())

watched = {
    "_companion_build_study_context",
    "_companion_build_calendar_context",
    "_companion_build_context",
    "_companion_prompt_from_context",
}

locations = {name: [] for name in watched}

for node in tree.body:
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name in watched:
        locations[node.name].append(node.lineno)

duplicates = {name: lines for name, lines in locations.items() if len(lines) > 1}
missing = {name: lines for name, lines in locations.items() if len(lines) == 0}

if duplicates or missing:
    if duplicates:
        print("ERROR: duplicate companion helper definitions found:")
        for name, lines in sorted(duplicates.items()):
            print(f"  {name}: lines {', '.join(map(str, lines))}")

    if missing:
        print("ERROR: missing companion helper definitions:")
        for name in sorted(missing):
            print(f"  {name}")

    raise SystemExit(1)

print("PASS: companion helper definitions are unique")
PY
