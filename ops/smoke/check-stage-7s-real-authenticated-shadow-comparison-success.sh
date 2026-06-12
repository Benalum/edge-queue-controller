#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7S smoke: real authenticated shadow comparison success checkpoint ==="

test -f docs/stage-7s-real-authenticated-shadow-comparison-success.md
test -f ops/compare/run-authenticated-shadow-comparison.py
test -f ops/validate/validate-authenticated-shadow-comparison-artifact.py

python3 - <<'PY'
from pathlib import Path

doc = Path("docs/stage-7s-real-authenticated-shadow-comparison-success.md").read_text()
runner = Path("ops/compare/run-authenticated-shadow-comparison.py").read_text()

required_doc_markers = [
    "Stage 7S Real Authenticated Shadow Comparison Success",
    "EDGE_POWER_AUTO_PAUSED=1",
    "/api/study/session/command",
    "/api/companion/chat",
    "Existing route HTTP status: 200",
    "Router dispatch performed: false",
    "Router model call required: false",
    "Raw response stored: false",
    "Secrets stored: false",
    "Safe to continue: true",
    "Power automation remains paused",
]

missing_doc = [item for item in required_doc_markers if item not in doc]
if missing_doc:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing_doc))

required_runner_markers = [
    "EDGE_AUTH_SHADOW_COMPARE_PUBLIC_API_KEY",
    'headers["x-edge-api-key"] = public_api_key',
    'headers["Authorization"] = f"Bearer {bearer}"',
]

missing_runner = [item for item in required_runner_markers if item not in runner]
if missing_runner:
    raise SystemExit("FAIL: missing runner markers: " + ", ".join(missing_runner))

for forbidden in [
    "Authorization: Bearer ",
    "EDGE_PUBLIC_API_KEY=",
    "edgeStudyToken=",
    "postgresql://",
]:
    if forbidden in doc:
        raise SystemExit(f"FAIL: doc contains forbidden secret-like marker: {forbidden}")

print("OK: Stage 7S success checkpoint is documented without stored auth values")
PY

echo
echo "=== verify local generated artifacts are ignored if present ==="
if [ -f ops/compare/output/study-next.manual.local-auth-shadow.json ]; then
  git check-ignore -v ops/compare/output/study-next.manual.local-auth-shadow.json
fi

if [ -f ops/compare/output/companion-chat.manual.local-auth-shadow.json ]; then
  git check-ignore -v ops/compare/output/companion-chat.manual.local-auth-shadow.json
fi

echo "OK: Stage 7S smoke passed"
