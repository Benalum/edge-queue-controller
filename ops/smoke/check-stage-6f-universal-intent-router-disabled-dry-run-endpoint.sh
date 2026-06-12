#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6F Universal Intent Router disabled dry-run endpoint smoke ==="

fail=0

for f in \
  edge_controller.py \
  docs/stage-6f-universal-intent-router-disabled-dry-run-endpoint.md \
  docs/stage-6e-universal-intent-router-dry-run-contract.md
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

python3 -m py_compile edge_controller.py

for marker in \
  "STAGE_6F_MINIMAL_ROUTER_DRY_RUN_ENDPOINT_V1" \
  "EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED" \
  "dispatch_performed" \
  "allowed_to_dispatch" \
  "model_call_required"
do
  grep -q "$marker" edge_controller.py && echo "OK: marker $marker" || { echo "FAIL: missing marker $marker"; fail=1; }
done

.venv/bin/python - <<'PY'
import edge_controller

result = edge_controller._stage6f_router_response({
    "input": {"text": "next", "source": "study", "surface": "study_session"},
    "context": {"active_page": "study"}
})

assert result["ok"] is True
assert result["dry_run"] is True
assert result["dispatch_performed"] is False
assert result["intent"]["name"] == "study.next"
assert result["target"]["existing_route"] == "/api/study/session/command"
assert result["model_routing"]["model_call_required"] is False
assert result["safety"]["allowed_to_dispatch"] is False

spanish = edge_controller._stage6f_router_response({
    "input": {"text": "siguiente", "source": "study", "surface": "study_session"},
    "context": {"active_page": "study"}
})

assert spanish["intent"]["name"] == "study.next"
assert spanish["language"]["detected"] == "es"

print("OK: helper contract check passed")
PY

if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  http_code="$(
    curl -sS -o /tmp/stage6f-disabled.json \
      -w "%{http_code}" \
      -X POST http://127.0.0.1:7070/api/router/dry-run \
      -H 'Content-Type: application/json' \
      --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true
  )"

  echo "disabled_endpoint_http_code=$http_code"

  if [ "$http_code" = "404" ]; then
    echo "OK: endpoint disabled by default"
  else
    echo "FAIL: endpoint should be disabled by default"
    cat /tmp/stage6f-disabled.json || true
    fail=1
  fi
else
  echo "WARN: controller inactive; skipped runtime disabled check"
fi

if git diff --name-only | grep -E '(^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' >/dev/null; then
  echo "FAIL: unrelated runtime/systemd files modified"
  fail=1
else
  echo "OK: no unrelated runtime/systemd files modified"
fi

git status --short

if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 6F Universal Intent Router disabled dry-run endpoint smoke passed"
else
  echo "FAIL: Stage 6F Universal Intent Router disabled dry-run endpoint smoke failed"
fi

exit "$fail"
