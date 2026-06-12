#!/usr/bin/env bash
set -euo pipefail

cd "$HOME/Desktop/edge-queue-controller"

ok=1
PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
[ -x "$PYBIN" ] || PYBIN="python3"

echo "=== Stage 5P-11S Presence Send Fallback Smoke ==="

echo
echo "=== syntax ==="
node --check frontend/wrapper-ui/app.js || ok=0
"$PYBIN" -m py_compile edge_controller.py || ok=0

echo
echo "=== marker checks ==="
for item in \
  "STAGE_5P11S_PRESENCE_SEND_FALLBACK_BEGIN" \
  "api(\"/presence/web\"" \
  "\"/system/presence/web\"" \
  "\"/api/presence/web\"" \
  "presence send failed:" \
  "STAGE_5P11S_PRESENCE_ROUTE_ALIASES_BEGIN" \
  "@app.post(\"/api/presence/web\")" \
  "@app.post(\"/presence/web\")"
do
  if grep -Fq "$item" frontend/wrapper-ui/app.js edge_controller.py frontend/wrapper-ui/index.html; then
    echo "OK marker $item"
  else
    echo "FAIL missing marker $item"
    ok=0
  fi
done

echo
echo "=== route aliases ==="
for url in \
  http://127.0.0.1:7070/system/presence/web \
  http://127.0.0.1:7070/api/presence/web \
  http://127.0.0.1:7070/presence/web
do
  code="$(curl -sS -o /tmp/stage5p11s-presence.json -w '%{http_code}' \
    -X POST "$url" \
    -H 'Content-Type: application/json' \
    -d '{"visitor_id":"stage5p11s-smoke","route":"/smoke","active_seconds":1,"visibility":"visible","metadata":{"reason":"smoke"}}' || true)"
  echo "$url code=$code"
  [ "$code" = "200" ] || ok=0
done

echo
echo "=== served JS/cache checks ==="
curl -fsS http://127.0.0.1:8787/app.js | grep -F "STAGE_5P11S_PRESENCE_SEND_FALLBACK_BEGIN" >/dev/null || ok=0
curl -fsS http://127.0.0.1:8787/companion | grep -E 'app\.js\?v=' >/dev/null || ok=0

echo
if [ "$ok" = "1" ]; then
  echo "STAGE_5P11S_SMOKE_OK"
else
  echo "STAGE_5P11S_SMOKE_FAIL"
  exit 1
fi
