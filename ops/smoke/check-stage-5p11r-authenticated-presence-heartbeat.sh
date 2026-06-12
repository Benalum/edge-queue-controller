#!/usr/bin/env bash
set -euo pipefail

cd "$HOME/Desktop/edge-queue-controller"

ok=1
PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
[ -x "$PYBIN" ] || PYBIN="python3"

echo "=== Stage 5P-11R Authenticated Presence Heartbeat Smoke ==="

echo
echo "=== syntax ==="
node --check frontend/wrapper-ui/app.js || ok=0
"$PYBIN" -m py_compile edge_controller.py || ok=0

echo
echo "=== frontend marker checks ==="
for marker in \
  "STAGE_5P11R_AUTH_PRESENCE_FORCE_BEGIN" \
  "webPresenceAuthHeaders" \
  "webPresenceShouldBypassDebounce" \
  "headers.Authorization = \"Bearer \" + authState.token" \
  'fetch(`${API_BASE}/presence/web`' \
  "15-second-logged-in-heartbeat" \
  "private-app-heartbeat" \
  "private_app: PRIVATE_APP_ROUTE_SET.has(location.pathname)" \
  "STAGE_5P11R_LOGGED_IN_15_SECOND_HEARTBEAT_BEGIN"
do
  if grep -Fq "$marker" frontend/wrapper-ui/app.js; then
    echo "OK marker $marker"
  else
    echo "FAIL missing marker $marker"
    ok=0
  fi
done

echo
echo "=== backend policy marker checks ==="
for marker in \
  "WEB_PRESENCE_CONTAINER_START_DEMAND_V1" \
  "web_presence_container_required" \
  "container_required" \
  "Logged-in user is active; host must be online or booting."
do
  if grep -Fq "$marker" edge_controller.py; then
    echo "OK backend marker $marker"
  else
    echo "FAIL backend missing $marker"
    ok=0
  fi
done

echo
echo "=== route checks ==="
curl -fsS http://127.0.0.1:8787/companion >/tmp/stage5p11r-companion.html || ok=0
curl -fsS http://127.0.0.1:7070/system/presence/power-policy >/tmp/stage5p11r-policy.json || ok=0

echo
if [ "$ok" = "1" ]; then
  echo "STAGE_5P11R_SMOKE_OK"
else
  echo "STAGE_5P11R_SMOKE_FAIL"
  exit 1
fi
