#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-m-disabled-admin-model-warmup-endpoint-skeleton"
fail=0

echo "=== ${PHASE}: static safety checks ==="

python3 -m py_compile edge_controller.py || fail=1

grep -q 'def _stage5p12m_disabled_admin_model_warmup_response' edge_controller.py || fail=1
grep -q '@app.post("/admin/model-warmup")' edge_controller.py || fail=1
grep -q 'status\["admin_model_warmup_endpoint"\]' edge_controller.py || fail=1
grep -q 'phase_12r_m_disabled_admin_model_warmup_endpoint_skeleton' edge_controller.py || fail=1
grep -q 'raise HTTPException(status_code=403, detail=response)' edge_controller.py || fail=1

echo
echo "=== safety: endpoint skeleton must not call runtime model APIs ==="
if grep -n -A35 '@app.post("/admin/model-warmup")' edge_controller.py | grep -E '/api/generate|/api/chat|ollama|subprocess|systemctl|ai-platform-laptop-queue-worker'; then
  echo "FAIL: admin warmup endpoint appears to call runtime APIs"
  fail=1
else
  echo "PASS: endpoint skeleton has no runtime calls"
fi

echo
echo "=== safety: action remains disabled by default ==="
python3 - <<'PY' || fail=1
import os
os.environ.pop("EDGE_MODEL_WARMUP_ACTION_ENABLED", None)

ns = {}
src = open("edge_controller.py").read()
start = src.index("def _stage5p12m_disabled_admin_model_warmup_response(")
end = src.index("\ndef _stage5p12r_model_memory_status_read_only() -> dict:", start)
exec("import os\n" + src[start:end], ns)

response = ns["_stage5p12m_disabled_admin_model_warmup_response"]("qwen3:0.6b", dry_run=True)

assert response["source"] == "phase_12r_m_disabled_admin_model_warmup_endpoint_skeleton"
assert response["mode"] == "disabled_endpoint_skeleton"
assert response["endpoint"] == "/admin/model-warmup"
assert response["method"] == "POST"
assert response["dry_run_only"] is True
assert response["action_enabled"] is False
assert response["runtime_action_available"] is False
assert response["admin_endpoint_available"] is True
assert response["would_call"] == "none"
assert response["required_env"] == "EDGE_MODEL_WARMUP_ACTION_ENABLED=1"
assert response["reason"] == "warmup_action_disabled"
assert "warmup_action_disabled" in response["blockers"]

print("PASS: disabled response shape is correct")
PY

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
fi

exit "$fail"
