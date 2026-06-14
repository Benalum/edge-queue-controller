#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12R-L smoke: disabled manual warmup action blueprint ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

DOC="docs/phase-12r-l-disabled-manual-warmup-action-blueprint.md"

echo
echo "=== repo state ==="
git status --short
git log --oneline -8
git tag --points-at HEAD || true

echo
echo "=== doc checks ==="
grep -Fq "Phase 12R-L Disabled Manual Warmup Action Blueprint" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "manual_warmup_action" "$DOC" && echo "PASS: manual warmup action status documented" || fail=1
grep -Fq "EDGE_MODEL_WARMUP_ACTION_ENABLED=1" "$DOC" && echo "PASS: required future env documented" || fail=1
grep -Fq "admin-only action route" "$DOC" && echo "PASS: admin-only future route documented" || fail=1
grep -Fq "Phase 12R-L only exposes the disabled action blueprint" "$DOC" && echo "PASS: scope marker documented" || fail=1

echo
echo "=== source checks ==="
grep -Fq "def _stage5p12l_disabled_manual_warmup_action_blueprint" edge_controller.py && echo "PASS: disabled action blueprint helper exists" || fail=1
grep -Fq "phase_12r_l_disabled_manual_warmup_action_blueprint" edge_controller.py && echo "PASS: blueprint source marker exists" || fail=1
grep -Fq 'status["manual_warmup_action"] = _stage5p12l_disabled_manual_warmup_action_blueprint(status)' edge_controller.py && echo "PASS: manual warmup action blueprint attached" || fail=1
grep -Fq '"enabled": False' edge_controller.py && echo "PASS: action disabled in source" || fail=1
grep -Fq '"runtime_action_available": runtime_action_available' edge_controller.py && echo "PASS: runtime availability field found" || fail=1
grep -Fq '"admin_endpoint_available": False' edge_controller.py && echo "PASS: admin endpoint unavailable in source" || fail=1
grep -Fq '"would_call": "none"' edge_controller.py && echo "PASS: would_call none in source" || fail=1
grep -Fq 'EDGE_MODEL_WARMUP_ACTION_ENABLED' edge_controller.py && echo "PASS: future env gate marker found" || fail=1

if grep -nE '/api/generate|/api/chat|ollama stop|keep_alive.: 0|keep_alive=0' edge_controller.py | grep -E 'stage5p12h|stage5p12i|stage5p12j|stage5p12k|stage5p12l|stage5p12r' >/tmp/phase12rl-risky.txt 2>/dev/null; then
  echo "FAIL: Phase 12R-H/I/J/K/L/R helper appears to contain warmup/unload execution markers"
  cat /tmp/phase12rl-risky.txt
  fail=1
else
  echo "PASS: Phase 12R-H/I/J/K/L/R helpers contain no warmup/unload execution markers"
fi

echo
echo "=== syntax check ==="
python3 -m py_compile edge_controller.py && echo "PASS: edge_controller.py compiles" || fail=1

echo
echo "=== restart controller to load disabled action blueprint ==="
sudo systemctl restart edge-queue-controller
sleep 2

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12rl-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health | tee /tmp/phase12rl-health-code.txt || fail=1

python3 -m json.tool /tmp/phase12rl-health.json >/tmp/phase12rl-health.pretty \
  && grep -Fq '"ok": true' /tmp/phase12rl-health.pretty \
  && echo "PASS: controller health ok" || fail=1

echo
echo "=== live disabled manual warmup action blueprint evidence ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status \
  | python3 -m json.tool >/tmp/phase12rl-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12rl-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker missing"

gate = worker.get("persistent_lane_cutover_readiness") or {}
reasons = set(gate.get("reasons") or [])
mms = worker.get("model_memory_status") or {}
action = mms.get("manual_warmup_action") or {}

summary = {
    "worker_state": worker.get("state"),
    "cutover_ready": gate.get("ready"),
    "cutover_dry_run_only": gate.get("dry_run_only"),
    "cutover_reasons": sorted(reasons),
    "manual_warmup_action": action,
}
print(json.dumps(summary, indent=2, sort_keys=True))

assert worker.get("state") == "online", summary
assert gate.get("ready") is False, gate
assert gate.get("dry_run_only") is True, gate
assert "primary_worker_unfiltered" in reasons, gate
assert "persistent_lane_workers_not_active" in reasons, gate

assert mms.get("mode") == "read_only", mms
assert mms.get("ollama_reachable") is True, mms
assert isinstance(mms.get("manual_warmup_dry_runs"), dict), mms
assert isinstance(action, dict), mms

assert action.get("source") == "phase_12r_l_disabled_manual_warmup_action_blueprint", action
assert action.get("mode") == "disabled_action_blueprint", action
assert action.get("enabled") is False, action
assert action.get("runtime_action_available") is False, action
assert action.get("admin_endpoint_available") is False, action
assert action.get("would_call") == "none", action
assert action.get("action_enabled_env") == "EDGE_MODEL_WARMUP_ACTION_ENABLED", action
assert isinstance(action.get("future_command_plan"), dict), action
assert action["future_command_plan"].get("execute_now") is False, action
assert isinstance(action.get("preflight_required"), list), action
assert "within_80_percent_ram_budget" in action.get("preflight_required"), action
assert "runtime_action_enabled" in action.get("preflight_required"), action
assert isinstance(action.get("eligible_models"), list), action

eligible = {item.get("model") for item in action.get("eligible_models") or []}
assert {"qwen3:0.6b", "qwen3:1.7b", "llama3.2:3b"}.issubset(eligible), action

assert mms.get("active_models") == [], mms
assert mms.get("warming_models") == [], mms
assert mms.get("last_warmup_decision") is None, mms
assert mms.get("last_eviction_decision") is None, mms

print("PASS: disabled manual warmup action blueprint evidence is live")
PY

echo
echo "=== CT101 service safety state ==="
ssh "$CT101" 'pct exec 101 -- bash -lc '"'"'
set -u
fail=0

systemctl is-active ai-platform-laptop-queue-worker.service >/tmp/phase12rl-primary-active.txt 2>/dev/null
grep -Fq "active" /tmp/phase12rl-primary-active.txt \
  && echo "PASS: primary worker active" || { echo "FAIL: primary worker inactive"; fail=1; }

for u in \
  ai-platform-laptop-queue-worker@model-tiny.service \
  ai-platform-laptop-queue-worker@model-small.service
do
  if systemctl is-active --quiet "$u" 2>/dev/null; then
    echo "FAIL: lane worker active unexpectedly: $u"
    fail=1
  else
    echo "PASS: lane worker inactive: $u"
  fi
done

if [ "$fail" = "0" ]; then
  true
else
  false
fi
'"'"'' || fail=1

echo
echo "=== warmup env disabled guard ==="
if systemctl show edge-queue-controller -p Environment --value \
  | tr " " "\n" \
  | grep -E '^EDGE_MODEL_WARMUP_ACTION_ENABLED=1$'; then
  echo "FAIL: warmup action env enabled unexpectedly"
  fail=1
else
  echo "PASS: warmup action env is not enabled"
fi

echo
echo "=== router rollout parked guard ==="
if systemctl show edge-queue-controller -p Environment --value \
  | tr " " "\n" \
  | grep -E "ROUTER.*DRY_RUN|PERSISTENT.*ROLLOUT.*ENABLED=1"; then
  echo "FAIL: unexpected router rollout env found"
  fail=1
else
  echo "PASS: no active router rollout env found"
fi

echo
echo "=== changed files guard ==="
git status --short

bad_status="$(git status --short \
  | grep -vF ' M edge_controller.py' \
  | grep -vF '?? docs/phase-12r-l-disabled-manual-warmup-action-blueprint.md' \
  | grep -vF '?? ops/smoke/check-phase-12r-l-disabled-manual-warmup-action-blueprint.sh' || true)"

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12R-L files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12R-L disabled manual warmup action blueprint smoke passed"
else
  echo "FAIL: Phase 12R-L disabled manual warmup action blueprint smoke failed"
fi

[ "$fail" = "0" ]
