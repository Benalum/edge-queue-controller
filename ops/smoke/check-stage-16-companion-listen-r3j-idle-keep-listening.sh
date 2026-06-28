#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPANION="$REPO/frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js"
INDEX="$REPO/frontend/wrapper-ui/apc-wrapper-local/index.html"

test -f "$COMPANION"
test -f "$INDEX"

if command -v node >/dev/null 2>&1; then
  node --check "$COMPANION"
fi

grep -q "Companion Listen Idle R3J" "$COMPANION"
grep -q "function clearBrowserListenRestartTimer" "$COMPANION"
grep -q "function browserListenShouldKeepWaiting" "$COMPANION"
grep -q "function scheduleBrowserListenRestart" "$COMPANION"
grep -q 'error === "no-speech"' "$COMPANION"
grep -q "listen-r3j-idle-keep-listening-20260627" "$INDEX"

python3 - <<'PY'
from pathlib import Path
import os

repo = Path(os.environ.get("REPO", "."))
companion = repo / "frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js"
text = companion.read_text()

bad_exact = """      recognitionInstance.start();
      render();
      scheduleBrowserListenSilence();"""

if bad_exact in text:
    raise SystemExit("initial silence timer still starts immediately after recognition start")
PY

echo "companion listen R3J idle keep-listening smoke PASS"
