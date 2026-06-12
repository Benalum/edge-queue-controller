#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6O Universal Intent Router HTTP enabled schema smoke ==="

fail=0
flag="EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED"
schema="docs/generated/stage-6n-router-response-schema.json"

cleanup() {
  echo
  echo "=== cleanup: disable router dry-run endpoint again ==="
  sudo systemctl unset-environment "$flag" || true
  sudo systemctl restart edge-queue-controller || true
  sleep 3

  code="$(
    curl -sS -o /tmp/stage6o-final-disabled.json \
      -w "%{http_code}" \
      -X POST http://127.0.0.1:7070/api/router/dry-run \
      -H 'Content-Type: application/json' \
      --data '{"input":{"text":"next card","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true
  )"

  echo "final_disabled_http_code=$code"
  cat /tmp/stage6o-final-disabled.json || true
  echo
}

trap cleanup EXIT

echo
echo "=== required files ==="
for f in \
  edge_controller.py \
  edge_intent_router.py \
  "$schema" \
  docs/stage-6o-universal-intent-router-http-enabled-schema-smoke.md
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

python3 -m json.tool "$schema" >/dev/null
python3 -m py_compile edge_controller.py edge_intent_router.py

echo
echo "=== prove disabled before enabling ==="
disabled_code="$(
  curl -sS -o /tmp/stage6o-disabled-before.json \
    -w "%{http_code}" \
    -X POST http://127.0.0.1:7070/api/router/dry-run \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"next card","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true
)"
echo "disabled_before_http_code=$disabled_code"

if [ "$disabled_code" = "404" ]; then
  echo "OK: endpoint disabled before smoke"
else
  echo "FAIL: endpoint was not disabled before smoke"
  cat /tmp/stage6o-disabled-before.json || true
  fail=1
fi

echo
echo "=== temporarily enable router dry-run endpoint ==="
sudo systemctl set-environment "$flag=1"
sudo systemctl restart edge-queue-controller
sleep 3

echo
echo "=== call enabled study request ==="
study_code="$(
  curl -sS -o /tmp/stage6o-study.json \
    -w "%{http_code}" \
    -X POST http://127.0.0.1:7070/api/router/dry-run \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"next card","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true
)"
echo "study_http_code=$study_code"
cat /tmp/stage6o-study.json | jq '.'
echo

echo
echo "=== call enabled blocked admin request ==="
admin_code="$(
  curl -sS -o /tmp/stage6o-admin-blocked.json \
    -w "%{http_code}" \
    -X POST http://127.0.0.1:7070/api/router/dry-run \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"status","source":"admin","surface":"admin_panel"},"context":{"active_page":"admin"}}' || true
)"
echo "admin_http_code=$admin_code"
cat /tmp/stage6o-admin-blocked.json | jq '.'
echo

if [ "$study_code" != "200" ] || [ "$admin_code" != "200" ]; then
  echo "FAIL: enabled endpoint did not return HTTP 200 for both requests"
  fail=1
else
  .venv/bin/python - <<'PY'
import json
from pathlib import Path

schema = json.loads(Path("docs/generated/stage-6n-router-response-schema.json").read_text())

responses = {
    "study": json.loads(Path("/tmp/stage6o-study.json").read_text()),
    "admin_blocked": json.loads(Path("/tmp/stage6o-admin-blocked.json").read_text()),
}

required_top = schema["required_top_level"]
required_nested = schema["required_nested"]

def validate_common(name, result):
    missing_top = [key for key in required_top if key not in result]
    assert not missing_top, (name, "missing_top", missing_top)

    for parent, keys in required_nested.items():
        assert isinstance(result[parent], dict), (name, parent, "not_dict")
        missing = [key for key in keys if key not in result[parent]]
        assert not missing, (name, parent, "missing_nested", missing)

    assert result["ok"] is True, name
    assert result["dry_run"] is True, name
    assert result["dispatch_performed"] is False, name
    assert result["model_routing"]["model_call_required"] is False, name
    assert result["safety"]["allowed_to_dispatch"] is False, name
    assert result["confirmation_policy"]["eligible_for_dispatch"] is False, name
    assert result["decision_trace"][0]["step"] == "normalize_input", name
    assert result["decision_trace"][-1]["step"] == "rule_result", name
    assert result["decision_trace"][-1]["dispatch_blocked_reason"] == "dry_run_endpoint_never_dispatches", name

for name, result in responses.items():
    validate_common(name, result)
    print(f"OK: HTTP response schema valid: {name}")

study = responses["study"]
assert study["source_surface_policy"]["allowed"] is True
assert study["intent"]["name"] == "study.next"
assert study["target"]["existing_route"] == "/api/study/session/command"
assert study["decision_trace"][-1]["rule_id"] == "study.next.alias"

admin = responses["admin_blocked"]
assert admin["source_surface_policy"]["allowed"] is False
assert admin["intent"]["name"] == "unknown.unsupported"
assert admin["target"]["existing_route"] is None
assert admin["decision_trace"][-1]["rule_id"] == "policy.source_surface.blocked"

print("OK: Stage 6O HTTP enabled schema checks passed")
PY
fi

echo
echo "=== unrelated runtime/systemd file check ==="
if git diff --name-only | grep -E '(^edge_controller.py$|^edge_intent_router.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' >/dev/null; then
  echo "FAIL: runtime/systemd files modified"
  git diff --name-only | grep -E '(^edge_controller.py$|^edge_intent_router.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' || true
  fail=1
else
  echo "OK: no runtime/systemd file modifications detected"
fi

git status --short

if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 6O Universal Intent Router HTTP enabled schema smoke passed"
else
  echo "FAIL: Stage 6O Universal Intent Router HTTP enabled schema smoke failed"
fi

exit "$fail"
