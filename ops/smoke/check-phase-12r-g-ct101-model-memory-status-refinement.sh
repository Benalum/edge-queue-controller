#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12R-G smoke: CT101 model memory status refinement ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

DOC="docs/phase-12r-g-ct101-model-memory-status-refinement.md"

echo
echo "=== repo state ==="
git status --short
git log --oneline -8
git tag --points-at HEAD || true

echo
echo "=== doc checks ==="
grep -Fq "Phase 12R-G CT101 Model Memory Status Refinement" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "controller_memory" "$DOC" && echo "PASS: controller memory documented" || fail=1
grep -Fq "ct101_memory" "$DOC" && echo "PASS: CT101 memory documented" || fail=1
grep -Fq "Phase 12R-G is read-only" "$DOC" && echo "PASS: read-only policy documented" || fail=1
grep -Fq "Phase 12R-G only refines read-only evidence" "$DOC" && echo "PASS: scope marker documented" || fail=1

echo
echo "=== source checks ==="
grep -Fq '"controller_memory"' edge_controller.py && echo "PASS: controller_memory source marker found" || fail=1
grep -Fq '"ct101_memory"' edge_controller.py && echo "PASS: ct101_memory source marker found" || fail=1
grep -Fq "ct101_ollama_host_proc_meminfo_via_pveso_pct_exec" edge_controller.py && echo "PASS: ct101 memory source label found" || fail=1
grep -Fq "BatchMode=yes" edge_controller.py && echo "PASS: noninteractive ssh marker found" || fail=1
grep -Fq "pct exec 101" edge_controller.py && echo "PASS: pct exec memory read marker found" || fail=1

if grep -nE '/api/generate|/api/chat|ollama stop|keep_alive.: 0|keep_alive=0' edge_controller.py | grep -F "stage5p12r" >/tmp/phase12rg-risky.txt 2>/dev/null; then
  echo "FAIL: Phase 12R-G helper appears to contain warmup/unload markers"
  cat /tmp/phase12rg-risky.txt
  fail=1
else
  echo "PASS: Phase 12R-G helper contains no warmup/unload markers"
fi

echo
echo "=== syntax check ==="
python3 -m py_compile edge_controller.py && echo "PASS: edge_controller.py compiles" || fail=1

echo
echo "=== restart controller to load refined status helper ==="
sudo systemctl restart edge-queue-controller
sleep 2

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12rg-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health | tee /tmp/phase12rg-health-code.txt || fail=1

python3 -m json.tool /tmp/phase12rg-health.json >/tmp/phase12rg-health.pretty \
  && grep -Fq '"ok": true' /tmp/phase12rg-health.pretty \
  && echo "PASS: controller health ok" || fail=1

echo
echo "=== live refined model memory status evidence ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status \
  | python3 -m json.tool >/tmp/phase12rg-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12rg-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker missing"

gate = worker.get("persistent_lane_cutover_readiness") or {}
reasons = set(gate.get("reasons") or [])
mms = worker.get("model_memory_status") or {}
controller_memory = mms.get("controller_memory") or {}
ct101_memory = mms.get("ct101_memory") or {}
legacy_memory = mms.get("memory") or {}

summary = {
    "worker_state": worker.get("state"),
    "cutover_ready": gate.get("ready"),
    "cutover_dry_run_only": gate.get("dry_run_only"),
    "cutover_reasons": sorted(reasons),
    "mode": mms.get("mode"),
    "ollama_reachable": mms.get("ollama_reachable"),
    "installed_models": mms.get("installed_models"),
    "loaded_models": mms.get("loaded_models"),
    "controller_memory": controller_memory,
    "ct101_memory": ct101_memory,
    "legacy_memory_note": legacy_memory.get("note"),
    "safe_eviction_candidates": mms.get("safe_eviction_candidates"),
    "active_models": mms.get("active_models"),
    "warming_models": mms.get("warming_models"),
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
assert "qwen3:0.6b" in mms.get("installed_models", []), mms
assert isinstance(mms.get("loaded_models"), list), mms

assert controller_memory.get("source") == "controller_host_proc_meminfo", controller_memory
assert isinstance(controller_memory.get("mem_total_mb"), int), controller_memory

assert ct101_memory.get("source") == "ct101_ollama_host_proc_meminfo_via_pveso_pct_exec", ct101_memory
assert "available" in ct101_memory, ct101_memory
if ct101_memory.get("available") is True:
    assert isinstance(ct101_memory.get("mem_total_mb"), int), ct101_memory
    assert ct101_memory.get("mem_total_mb") >= 30000, ct101_memory

assert "Deprecated alias" in (legacy_memory.get("note") or ""), legacy_memory

assert mms.get("safe_eviction_candidates") == [], mms
assert mms.get("active_models") == [], mms
assert mms.get("warming_models") == [], mms
assert mms.get("last_warmup_decision") is None, mms
assert mms.get("last_eviction_decision") is None, mms

print("PASS: refined read-only model memory status evidence is live")
PY

echo
echo "=== CT101 service safety state ==="
ssh "$CT101" 'pct exec 101 -- bash -lc '"'"'
set -u
fail=0

systemctl is-active ai-platform-laptop-queue-worker.service >/tmp/phase12rg-primary-active.txt 2>/dev/null
grep -Fq "active" /tmp/phase12rg-primary-active.txt \
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
  | grep -vF '?? docs/phase-12r-g-ct101-model-memory-status-refinement.md' \
  | grep -vF '?? ops/smoke/check-phase-12r-g-ct101-model-memory-status-refinement.sh' || true)"

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12R-G files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12R-G CT101 model memory status refinement smoke passed"
else
  echo "FAIL: Phase 12R-G CT101 model memory status refinement smoke failed"
fi

[ "$fail" = "0" ]
