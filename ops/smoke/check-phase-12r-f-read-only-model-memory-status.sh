#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12R-F smoke: read-only model memory status ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

DOC="docs/phase-12r-f-read-only-model-memory-status.md"

echo
echo "=== repo state ==="
git status --short
git log --oneline -8
git tag --points-at HEAD || true

echo
echo "=== doc checks ==="
grep -Fq "Phase 12R-F Read-Only Model Memory Status" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "Phase 12R-F is read-only" "$DOC" && echo "PASS: read-only policy documented" || fail=1
grep -Fq "http://100.88.245.33:11434" "$DOC" && echo "PASS: discovered Ollama base URL documented" || fail=1
grep -Fq "Phase 12R-F only adds read-only status evidence" "$DOC" && echo "PASS: scope marker documented" || fail=1

echo
echo "=== source checks ==="
grep -Fq "def _stage5p12r_model_memory_status_read_only" edge_controller.py && echo "PASS: helper exists" || fail=1
grep -Fq "phase_12r_f_read_only_model_memory_status" edge_controller.py && echo "PASS: helper source marker exists" || fail=1
grep -Fq '"model_memory_status": _stage5p12r_model_memory_status_read_only()' edge_controller.py && echo "PASS: status attach exists" || fail=1
grep -Fq '"/api/version"' edge_controller.py && echo "PASS: version read marker found" || fail=1
grep -Fq '"/api/tags"' edge_controller.py && echo "PASS: tags read marker found" || fail=1
grep -Fq '"/api/ps"' edge_controller.py && echo "PASS: ps read marker found" || fail=1

if grep -nE '/api/generate|/api/chat|ollama stop|keep_alive.: 0|keep_alive=0' edge_controller.py | grep -F "stage5p12r" >/tmp/phase12rf-risky.txt 2>/dev/null; then
  echo "FAIL: Phase 12R-F helper appears to contain warmup/unload markers"
  cat /tmp/phase12rf-risky.txt
  fail=1
else
  echo "PASS: Phase 12R-F helper contains no warmup/unload markers"
fi

echo
echo "=== syntax check ==="
python3 -m py_compile edge_controller.py && echo "PASS: edge_controller.py compiles" || fail=1

echo
echo "=== restart controller to load read-only status helper ==="
sudo systemctl restart edge-queue-controller
sleep 2

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12rf-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health | tee /tmp/phase12rf-health-code.txt || fail=1

python3 -m json.tool /tmp/phase12rf-health.json >/tmp/phase12rf-health.pretty \
  && grep -Fq '"ok": true' /tmp/phase12rf-health.pretty \
  && echo "PASS: controller health ok" || fail=1

echo
echo "=== live model memory status evidence ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status \
  | python3 -m json.tool >/tmp/phase12rf-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12rf-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker missing"

gate = worker.get("persistent_lane_cutover_readiness") or {}
reasons = set(gate.get("reasons") or [])
mms = worker.get("model_memory_status") or {}

summary = {
    "worker_state": worker.get("state"),
    "cutover_ready": gate.get("ready"),
    "cutover_dry_run_only": gate.get("dry_run_only"),
    "cutover_reasons": sorted(reasons),
    "model_memory_source": mms.get("source"),
    "mode": mms.get("mode"),
    "ollama_base_url": mms.get("ollama_base_url"),
    "ollama_reachable": mms.get("ollama_reachable"),
    "ollama_version": mms.get("ollama_version"),
    "installed_models": mms.get("installed_models"),
    "loaded_models": mms.get("loaded_models"),
    "safe_eviction_candidates": mms.get("safe_eviction_candidates"),
    "active_models": mms.get("active_models"),
    "warming_models": mms.get("warming_models"),
    "memory": mms.get("memory"),
}
print(json.dumps(summary, indent=2, sort_keys=True))

assert worker.get("state") == "online", summary
assert gate.get("ready") is False, gate
assert gate.get("dry_run_only") is True, gate
assert "primary_worker_unfiltered" in reasons, gate
assert "persistent_lane_workers_not_active" in reasons, gate

assert mms.get("source") == "phase_12r_f_read_only_model_memory_status", mms
assert mms.get("mode") == "read_only", mms
assert mms.get("ollama_base_url") == "http://100.88.245.33:11434", mms
assert mms.get("ollama_reachable") is True, mms
assert isinstance(mms.get("installed_models"), list), mms
assert "qwen3:0.6b" in mms.get("installed_models", []), mms
assert "qwen3:1.7b" in mms.get("installed_models", []), mms
assert "llama3.2:3b" in mms.get("installed_models", []), mms
assert isinstance(mms.get("loaded_models"), list), mms
assert mms.get("safe_eviction_candidates") == [], mms
assert mms.get("active_models") == [], mms
assert mms.get("warming_models") == [], mms
assert mms.get("last_warmup_decision") is None, mms
assert mms.get("last_eviction_decision") is None, mms
assert isinstance(mms.get("memory"), dict), mms

print("PASS: read-only model memory status evidence is live")
PY

echo
echo "=== CT101 service safety state ==="
ssh "$CT101" 'pct exec 101 -- bash -lc '"'"'
set -u
fail=0

systemctl is-active ai-platform-laptop-queue-worker.service >/tmp/phase12rf-primary-active.txt 2>/dev/null
grep -Fq "active" /tmp/phase12rf-primary-active.txt \
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
  | grep -vF '?? docs/phase-12r-f-read-only-model-memory-status.md' \
  | grep -vF '?? ops/smoke/check-phase-12r-f-read-only-model-memory-status.sh' || true)"

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12R-F files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12R-F read-only model memory status smoke passed"
else
  echo "FAIL: Phase 12R-F read-only model memory status smoke failed"
fi

[ "$fail" = "0" ]
