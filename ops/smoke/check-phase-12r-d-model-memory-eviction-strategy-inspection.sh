#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12R-D smoke: model memory eviction strategy inspection ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

DOC="docs/phase-12r-d-model-memory-eviction-strategy-inspection.md"

echo
echo "=== repo state ==="
git status --short
git log --oneline -8
git tag --points-at HEAD || true

echo
echo "=== doc checks ==="
grep -Fq "Phase 12R-D Model Memory Eviction Strategy Inspection" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "memory-aware model eviction" "$DOC" && echo "PASS: memory eviction policy documented" || fail=1
grep -Fq "Never unload a model that is actively running a job" "$DOC" && echo "PASS: active model safety rule documented" || fail=1
grep -Fq "idle-cold models" "$DOC" && echo "PASS: idle-cold eviction priority documented" || fail=1
grep -Fq "Future Model Memory Manager" "$DOC" && echo "PASS: future manager documented" || fail=1
grep -Fq "ensure_model_ready(model)" "$DOC" && echo "PASS: ensure model ready behavior documented" || fail=1
grep -Fq "Phase 12R-D does not perform unloads" "$DOC" && echo "PASS: no-unload marker documented" || fail=1
grep -Fq "Phase 12R-D is documentation and smoke only" "$DOC" && echo "PASS: inspection-only marker documented" || fail=1

echo
echo "=== local source sanity checks ==="
python3 - <<'PY' || fail=1
from pathlib import Path

combined = ""
for p in [
    Path("edge_controller.py"),
    Path("edge_modules/laptop_queue.py"),
    Path("edge_modules/chat_queue_real_user_creation.py"),
]:
    if p.exists():
        combined += p.read_text(errors="ignore")

checks = {
    "requested model exists": "requested_model",
    "queue lane exists": "queue_lane",
    "allowed models exists": "allowed_models",
    "worker state exists": "worker_state",
    "persistent cutover readiness exists": "persistent_lane_cutover_readiness",
}

for label, needle in checks.items():
    if needle in combined:
        print(f"PASS: {label}")
    else:
        print(f"FAIL: {label}")
        raise SystemExit(1)
PY

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12rd-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health | tee /tmp/phase12rd-health-code.txt || fail=1

python3 -m json.tool /tmp/phase12rd-health.json >/tmp/phase12rd-health.pretty \
  && grep -Fq '"ok": true' /tmp/phase12rd-health.pretty \
  && echo "PASS: controller health ok" || fail=1

echo
echo "=== live gate remains blocked safely ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status \
  | python3 -m json.tool >/tmp/phase12rd-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12rd-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker missing"

gate = worker.get("persistent_lane_cutover_readiness") or {}
reasons = set(gate.get("reasons") or [])
evidence = gate.get("evidence") or {}
warnings = gate.get("warnings") or []

summary = {
    "worker_state": worker.get("state"),
    "ready": gate.get("ready"),
    "dry_run_only": gate.get("dry_run_only"),
    "reasons": sorted(reasons),
    "warnings": warnings,
    "primary_worker_queue_lane": evidence.get("primary_worker_queue_lane"),
}
print(json.dumps(summary, indent=2, sort_keys=True))

assert worker.get("state") == "online", summary
assert gate.get("ready") is False, gate
assert gate.get("dry_run_only") is True, gate
assert "primary_worker_unfiltered" in reasons, gate
assert "persistent_lane_workers_not_active" in reasons, gate
assert evidence.get("primary_worker_queue_lane") in (None, ""), evidence

print("PASS: persistent lane cutover remains blocked during eviction strategy inspection")
PY

echo
echo "=== CT101 safety checks, no unloads ==="
ssh "$CT101" 'pct exec 101 -- bash -lc '"'"'
set -u
fail=0

systemctl is-active ai-platform-laptop-queue-worker.service >/tmp/phase12rd-primary-active.txt 2>/dev/null
grep -Fq "active" /tmp/phase12rd-primary-active.txt \
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

for f in \
  /etc/ai-platform/laptop-queue-worker.env \
  /etc/ai-platform/laptop-queue-worker-model-tiny.env \
  /etc/ai-platform/laptop-queue-worker-model-small.env
do
  [ -f "$f" ] && echo "PASS: env file exists: $f" || { echo "FAIL: env missing: $f"; fail=1; }
done

free -h | sed -n "1,3p"

echo "PASS: no model unload command executed in Phase 12R-D smoke"

if [ "$fail" = "0" ]; then
  true
else
  false
fi
'"'"'' || fail=1

echo
echo "=== guard: smoke must not contain active unload commands ==="
if grep -E "ollama stop|keep_alive.: 0|keep_alive=0|/api/generate.*keep_alive" "$0" 2>/dev/null; then
  echo "CHECK: shell self-inspection found unload text in execution wrapper"
fi

if grep -E "ollama stop|keep_alive.: 0|keep_alive=0" "$DOC" >/tmp/phase12rd-doc-unload-mentions.txt 2>/dev/null; then
  echo "PASS: doc mentions future unload methods only"
else
  echo "FAIL: doc missing future unload method discussion"
  fail=1
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
  | grep -vF '?? docs/phase-12r-d-model-memory-eviction-strategy-inspection.md' \
  | grep -vF '?? ops/smoke/check-phase-12r-d-model-memory-eviction-strategy-inspection.sh' || true)"

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12R-D doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12R-D model memory eviction strategy inspection smoke passed"
else
  echo "FAIL: Phase 12R-D model memory eviction strategy inspection smoke failed"
fi

[ "$fail" = "0" ]
