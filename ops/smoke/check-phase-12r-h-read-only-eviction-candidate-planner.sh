#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12R-H smoke: read-only eviction candidate planner ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

DOC="docs/phase-12r-h-read-only-eviction-candidate-planner.md"

echo
echo "=== repo state ==="
git status --short
git log --oneline -8
git tag --points-at HEAD || true

echo
echo "=== doc checks ==="
grep -Fq "Phase 12R-H Read-Only Eviction Candidate Planner" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "eviction_plan" "$DOC" && echo "PASS: eviction plan documented" || fail=1
grep -Fq "action_enabled = false" "$DOC" && echo "PASS: action disabled expectation documented" || fail=1
grep -Fq "no_loaded_models" "$DOC" && echo "PASS: no loaded models expectation documented" || fail=1
grep -Fq "Phase 12R-H only plans and reports" "$DOC" && echo "PASS: scope marker documented" || fail=1

echo
echo "=== source checks ==="
grep -Fq "def _stage5p12h_read_only_eviction_plan" edge_controller.py && echo "PASS: eviction planner helper exists" || fail=1
grep -Fq "phase_12r_h_read_only_eviction_candidate_planner" edge_controller.py && echo "PASS: eviction planner source marker exists" || fail=1
grep -Fq 'status["eviction_plan"] = _stage5p12h_read_only_eviction_plan(status)' edge_controller.py && echo "PASS: eviction plan attached" || fail=1
grep -Fq 'status["safe_eviction_candidates"] = status["eviction_plan"].get("candidates", [])' edge_controller.py && echo "PASS: safe eviction candidates derived from plan" || fail=1
grep -Fq '"action_enabled": False' edge_controller.py && echo "PASS: action disabled in source" || fail=1

if grep -nE '/api/generate|/api/chat|ollama stop|keep_alive.: 0|keep_alive=0' edge_controller.py | grep -E 'stage5p12h|stage5p12r' >/tmp/phase12rh-risky.txt 2>/dev/null; then
  echo "FAIL: Phase 12R-H/R helper appears to contain warmup/unload markers"
  cat /tmp/phase12rh-risky.txt
  fail=1
else
  echo "PASS: Phase 12R-H/R helpers contain no warmup/unload markers"
fi

echo
echo "=== syntax check ==="
python3 -m py_compile edge_controller.py && echo "PASS: edge_controller.py compiles" || fail=1

echo
echo "=== restart controller to load eviction planner ==="
sudo systemctl restart edge-queue-controller
sleep 2

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12rh-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health | tee /tmp/phase12rh-health-code.txt || fail=1

python3 -m json.tool /tmp/phase12rh-health.json >/tmp/phase12rh-health.pretty \
  && grep -Fq '"ok": true' /tmp/phase12rh-health.pretty \
  && echo "PASS: controller health ok" || fail=1

echo
echo "=== live read-only eviction plan evidence ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status \
  | python3 -m json.tool >/tmp/phase12rh-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12rh-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker missing"

gate = worker.get("persistent_lane_cutover_readiness") or {}
reasons = set(gate.get("reasons") or [])
mms = worker.get("model_memory_status") or {}
plan = mms.get("eviction_plan") or {}

summary = {
    "worker_state": worker.get("state"),
    "cutover_ready": gate.get("ready"),
    "cutover_dry_run_only": gate.get("dry_run_only"),
    "cutover_reasons": sorted(reasons),
    "mode": mms.get("mode"),
    "loaded_models": mms.get("loaded_models"),
    "safe_eviction_candidates": mms.get("safe_eviction_candidates"),
    "eviction_plan": plan,
}
print(json.dumps(summary, indent=2, sort_keys=True))

assert worker.get("state") == "online", summary
assert gate.get("ready") is False, gate
assert gate.get("dry_run_only") is True, gate
assert "primary_worker_unfiltered" in reasons, gate
assert "persistent_lane_workers_not_active" in reasons, gate

assert mms.get("mode") == "read_only", mms
assert mms.get("ollama_reachable") is True, mms
assert isinstance(mms.get("installed_models"), list), mms
assert isinstance(mms.get("loaded_models"), list), mms
assert isinstance(mms.get("ct101_memory"), dict), mms

assert plan.get("source") == "phase_12r_h_read_only_eviction_candidate_planner", plan
assert plan.get("mode") == "read_only", plan
assert plan.get("action_enabled") is False, plan
assert isinstance(plan.get("candidates"), list), plan
assert isinstance(plan.get("blocked"), list), plan
assert plan.get("candidate_count") == len(plan.get("candidates") or []), plan
assert plan.get("loaded_model_count") == len(mms.get("loaded_models") or []), plan

if not mms.get("loaded_models"):
    assert plan.get("reason") == "no_loaded_models", plan
    assert plan.get("candidates") == [], plan
    assert mms.get("safe_eviction_candidates") == [], mms

assert mms.get("active_models") == [], mms
assert mms.get("warming_models") == [], mms
assert mms.get("last_warmup_decision") is None, mms
assert mms.get("last_eviction_decision") is None, mms

print("PASS: read-only eviction planner evidence is live")
PY

echo
echo "=== CT101 service safety state ==="
ssh "$CT101" 'pct exec 101 -- bash -lc '"'"'
set -u
fail=0

systemctl is-active ai-platform-laptop-queue-worker.service >/tmp/phase12rh-primary-active.txt 2>/dev/null
grep -Fq "active" /tmp/phase12rh-primary-active.txt \
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
  | grep -vF '?? docs/phase-12r-h-read-only-eviction-candidate-planner.md' \
  | grep -vF '?? ops/smoke/check-phase-12r-h-read-only-eviction-candidate-planner.sh' || true)"

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12R-H files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12R-H read-only eviction candidate planner smoke passed"
else
  echo "FAIL: Phase 12R-H read-only eviction candidate planner smoke failed"
fi

[ "$fail" = "0" ]
