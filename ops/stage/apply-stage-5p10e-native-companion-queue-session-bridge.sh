#!/usr/bin/env bash
cd "$HOME/Desktop/edge-queue-controller" || return 1

cp -a .env ".env.bak-stage-5p10e-$(date +%F-%H%M%S)"

python3 - <<'PY'
from pathlib import Path

p = Path(".env")
s = p.read_text() if p.exists() else ""

wanted = {
    "LAPTOP_CHAT_QUEUE_ENABLED": "1",
    "LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED": "1",
    "LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED": "1",
    "LAPTOP_CHAT_QUEUE_REAL_USER_CREATION_HELPER_ENABLED": "1",
}

lines = s.splitlines()
seen = set()
out = []

for line in lines:
    stripped = line.strip()
    if "=" not in stripped or stripped.startswith("#"):
        out.append(line)
        continue

    key = stripped.split("=", 1)[0].strip()
    if key in wanted:
        out.append(f"{key}={wanted[key]}")
        seen.add(key)
    else:
        out.append(line)

if out and out[-1].strip():
    out.append("")

for key, value in wanted.items():
    if key not in seen:
        out.append(f"{key}={value}")

p.write_text("\n".join(out) + "\n")
PY

bash ops/dev/restart-controller-7070.sh || return 1

if bash ops/smoke/check-stage-5p10e-native-companion-queue-session-bridge.sh; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
