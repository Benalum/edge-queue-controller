#!/usr/bin/env bash
set -euo pipefail

cd "$HOME/Desktop/edge-queue-controller"

ok=1
PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
[ -x "$PYBIN" ] || PYBIN="python3"

echo "=== Stage 5P-11T Session Me Presence Touch Smoke ==="

echo
echo "=== syntax ==="
"$PYBIN" -m py_compile edge_controller.py || ok=0

echo
echo "=== marker checks ==="
for item in \
  "STAGE_5P11T_SESSION_ME_PRESENCE_TOUCH_BEGIN" \
  "_stage5p11t_touch_authenticated_web_presence_from_session_me" \
  "session-me-authenticated-touch" \
  "session-me-user-" \
  "STAGE_5P11T_SESSION_ME_PRESENCE_CALL_BEGIN" \
  '"presence_touch": presence_touch'
do
  if grep -Fq "$item" edge_controller.py; then
    echo "OK marker $item"
  else
    echo "FAIL missing marker $item"
    ok=0
  fi
done

echo
echo "=== existing policy markers ==="
for item in \
  "WEB_PRESENCE_CONTAINER_START_DEMAND_V1" \
  "web_presence_container_required" \
  "Logged-in user is active; host must be online or booting."
do
  if grep -Fq "$item" edge_controller.py; then
    echo "OK policy marker $item"
  else
    echo "FAIL missing policy marker $item"
    ok=0
  fi
done

echo
echo "=== route smoke ==="
curl -fsS http://127.0.0.1:7070/system/presence/power-policy >/tmp/stage5p11t-policy.json || ok=0
curl -fsS http://127.0.0.1:8787/companion >/tmp/stage5p11t-companion.html || ok=0

echo
if [ "$ok" = "1" ]; then
  echo "STAGE_5P11T_SMOKE_OK"
else
  echo "STAGE_5P11T_SMOKE_FAIL"
  exit 1
fi
