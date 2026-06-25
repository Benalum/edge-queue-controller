#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bj-companion-structural-minimal-source.md"
APP_JS="frontend/wrapper-ui/app.js"
STYLE_CSS="frontend/wrapper-ui/styles.css"

test -f "$DOC"
test -f "$APP_JS"
test -f "$STYLE_CSS"

grep -Fq "Stage 16 FC-O45-E-BJ-R4" "$DOC"
grep -Fq "NO live deploy" "$DOC"
grep -Fq "NO public \`/var/www\` mutation" "$DOC"
grep -Fq "Preserve existing queued-chat IDs/classes" "$DOC"
grep -Fq "FC-O45-E-BK" "$DOC"

grep -Fq "Stage 16 FC-O45-E-BJ-R4 Companion structural minimal source" "$APP_JS"
grep -Fq "Stage 16 FC-O45-E-BJ-R4 Companion structural minimal early flag" "$APP_JS"
grep -Fq "window.apcCompanionStructuralMinimalWorkspace" "$APP_JS"
grep -Fq "stage16FcO45EBjR4CompanionStructuralMinimalRuntime" "$APP_JS"
grep -Fq "stage16-fc-o45-e-bj-companion-minimal" "$APP_JS"
grep -Fq "queuedChatForm" "$APP_JS"
grep -Fq "queuedChatMessages" "$APP_JS"
grep -Fq "queuedChatInput" "$APP_JS"
grep -Fq "queuedChatSendBtn" "$APP_JS"
grep -Fq "queuedChatClearBtn" "$APP_JS"
grep -Fq "requestSubmit" "$APP_JS"
grep -Fq "Type a message and press Enter to send." "$APP_JS"

grep -Fq "Stage 16 FC-O45-E-BJ-R4 Companion structural minimal CSS" "$STYLE_CSS"
grep -Fq ".stage16-fc-o45-e-bj-companion-minimal" "$STYLE_CSS"

if command -v node >/dev/null 2>&1; then
  node --check "$APP_JS"
fi

python3 - <<'PY'
from pathlib import Path

text = Path("frontend/wrapper-ui/app.js").read_text()

def find_function_span(src: str, name: str):
    needle = f"function {name}("
    start = src.find(needle)
    if start < 0:
        raise SystemExit(f"missing {name}")
    brace = src.find("{", start)
    depth = 0
    in_s = in_d = in_t = False
    esc = False
    i = brace
    while i < len(src):
        ch = src[i]
        if esc:
            esc = False
        elif ch == "\\":
            esc = True
        elif in_s:
            if ch == "'": in_s = False
        elif in_d:
            if ch == '"': in_d = False
        elif in_t:
            if ch == "`": in_t = False
        else:
            if ch == "'": in_s = True
            elif ch == '"': in_d = True
            elif ch == "`": in_t = True
            elif ch == "{": depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    return start, i + 1
        i += 1
    raise SystemExit(f"unterminated {name}")

start, end = find_function_span(text, "renderQueuedChatPage")
body = text[start:end]

required = [
    "Stage 16 FC-O45-E-BJ-R4 Companion structural minimal source",
    "queuedChatMessages",
    "queuedChatInput",
    "queuedChatSendBtn",
    "queuedChatClearBtn",
    "Type a message and press Enter to send.",
]
for item in required:
    if item not in body:
        raise SystemExit(f"required missing from render body: {item}")

forbidden = [
    "Supportive chat workspace",
    "Companion result reader",
    "Study phrases",
    "Use natural phrases with Companion",
    "Debug details",
    "Thinking",
    "stage5p8h-status-rail",
    "queuedChatPrompt",
    "queuedChatConversation",
    "queuedChatSubmit",
]
for item in forbidden:
    if item in body:
        raise SystemExit(f"forbidden legacy/new-broken item present in render body: {item}")

early_flag = text.find("Stage 16 FC-O45-E-BJ-R4 Companion structural minimal early flag")
old_runtime_positions = [
    text.find("(function stage16FcO45EAtWireCompanionImmersionPanel()"),
    text.find("(function stage16FcO45EAzCompanionImmersionPrimaryWorkspace()"),
    text.find("(function stage16FcO45EBbCompanionCleanChatWorkspace()"),
]
old_runtime_positions = [idx for idx in old_runtime_positions if idx >= 0]
if not old_runtime_positions:
    raise SystemExit("old runtime positions missing")
if early_flag < 0 or early_flag > min(old_runtime_positions):
    raise SystemExit("structural flag is not before old Companion runtime IIFEs")

print("PASS: renderQueuedChatPage structural minimal body excludes legacy copy and preserves existing IDs")
print("PASS: structural minimal flag is before old Companion runtime IIFEs")
PY

echo "PASS: Stage 16 FC-O45-E-BJ-R4 Companion structural minimal source smoke"
