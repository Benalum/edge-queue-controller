#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-ad-local-authenticated-admin-disabled-warmup-refusal-verification"
fail=0

echo "=== ${PHASE}: local authenticated admin disabled refusal verification ==="

python3 -m py_compile edge_controller.py || fail=1
ops/smoke/check-phase-12r-ac-disabled-future-warmup-pre-execution-readiness-rollup.sh || fail=1

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
curl -sS --max-time 5 -o /tmp/phase12rad-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health || fail=1

if [ "$fail" != "0" ]; then
  echo "FAIL: preflight blocked authenticated admin verification"
  exit "$fail"
fi

echo
echo "=== local-only authenticated admin POST disabled-refusal check ==="
echo "Paste the admin bearer token at the silent prompt. It will not be printed or stored."

python3 - <<'PY' || fail=1
import getpass
import json
import sys
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
        "User-Agent": "phase-12r-ad-local-admin-check/1.0",
    },
)

status = None
payload = None
raw = b""

try:
    with urllib.request.urlopen(req, timeout=10) as resp:
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
if status == 403:
    detail = payload.get("detail")
else:
    raise SystemExit(f"FAIL: expected authenticated admin disabled refusal HTTP 403, got {status}")

if not isinstance(detail, dict):
    raise SystemExit("FAIL: 403 detail was not the disabled warmup refusal object")

checks = {
    "source": "phase_12r_m_disabled_admin_model_warmup_endpoint_skeleton",
    "mode": "disabled_endpoint_skeleton",
    "endpoint": "/admin/model-warmup",
    "method": "POST",
    "model": "qwen3:0.6b",
    "would_call": "none",
    "reason": "warmup_action_disabled",
}

for key, expected in checks.items():
    actual = detail.get(key)
    if actual != expected:
        raise SystemExit(f"FAIL: detail.{key} expected {expected!r}, got {actual!r}")

boolean_checks = {
    "dry_run": True,
    "dry_run_only": True,
    "runtime_action_available": False,
    "admin_endpoint_available": True,
}

for key, expected in boolean_checks.items():
    actual = detail.get(key)
    if actual is not expected:
        raise SystemExit(f"FAIL: detail.{key} expected {expected!r}, got {actual!r}")

if detail.get("action_enabled") is True:
    raise SystemExit("FAIL: warmup action unexpectedly enabled")

blockers = detail.get("blockers")
if not isinstance(blockers, list) or "warmup_action_disabled" not in blockers:
    raise SystemExit("FAIL: warmup_action_disabled blocker missing")

if "Authorization" in json.dumps(payload, sort_keys=True):
    raise SystemExit("FAIL: response appears to include authorization material")

print("PASS: authenticated admin reached disabled warmup refusal without executing warmup")
PY

echo
echo "=== safety summary ==="
echo "PASS: no controller restart was performed"
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
