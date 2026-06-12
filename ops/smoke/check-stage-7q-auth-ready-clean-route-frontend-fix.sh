#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7Q smoke: auth-ready clean route frontend fix ==="

test -f frontend/wrapper-ui/app.js
test -f frontend/wrapper-ui/index.html
test -f docs/stage-7q-auth-ready-clean-route-frontend-fix.md

python3 - <<'PY'
from pathlib import Path

s = Path("frontend/wrapper-ui/app.js").read_text()
html = Path("frontend/wrapper-ui/index.html").read_text()

required = [
    "function normalizeWrapperAuthRoute(path) {",
    "function rerenderCurrentRouteAfterAuthReady() {",
    'const path = normalizeWrapperAuthRoute(window.location.pathname || "/");',
]

missing = [item for item in required if item not in s]
if missing:
    raise SystemExit("FAIL: missing required app.js markers: " + ", ".join(missing))

start = s.find("function rerenderCurrentRouteAfterAuthReady() {")
if start < 0:
    raise SystemExit("FAIL: rerenderCurrentRouteAfterAuthReady missing")

end = s.find("\nfunction hasActiveWrapperSession()", start)
if end < 0:
    raise SystemExit("FAIL: could not locate end of auth rerender helper")

block = s[start:end]

if "cleanRoute(" in block:
    raise SystemExit("FAIL: rerenderCurrentRouteAfterAuthReady still calls cleanRoute")

if "app.js?v=20260612140700" not in html:
    raise SystemExit("FAIL: wrapper index did not get Stage 7Q app.js cache version")

print("OK: auth-ready rerender uses scoped normalizer and cache version is bumped")
PY

echo "OK: Stage 7Q smoke passed"
