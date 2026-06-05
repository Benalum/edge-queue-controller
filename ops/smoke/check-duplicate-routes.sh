#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from collections import defaultdict

from edge_controller import app

seen = defaultdict(list)

for route in app.routes:
    path = getattr(route, "path", None)
    methods = sorted(getattr(route, "methods", []) or [])
    endpoint = getattr(route, "endpoint", None)
    endpoint_name = getattr(endpoint, "__name__", str(endpoint))

    if not path or not methods:
        continue

    for method in methods:
        if method in {"HEAD", "OPTIONS"}:
            continue
        seen[(method, path)].append(endpoint_name)

duplicates = {
    key: endpoints
    for key, endpoints in seen.items()
    if len(endpoints) > 1
}

if duplicates:
    print("ERROR: duplicate route registrations found:")
    for (method, path), endpoints in sorted(duplicates.items()):
        print(f"{method:6} {path}")
        for endpoint in endpoints:
            print(f"  - {endpoint}")
    raise SystemExit(1)

print("PASS: no duplicate route registrations")
PY
