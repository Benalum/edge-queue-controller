#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12R-K smoke: guarded manual warmup dry-run ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

DOC="docs/phase-12r-k-guarded-manual-warmup-dry-run.md"

echo
echo "=== repo state ==="
git status --short
git log --oneline -8
git tag --points-at HEAD || true

echo
echo "=== doc checks ==="
grep -Fq "Phase 12R-K Guarded Manual Warmup Dry-Run" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "manual_warmup_dry_runs" "$DOC" && echo "PASS: dry-run status documented" || fail=1
grep -Fq "budget_percent = 80" "$DOC" && echo "PASS: 80 percent budget expectation documented" || fail=1
grep -Fq "would_call = none" "$DOC" && echo "PASS: no-call expectation documented" || fail=1
grep -Fq "Phase 12R-K only reports" "$DOC" && echo "PASS: scope marker documented" || fail=1

echo
echo "=== source checks ==="
grep -Fq "def _stage5p12k_manual_warmup_dry_run" edge_controller.py && echo "PASS: manual warmup dry-run helper exists" || fail=1
grep -Fq "phase_12r_k_guarded_manual_warmup_dry_run" edge_controller.py && echo "PASS: dry-run source marker exists" || fail=1
grep -Fq 'status["manual_warmup_dry_runs"]' edge_controller.py && echo "PASS: manual warmup dry-runs attached" || fail=1
grep -Fq '"would_call": "none"' edge_controller.py && echo "PASS: would_call none in source" || fail=1
grep -Fq '"action_enabled": False' edge_controller.py && echo "PASS: action disabled in source" || fail=1

if grep -nE '/api/generate|/api/chat|ollama stop|keep_alive.: 0|keep_alive=0' edge_controller.py | grep -E 'stage5p12h|stage5p12i|stage5p12j|stage5p12k|stage5p12r' >/tmp/phase12rk-risky.txt 2>/dev/null; then
  echo "FAIL: Phase 12R-H/I/J/K/R helper appears to contain warmup/unload execution markers"
  cat /tmp/phase12rk-risky.txt
  fail=1
else
  echo "PASS: Phase 12R-H/I/J/K/R helpers contain no warmup/unload execution markers"
fi

echo
echo "=== syntax check ==="
python3 -m py_compile edge_controller.py && echo "PASS: edge_controller.py compiles" || fail=1

echo
echo "=== restart controller to load manual warmup dry-run planner ==="
sudo systemctl restart edge-queue-controller
sleep 2

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12rk-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health | tee /tmp/phase12rk-health-code.txt || fail=1

python3 -m json.tool /tmp/phase12rk-health.json >/tmp/phase12rk-health.pretty \
  && grep -Fq '"ok": true' /tmp/phase12rk-health.pretty \
  && echo "PASS: controller health ok" || fail=1

echo
echo "=== live guarded manual warmup dry-run evidence ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status \
  | python3 -m json.tool >/tmp/phase12rk-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12rk-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker missing"

gate = worker.get("persistent_lane_cutover_readiness") or {}
reasons = set(gate.get("reasons") or [])
mms = worker.get("model_memory_status") or {}
dry_runs = mms.get("manual_warmup_dry_runs") or {}

summary = {
    "worker_state": worker.get("state"),
    "cutover_ready": gate.get("ready"),
    "cutover_dry_run_only": gate.get("dry_run_only"),
    "cutover_reasons": sorted(reasons),
    "loaded_models": mms.get("loaded_models"),
    "warming_models": mms.get("warming_models"),
    "manual_warmup_dry_runs": dry_runs,
}
print(json.dumps(summary, indent=2, sort_keys=True))

assert worker.get("state") == "online", summary
assert gate.get("ready") is False, gate
assert gate.get("dry_run_only") is True, gate
assert "primary_worker_unfiltered" in reasons, gate
assert "persistent_lane_workers_not_active" in reasons, gate

assert mms.get("mode") == "read_only", mms
assert mms.get("ollama_reachable") is True, mms
assert isinstance(mms.get("warmup_memory_budget"), dict), mms
assert isinstance(dry_runs, dict), mms

for model in ["qwen3:0.6b", "qwen3:1.7b", "llama3.2:3b"]:
    report = dry_runs.get(model)
    assert isinstance(report, dict), (model, report)
    assert report.get("source") == "phase_12r_k_guarded_manual_warmup_dry_run", report
    assert report.get("mode") == "read_only", report
    assert report.get("model") == model, report
    assert report.get("action_enabled") is False, report
    assert report.get("installed") is True, report
    assert report.get("currently_loaded") is False, report
    assert report.get("ct101_memory_available") is True, report
    assert report.get("budget_percent") == 80, report
    assert report.get("within_budget") is True, report
    assert report.get("eviction_required") is False, report
    assert report.get("allowed_by_lane_policy") is True, report
    assert report.get("would_call") == "none", report
    assert report.get("dry_run_passed") is True, report
    assert report.get("blockers") == [], report

assert mms.get("active_models") == [], mms
assert mms.get("warming_models") == [], mms
assert mms.get("last_warmup_decision") is None, mms
assert mms.get("last_eviction_decision") is None, mms

print("PASS: guarded manual warmup dry-run evidence is live")
PY

echo
echo "=== CT101 service safety state ==="
ssh "$CT101" 'pct exec 101 -- bash -lc '"'"'
set -u
fail=0

systemctl is-active ai-platform-laptop-queue-worker.service >/tmp/phase12rk-primary-active.txt 2>/dev/null
grep -Fq "active" /tmp/phase12rk-primary-active.txt \
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
  | grep -vF '?? docs/phase-12r-k-guarded-manual-warmup-dry-run.md' \
  | grep -vF '?? ops/smoke/check-phase-12r-k-guarded-manual-warmup-dry-run.sh' || true)"

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12R-K files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12R-K guarded manual warmup dry-run smoke passed"
else
  echo "FAIL: Phase 12R-K guarded manual warmup dry-run smoke failed"
fi

[ "$fail" = "0" ]
