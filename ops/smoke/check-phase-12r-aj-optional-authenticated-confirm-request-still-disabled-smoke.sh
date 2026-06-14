#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-aj-optional-authenticated-confirm-request-still-disabled-smoke"
fail=0

echo "=== ${PHASE}: optional authenticated confirm request still-disabled checks ==="

python3 -m py_compile edge_controller.py || fail=1
ops/smoke/check-phase-12r-ai-inspect-only-warmup-execution-activation-contract.sh || fail=1

echo
echo "=== safety: warmup execution env must not be enabled ==="
if systemctl show edge-queue-controller -p Environment --value \
  | tr ' ' '\n' \
  | grep -q '^EDGE_MODEL_WARMUP_ACTION_ENABLED=1$'; then
  echo "FAIL: EDGE_MODEL_WARMUP_ACTION_ENABLED=1 is set"
  fail=1
else
  echo "PASS: warmup action env is not enabled"
fi

echo
echo "=== service health ==="
curl -sS --max-time 5 -o /tmp/phase12raj-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health || fail=1

echo
echo "=== unauthenticated future-style POST must remain auth/admin blocked ==="
unauth_code="$(curl -sS --max-time 8 \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3:0.6b","dry_run":false,"confirm":"WARMUP_MODEL_NOW"}' \
  -o /tmp/phase12raj-unauth-post.json \
  -w "%{http_code}" \
  http://127.0.0.1:7070/admin/model-warmup || true)"
echo "unauth_code=${unauth_code}"

if [ "$unauth_code" != "401" ] && [ "$unauth_code" != "403" ]; then
  echo "FAIL: expected unauthenticated POST to be blocked with 401 or 403"
  fail=1
fi

python3 - <<'PY' || fail=1
import json
from pathlib import Path

data = json.loads(Path("/tmp/phase12raj-unauth-post.json").read_text())
body = json.dumps(data, sort_keys=True)

for forbidden in [
    "phase_12r_m_disabled_admin_model_warmup_endpoint_skeleton",
    "future_warmup_execution_preview",
    "disabled_future_execution_skeleton",
    "warmup_action_disabled",
    "WARMUP_MODEL_NOW",
    "would_call",
    "runtime_action_available",
]:
    if forbidden in body:
        raise SystemExit(f"FAIL: unauth response leaked warmup marker: {forbidden}")

print("PASS: unauthenticated future-style POST remains blocked before warmup refusal")
print("detail:", data.get("detail"))
PY

echo
echo "=== optional authenticated admin future-style POST still-disabled check ==="
if [ -z "${EDGE_TEST_ADMIN_BEARER_TOKEN:-}" ]; then
  echo "CHECK: EDGE_TEST_ADMIN_BEARER_TOKEN is not set"
  echo "CHECK: skipping authenticated admin future-style disabled check"
else
  python3 - <<'PY' || fail=1
import json
import os
import urllib.error
import urllib.request

token = os.environ.get("EDGE_TEST_ADMIN_BEARER_TOKEN", "").strip()
if not token:
    raise SystemExit("FAIL: token env unexpectedly empty")

body_obj = {
    "model": "qwen3:0.6b",
    "dry_run": False,
    "confirm": "WARMUP_MODEL_NOW",
}
body = json.dumps(body_obj).encode("utf-8")

req = urllib.request.Request(
    "http://127.0.0.1:7070/admin/model-warmup",
    data=body,
    method="POST",
    headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token}",
        "User-Agent": "phase-12r-aj-confirm-still-disabled-check/1.0",
    },
)

try:
    with urllib.request.urlopen(req, timeout=15) as resp:
        status = int(getattr(resp, "status", 0) or 0)
        raw = resp.read(1024 * 1024)
except urllib.error.HTTPError as exc:
    status = int(exc.code)
    raw = exc.read(1024 * 1024)
except Exception as exc:
    raise SystemExit(f"FAIL: authenticated POST request failed: {type(exc).__name__}: {str(exc)[:200]}")

print(f"auth_code={status}")

try:
    payload = json.loads(raw.decode("utf-8", errors="replace"))
except Exception as exc:
    raise SystemExit(f"FAIL: response was not JSON: {type(exc).__name__}")

if status == 401:
    raise SystemExit("FAIL: token was not accepted; got 401")
if status != 403:
    raise SystemExit(f"FAIL: expected authenticated admin disabled refusal HTTP 403, got {status}")

detail = payload.get("detail")
if not isinstance(detail, dict):
    raise SystemExit("FAIL: 403 detail was not an object")

expected_top = {
    "source": "phase_12r_m_disabled_admin_model_warmup_endpoint_skeleton",
    "mode": "disabled_endpoint_skeleton",
    "endpoint": "/admin/model-warmup",
    "method": "POST",
    "model": "qwen3:0.6b",
    "would_call": "none",
    "reason": "warmup_action_disabled",
}

for key, expected in expected_top.items():
    actual = detail.get(key)
    if actual != expected:
        raise SystemExit(f"FAIL: detail.{key} expected {expected!r}, got {actual!r}")

if detail.get("dry_run") is not False:
    raise SystemExit("FAIL: detail.dry_run should reflect false request")
if detail.get("dry_run_only") is not True:
    raise SystemExit("FAIL: detail.dry_run_only must remain true")
if detail.get("runtime_action_available") is not False:
    raise SystemExit("FAIL: detail.runtime_action_available must remain false")
if detail.get("action_enabled") is True:
    raise SystemExit("FAIL: detail.action_enabled unexpectedly true")

preview = detail.get("future_warmup_execution_preview")
if not isinstance(preview, dict):
    raise SystemExit("FAIL: missing future_warmup_execution_preview")

if preview.get("source") != "phase_12r_y_disabled_future_warmup_execution_skeleton":
    raise SystemExit("FAIL: preview source mismatch")
if preview.get("mode") != "disabled_future_execution_skeleton":
    raise SystemExit("FAIL: preview mode mismatch")
if preview.get("runtime_action_available") is not False:
    raise SystemExit("FAIL: preview runtime_action_available is not false")
if preview.get("would_call") != "none":
    raise SystemExit("FAIL: preview would_call is not none")
if preview.get("reason") != "runtime_action_unavailable":
    raise SystemExit("FAIL: preview reason mismatch")

future = preview.get("future_ollama_request")
if not isinstance(future, dict):
    raise SystemExit("FAIL: missing future_ollama_request")
if future.get("endpoint") != "/api/generate":
    raise SystemExit("FAIL: future endpoint mismatch")
if future.get("method") != "POST":
    raise SystemExit("FAIL: future method mismatch")
if future.get("execute_now") is not False:
    raise SystemExit("FAIL: future execute_now is not false")

response_text = json.dumps(payload, sort_keys=True)
if token in response_text or "Authorization" in response_text:
    raise SystemExit("FAIL: response appears to include authorization material")
if "WARMUP_MODEL_NOW" in response_text:
    raise SystemExit("FAIL: response should not echo confirm token")

print("PASS: authenticated future-style request still returns disabled non-executable refusal")
PY
fi

echo
echo "=== safety summary ==="
echo "PASS: no controller restart was performed"
echo "PASS: no CT101 worker runtime was changed"
echo "PASS: no persistent lane workers were started"
echo "PASS: no router rollout was enabled"
echo "PASS: no warmup execution was enabled"
echo "PASS: no bearer token value was printed"
echo "PASS: no Ollama direct call was made"
echo "PASS: no /api/generate call was made"
echo "PASS: no /api/chat call was made"
echo "PASS: no model warmup was executed"
echo "PASS: no model unload was executed"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
fi

exit "$fail"
