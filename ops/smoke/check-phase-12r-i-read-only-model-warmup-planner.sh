#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12R-I smoke: read-only model warmup planner ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

DOC="docs/phase-12r-i-read-only-model-warmup-planner.md"

echo
echo "=== repo state ==="
git status --short
git log --oneline -8
git tag --points-at HEAD || true

echo
echo "=== doc checks ==="
grep -Fq "Phase 12R-I Read-Only Model Warmup Planner" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "warmup_plan" "$DOC" && echo "PASS: warmup plan documented" || fail=1
grep -Fq "action_enabled = false" "$DOC" && echo "PASS: action disabled expectation documented" || fail=1
grep -Fq "qwen3:0.6b" "$DOC" && echo "PASS: tiny target model documented" || fail=1
grep -Fq "qwen3:1.7b" "$DOC" && echo "PASS: small qwen target model documented" || fail=1
grep -Fq "llama3.2:3b" "$DOC" && echo "PASS: small llama target model documented" || fail=1
grep -Fq "Phase 12R-I only plans and reports" "$DOC" && echo "PASS: scope marker documented" || fail=1

echo
echo "=== source checks ==="
grep -Fq "def _stage5p12i_read_only_warmup_plan" edge_controller.py && echo "PASS: warmup planner helper exists" || fail=1
grep -Fq "phase_12r_i_read_only_model_warmup_planner" edge_controller.py && echo "PASS: warmup planner source marker exists" || fail=1
grep -Fq 'status["warmup_plan"] = _stage5p12i_read_only_warmup_plan(status)' edge_controller.py && echo "PASS: warmup plan attached" || fail=1
grep -Fq 'status["warmup_candidates"] = status["warmup_plan"].get("candidates", [])' edge_controller.py && echo "PASS: warmup candidates derived from plan" || fail=1
grep -Fq '"action_enabled": False' edge_controller.py && echo "PASS: action disabled in source" || fail=1

if grep -nE '/api/generate|/api/chat|ollama stop|keep_alive.: 0|keep_alive=0' edge_controller.py | grep -E 'stage5p12h|stage5p12i|stage5p12r' >/tmp/phase12ri-risky.txt 2>/dev/null; then
  echo "FAIL: Phase 12R-H/I/R helper appears to contain warmup/unload execution markers"
  cat /tmp/phase12ri-risky.txt
  fail=1
else
  echo "PASS: Phase 12R-H/I/R helpers contain no warmup/unload execution markers"
fi

echo
echo "=== syntax check ==="
python3 -m py_compile edge_controller.py && echo "PASS: edge_controller.py compiles" || fail=1

echo
echo "=== restart controller to load warmup planner ==="
sudo systemctl restart edge-queue-controller
sleep 2

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12ri-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health | tee /tmp/phase12ri-health-code.txt || fail=1

python3 -m json.tool /tmp/phase12ri-health.json >/tmp/phase12ri-health.pretty \
  && grep -Fq '"ok": true' /tmp/phase12ri-health.pretty \
  && echo "PASS: controller health ok" || fail=1

echo
echo "=== live read-only warmup plan evidence ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status \
  | python3 -m json.tool >/tmp/phase12ri-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12ri-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker missing"

gate = worker.get("persistent_lane_cutover_readiness") or {}
reasons = set(gate.get("reasons") or [])
mms = worker.get("model_memory_status") or {}
warmup = mms.get("warmup_plan") or {}

summary = {
    "worker_state": worker.get("state"),
    "cutover_ready": gate.get("ready"),
    "cutover_dry_run_only": gate.get("dry_run_only"),
    "cutover_reasons": sorted(reasons),
    "mode": mms.get("mode"),
    "installed_models": mms.get("installed_models"),
    "loaded_models": mms.get("loaded_models"),
    "warmup_candidates": mms.get("warmup_candidates"),
    "warmup_plan": warmup,
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
assert isinstance(mms.get("eviction_plan"), dict), mms

assert warmup.get("source") == "phase_12r_i_read_only_model_warmup_planner", warmup
assert warmup.get("mode") == "read_only", warmup
assert warmup.get("action_enabled") is False, warmup
assert isinstance(warmup.get("default_target_models"), list), warmup
assert "qwen3:0.6b" in warmup.get("default_target_models", []), warmup
assert "qwen3:1.7b" in warmup.get("default_target_models", []), warmup
assert "llama3.2:3b" in warmup.get("default_target_models", []), warmup
assert isinstance(warmup.get("candidates"), list), warmup
assert isinstance(warmup.get("blocked"), list), warmup
assert warmup.get("candidate_count") == len(warmup.get("candidates") or []), warmup
assert warmup.get("loaded_model_count") == len(mms.get("loaded_models") or []), warmup

installed = set(mms.get("installed_models") or [])
loaded = set(mms.get("loaded_models") or [])

if {"qwen3:0.6b", "qwen3:1.7b", "llama3.2:3b"}.issubset(installed) and not loaded:
    assert warmup.get("reason") == "installed_not_loaded_models_available", warmup
    candidate_models = {item.get("model") for item in warmup.get("candidates") or []}
    assert {"qwen3:0.6b", "qwen3:1.7b", "llama3.2:3b"}.issubset(candidate_models), warmup

assert mms.get("warmup_candidates") == warmup.get("candidates"), mms
assert mms.get("safe_eviction_candidates") == (mms.get("eviction_plan") or {}).get("candidates", []), mms
assert mms.get("active_models") == [], mms
assert mms.get("warming_models") == [], mms
assert mms.get("last_warmup_decision") is None, mms
assert mms.get("last_eviction_decision") is None, mms

print("PASS: read-only warmup planner evidence is live")
PY

echo
echo "=== CT101 service safety state ==="
ssh "$CT101" 'pct exec 101 -- bash -lc '"'"'
set -u
fail=0

systemctl is-active ai-platform-laptop-queue-worker.service >/tmp/phase12ri-primary-active.txt 2>/dev/null
grep -Fq "active" /tmp/phase12ri-primary-active.txt \
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
  | grep -vF '?? docs/phase-12r-i-read-only-model-warmup-planner.md' \
  | grep -vF '?? ops/smoke/check-phase-12r-i-read-only-model-warmup-planner.sh' || true)"

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12R-I files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12R-I read-only model warmup planner smoke passed"
else
  echo "FAIL: Phase 12R-I read-only model warmup planner smoke failed"
fi

[ "$fail" = "0" ]
