#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-o-disabled-admin-warmup-deployment-readiness-snapshot"
fail=0

echo "=== ${PHASE}: static gates ==="

python3 -m py_compile edge_controller.py || fail=1

ops/smoke/check-phase-12r-m-disabled-admin-model-warmup-endpoint-skeleton.sh || fail=1
ops/smoke/check-phase-12r-n-static-admin-warmup-endpoint-contract-smoke.sh || fail=1

echo
echo "=== read-only local controller health ==="
curl -sS --max-time 5 -o /tmp/phase12ro-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health || fail=1

echo
echo "=== read-only local system status snapshot ==="
curl -sS --max-time 8 -o /tmp/phase12ro-status.json \
  -w "status_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/system/status || fail=1

echo
echo "=== inspect live status for disabled admin warmup field ==="
python3 - <<'PY' || fail=1
import json
from pathlib import Path

status_path = Path("/tmp/phase12ro-status.json")
if not status_path.exists():
    raise SystemExit("FAIL: status snapshot missing")

text = status_path.read_text().strip()
if not text:
    raise SystemExit("FAIL: status snapshot empty")

try:
    data = json.loads(text)
except Exception as exc:
    raise SystemExit(f"FAIL: status snapshot is not JSON: {exc}")

def find_model_memory_status(value):
    if isinstance(value, dict):
        if isinstance(value.get("model_memory_status"), dict):
            return value["model_memory_status"]
        for child in value.values():
            found = find_model_memory_status(child)
            if found is not None:
                return found
    elif isinstance(value, list):
        for child in value:
            found = find_model_memory_status(child)
            if found is not None:
                return found
    return None

memory = find_model_memory_status(data)
if not isinstance(memory, dict):
    print("CHECK: live service does not expose model_memory_status in /system/status")
    print("CHECK: this is non-fatal for Phase 12R-O; no restart was performed")
else:
    endpoint = memory.get("admin_model_warmup_endpoint")
    if endpoint is None:
        print("CHECK: live service has not exposed admin_model_warmup_endpoint yet")
        print("CHECK: likely needs a later guarded controller-only restart")
    else:
        assert endpoint.get("source") == "phase_12r_m_disabled_admin_model_warmup_endpoint_skeleton"
        assert endpoint.get("mode") == "disabled_endpoint_skeleton"
        assert endpoint.get("endpoint") == "/admin/model-warmup"
        assert endpoint.get("method") == "POST"
        assert endpoint.get("dry_run_only") is True
        assert endpoint.get("runtime_action_available") is False
        assert endpoint.get("admin_endpoint_available") is True
        assert endpoint.get("would_call") == "none"
        print("PASS: live status exposes disabled admin warmup endpoint snapshot")
PY

echo
echo "=== safety: no POST endpoint call was performed ==="
echo "PASS: only read-only GET checks were used"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
fi

exit "$fail"
