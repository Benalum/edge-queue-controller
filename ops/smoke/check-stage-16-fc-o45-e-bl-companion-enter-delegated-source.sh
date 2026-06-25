#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bl-companion-enter-delegated-source.md"
APP_JS="frontend/wrapper-ui/app.js"

test -f "$DOC"
test -f "$APP_JS"

grep -Fq "Stage 16 FC-O45-E-BL" "$DOC"
grep -Fq "NO live deploy" "$DOC"
grep -Fq "NO model/helper/Ollama call" "$DOC"
grep -Fq "mock/no-model" "$DOC"

grep -Fq "Stage 16 FC-O45-E-BL Companion delegated Enter-to-send source" "$APP_JS"
grep -Fq "stage16FcO45EBlCompanionDelegatedEnterToSend" "$APP_JS"
grep -Fq "window.apcCompanionDelegatedEnterToSend" "$APP_JS"
grep -Fq 'target.id !== "queuedChatInput"' "$APP_JS"
grep -Fq 'document.getElementById("queuedChatForm")' "$APP_JS"
grep -Fq 'document.getElementById("queuedChatSendBtn")' "$APP_JS"
grep -Fq "requestSubmit" "$APP_JS"

if command -v node >/dev/null 2>&1; then
  node --check "$APP_JS"
fi

python3 - <<'PY'
from pathlib import Path
text = Path("frontend/wrapper-ui/app.js").read_text()
start = text.find("Stage 16 FC-O45-E-BL Companion delegated Enter-to-send source")
if start < 0:
    raise SystemExit("BL marker missing")
tail = text[start:]
if "new MutationObserver" in tail:
    raise SystemExit("BL added MutationObserver")
for item in [
    'event.key !== "Enter"',
    "event.shiftKey",
    'target.id !== "queuedChatInput"',
    'document.getElementById("queuedChatForm")',
]:
    if item not in tail:
        raise SystemExit(f"BL delegated handler missing {item}")
print("PASS: BL delegated Enter-to-send source has no MutationObserver")
PY

echo "PASS: Stage 16 FC-O45-E-BL Companion delegated Enter-to-send source smoke"
