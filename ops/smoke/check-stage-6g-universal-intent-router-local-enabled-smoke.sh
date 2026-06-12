#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6G Universal Intent Router local enabled smoke ==="

fail=0
flag="EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED"

cleanup() {
  echo
  echo "=== cleanup: disable router dry-run endpoint again ==="
  sudo systemctl unset-environment "$flag" || true
  sudo systemctl restart edge-queue-controller || true
  sleep 3

  code="$(
    curl -sS -o /tmp/stage6g-disabled-final.json \
      -w "%{http_code}" \
      -X POST http://127.0.0.1:7070/api/router/dry-run \
      -H 'Content-Type: application/json' \
      --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true
  )"

  echo "final_disabled_http_code=$code"
  cat /tmp/stage6g-disabled-final.json || true
  echo
}

trap cleanup EXIT

echo
echo "=== required files ==="
for f in \
  edge_controller.py \
  docs/stage-6f-universal-intent-router-disabled-dry-run-endpoint.md \
  docs/stage-6g-universal-intent-router-local-enabled-smoke.md
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== syntax ==="
python3 -m py_compile edge_controller.py

echo
echo "=== prove disabled before enabling ==="
disabled_code="$(
  curl -sS -o /tmp/stage6g-disabled-before.json \
    -w "%{http_code}" \
    -X POST http://127.0.0.1:7070/api/router/dry-run \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true
)"
echo "disabled_before_http_code=$disabled_code"

if [ "$disabled_code" = "404" ]; then
  echo "OK: endpoint disabled before smoke"
else
  echo "FAIL: endpoint was not disabled before smoke"
  cat /tmp/stage6g-disabled-before.json || true
  fail=1
fi

echo
echo "=== temporarily enable endpoint ==="
sudo systemctl set-environment "$flag=1"
sudo systemctl restart edge-queue-controller
sleep 3

echo
echo "=== call enabled endpoint ==="
enabled_code="$(
  curl -sS -o /tmp/stage6g-enabled.json \
    -w "%{http_code}" \
    -X POST http://127.0.0.1:7070/api/router/dry-run \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true
)"
echo "enabled_http_code=$enabled_code"
cat /tmp/stage6g-enabled.json | jq '.'
echo

if [ "$enabled_code" != "200" ]; then
  echo "FAIL: enabled endpoint did not return HTTP 200"
  fail=1
else
  jq -e '
    .ok == true
    and .dry_run == true
    and .dispatch_performed == false
    and .intent.name == "study.next"
    and .target.existing_route == "/api/study/session/command"
    and .model_routing.model_call_required == false
    and .safety.allowed_to_dispatch == false
  ' /tmp/stage6g-enabled.json >/dev/null || {
    echo "FAIL: enabled endpoint response is not dry-run safe"
    fail=1
  }
fi

echo
echo "=== Spanish command check ==="
spanish_code="$(
  curl -sS -o /tmp/stage6g-spanish.json \
    -w "%{http_code}" \
    -X POST http://127.0.0.1:7070/api/router/dry-run \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"siguiente","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true
)"
echo "spanish_http_code=$spanish_code"
cat /tmp/stage6g-spanish.json | jq '.'
echo

if [ "$spanish_code" != "200" ]; then
  echo "FAIL: Spanish enabled endpoint did not return HTTP 200"
  fail=1
else
  jq -e '
    .intent.name == "study.next"
    and .language.detected == "es"
    and .dispatch_performed == false
    and .model_routing.model_call_required == false
    and .safety.allowed_to_dispatch == false
  ' /tmp/stage6g-spanish.json >/dev/null || {
    echo "FAIL: Spanish response is not safe/expected"
    fail=1
  }
fi

echo
echo "=== no unrelated runtime files should be modified ==="
if git diff --name-only | grep -E '(^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' >/dev/null; then
  echo "FAIL: unrelated runtime/systemd files modified"
  fail=1
else
  echo "OK: no unrelated runtime/systemd files modified"
fi

echo
echo "=== git status ==="
git status --short

if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 6G Universal Intent Router local enabled smoke passed"
else
  echo "FAIL: Stage 6G Universal Intent Router local enabled smoke failed"
fi

exit "$fail"
