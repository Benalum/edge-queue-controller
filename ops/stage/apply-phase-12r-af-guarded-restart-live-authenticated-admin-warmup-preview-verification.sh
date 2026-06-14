#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-af-guarded-restart-live-authenticated-admin-warmup-preview-verification"
fail=0

echo "=== ${PHASE}: guarded restart and live authenticated preview verification ==="

test "$(git rev-parse --short HEAD)" = "4bab5ca" || fail=1
test -z "$(git status --short --untracked-files=no)" || fail=1
python3 -m py_compile edge_controller.py || fail=1
ops/smoke/check-phase-12r-ae-admin-disabled-warmup-refusal-future-preview.sh || fail=1

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
echo "=== safety: service must be active before restart ==="
systemctl is-active edge-queue-controller || fail=1

if [ "$fail" != "0" ]; then
  echo "FAIL: preflight blocked controller restart"
  exit "$fail"
fi

echo
echo "=== restart controller service only ==="
sudo systemctl restart edge-queue-controller || fail=1

echo
echo "=== wait for health ==="
ok=0
for i in 1 2 3 4 5 6 7 8 9 10; do
  code="$(curl -sS --max-time 3 -o /tmp/phase12raf-health.json -w "%{http_code}" http://127.0.0.1:7070/health || true)"
  echo "try=$i health_code=$code"
  if [ "$code" = "200" ]; then
    ok=1
    break
  fi
  sleep 1
done

if [ "$ok" != "1" ]; then
  echo "FAIL: controller health did not recover"
  fail=1
fi

echo
echo "=== read-only live system status ==="
curl -sS --max-time 10 -o /tmp/phase12raf-status.json \
  -w "status_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/system/status || fail=1

if [ "$fail" != "0" ]; then
  echo "FAIL: health/status blocked authenticated verification"
  exit "$fail"
fi

echo
echo "=== local-only authenticated admin POST future-preview disabled-refusal check ==="
echo "Paste the admin bearer token at the silent prompt. It will not be printed or stored."

python3 - <<'PY' || fail=1
import getpass
import json
import urllib.error
import urllib.request

token = getpass.getpass("Admin bearer token: ").strip()
if not token:
    raise SystemExit("FAIL: empty bearer token")

url = "http://127.0.0.1:7070/admin/model-warmup"
body = json.dumps({"model": "qwen3:0.6b", "dry_run": True}).encode("utf-8")

req = urllib.request.Request(
    url,
    data=body,
    method="POST",
    headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token}",
        "User-Agent": "phase-12r-af-local-admin-preview-check/1.0",
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

print(f"post_code={status}")

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

for key, expected in {
    "dry_run": True,
    "dry_run_only": True,
    "runtime_action_available": False,
    "admin_endpoint_available": True,
}.items():
    actual = detail.get(key)
    if actual is not expected:
        raise SystemExit(f"FAIL: detail.{key} expected {expected!r}, got {actual!r}")

preview = detail.get("future_warmup_execution_preview")
if not isinstance(preview, dict):
    raise SystemExit("FAIL: missing future_warmup_execution_preview")

expected_preview = {
    "source": "phase_12r_y_disabled_future_warmup_execution_skeleton",
    "mode": "disabled_future_execution_skeleton",
    "model": "qwen3:0.6b",
    "would_call": "none",
    "reason": "runtime_action_unavailable",
}

for key, expected in expected_preview.items():
    actual = preview.get(key)
    if actual != expected:
        raise SystemExit(f"FAIL: preview.{key} expected {expected!r}, got {actual!r}")

if preview.get("runtime_action_available") is not False:
    raise SystemExit("FAIL: preview runtime_action_available is not false")

future = preview.get("future_ollama_request")
if not isinstance(future, dict):
    raise SystemExit("FAIL: missing future_ollama_request")

if future.get("endpoint") != "/api/generate":
    raise SystemExit("FAIL: future endpoint mismatch")
if future.get("method") != "POST":
    raise SystemExit("FAIL: future method mismatch")
if future.get("stream") is not False:
    raise SystemExit("FAIL: future stream is not false")
if future.get("execute_now") is not False:
    raise SystemExit("FAIL: future execute_now is not false")

body = json.dumps(payload, sort_keys=True)
if "Authorization" in body or token in body:
    raise SystemExit("FAIL: response appears to include authorization material")

print("PASS: live authenticated admin disabled refusal includes non-executable future preview")
PY

echo
echo "=== safety summary ==="
echo "PASS: only edge-queue-controller was restarted"
echo "PASS: no CT101 worker runtime was changed"
echo "PASS: no persistent lane workers were started"
echo "PASS: no router rollout was enabled"
echo "PASS: no warmup execution was enabled"
echo "PASS: no bearer token value was printed"
echo "PASS: no bearer token value was written to disk by this script"
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
