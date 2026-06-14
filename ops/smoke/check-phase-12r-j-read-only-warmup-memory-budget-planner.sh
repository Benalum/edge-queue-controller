#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12R-J smoke: read-only warmup memory budget planner ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

DOC="docs/phase-12r-j-read-only-warmup-memory-budget-planner.md"

echo
echo "=== repo state ==="
git status --short
git log --oneline -8
git tag --points-at HEAD || true

echo
echo "=== doc checks ==="
grep -Fq "Phase 12R-J Read-Only Warmup Memory Budget Planner" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "80% of CT101 RAM" "$DOC" && echo "PASS: 80 percent budget documented" || fail=1
grep -Fq "loaded model estimates + warming model estimates" "$DOC" && echo "PASS: loaded plus warming rule documented" || fail=1
grep -Fq "warmup_memory_budget" "$DOC" && echo "PASS: warmup memory budget status documented" || fail=1
grep -Fq "Phase 12R-J only plans and reports" "$DOC" && echo "PASS: scope marker documented" || fail=1

echo
echo "=== source checks ==="
grep -Fq "def _stage5p12j_read_only_warmup_memory_budget" edge_controller.py && echo "PASS: warmup memory budget helper exists" || fail=1
grep -Fq "phase_12r_j_read_only_warmup_memory_budget_planner" edge_controller.py && echo "PASS: budget planner source marker exists" || fail=1
grep -Fq 'status["warmup_memory_budget"] = _stage5p12j_read_only_warmup_memory_budget(status)' edge_controller.py && echo "PASS: warmup memory budget attached" || fail=1
grep -Fq '"budget_percent": 80' edge_controller.py && echo "PASS: 80 percent source budget found" || fail=1
grep -Fq '"action_enabled": False' edge_controller.py && echo "PASS: action disabled in source" || fail=1
grep -Fq "loaded_estimated_mb + warming_estimated_mb" edge_controller.py && echo "PASS: loaded plus warming calculation found" || fail=1

if grep -nE '/api/generate|/api/chat|ollama stop|keep_alive.: 0|keep_alive=0' edge_controller.py | grep -E 'stage5p12h|stage5p12i|stage5p12j|stage5p12r' >/tmp/phase12rj-risky.txt 2>/dev/null; then
  echo "FAIL: Phase 12R-H/I/J/R helper appears to contain warmup/unload execution markers"
  cat /tmp/phase12rj-risky.txt
  fail=1
else
  echo "PASS: Phase 12R-H/I/J/R helpers contain no warmup/unload execution markers"
fi

echo
echo "=== syntax check ==="
python3 -m py_compile edge_controller.py && echo "PASS: edge_controller.py compiles" || fail=1

echo
echo "=== restart controller to load budget planner ==="
sudo systemctl restart edge-queue-controller
sleep 2

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12rj-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health | tee /tmp/phase12rj-health-code.txt || fail=1

python3 -m json.tool /tmp/phase12rj-health.json >/tmp/phase12rj-health.pretty \
  && grep -Fq '"ok": true' /tmp/phase12rj-health.pretty \
  && echo "PASS: controller health ok" || fail=1

echo
echo "=== live read-only warmup memory budget evidence ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status \
  | python3 -m json.tool >/tmp/phase12rj-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12rj-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker missing"

gate = worker.get("persistent_lane_cutover_readiness") or {}
reasons = set(gate.get("reasons") or [])
mms = worker.get("model_memory_status") or {}
warmup = mms.get("warmup_plan") or {}
budget = mms.get("warmup_memory_budget") or {}

summary = {
    "worker_state": worker.get("state"),
    "cutover_ready": gate.get("ready"),
    "cutover_dry_run_only": gate.get("dry_run_only"),
    "cutover_reasons": sorted(reasons),
    "loaded_models": mms.get("loaded_models"),
    "warming_models": mms.get("warming_models"),
    "warmup_candidate_count": len(mms.get("warmup_candidates") or []),
    "warmup_plan_reason": warmup.get("reason"),
    "warmup_memory_budget": budget,
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
assert isinstance(mms.get("warmup_plan"), dict), mms

assert budget.get("source") == "phase_12r_j_read_only_warmup_memory_budget_planner", budget
assert budget.get("mode") == "read_only", budget
assert budget.get("action_enabled") is False, budget
assert budget.get("budget_percent") == 80, budget
assert budget.get("budget_fraction") == 0.8, budget
assert isinstance(budget.get("ct101_mem_total_mb"), int), budget
assert isinstance(budget.get("budget_mb"), int), budget
assert budget.get("budget_mb") < budget.get("ct101_mem_total_mb"), budget
assert budget.get("loaded_model_count") == len(mms.get("loaded_models") or []), budget
assert budget.get("warming_model_count") == len(mms.get("warming_models") or []), budget
assert budget.get("loaded_plus_warming_estimated_mb") == budget.get("loaded_estimated_mb") + budget.get("warming_estimated_mb"), budget
assert isinstance(budget.get("candidates"), list), budget
assert isinstance(budget.get("blocked"), list), budget

# Current expected state: no loaded/warming models, three installed target candidates.
if not mms.get("loaded_models") and not mms.get("warming_models"):
    assert budget.get("loaded_plus_warming_estimated_mb") == 0, budget
    assert budget.get("reason") in {"all_candidates_within_budget", "some_candidates_within_budget"}, budget
    candidate_models = {item.get("model") for item in budget.get("candidates") or []}
    assert {"qwen3:0.6b", "qwen3:1.7b", "llama3.2:3b"}.issubset(candidate_models), budget
    assert all(item.get("within_budget") is True for item in budget.get("candidates") or []), budget

assert mms.get("active_models") == [], mms
assert mms.get("warming_models") == [], mms
assert mms.get("last_warmup_decision") is None, mms
assert mms.get("last_eviction_decision") is None, mms

print("PASS: read-only warmup memory budget planner evidence is live")
PY

echo
echo "=== CT101 service safety state ==="
ssh "$CT101" 'pct exec 101 -- bash -lc '"'"'
set -u
fail=0

systemctl is-active ai-platform-laptop-queue-worker.service >/tmp/phase12rj-primary-active.txt 2>/dev/null
grep -Fq "active" /tmp/phase12rj-primary-active.txt \
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
  | grep -vF '?? docs/phase-12r-j-read-only-warmup-memory-budget-planner.md' \
  | grep -vF '?? ops/smoke/check-phase-12r-j-read-only-warmup-memory-budget-planner.sh' || true)"

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12R-J files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12R-J read-only warmup memory budget planner smoke passed"
else
  echo "FAIL: Phase 12R-J read-only warmup memory budget planner smoke failed"
fi

[ "$fail" = "0" ]
