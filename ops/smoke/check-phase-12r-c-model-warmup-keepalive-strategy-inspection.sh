#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12R-C smoke: model warmup and keep-alive strategy inspection ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

DOC="docs/phase-12r-c-model-warmup-keepalive-strategy-inspection.md"

echo
echo "=== repo state ==="
git status --short
git log --oneline -8
git tag --points-at HEAD || true

echo
echo "=== doc checks ==="
grep -Fq "Phase 12R-C Model Warmup and Keep-Alive Strategy Inspection" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "Use lazy, lane-aware model warmup" "$DOC" && echo "PASS: lazy warmup policy documented" || fail=1
grep -Fq "Do not load every model at boot" "$DOC" && echo "PASS: no preload-all policy documented" || fail=1
grep -Fq "first job for a lane/model triggers warmup" "$DOC" && echo "PASS: first-needed warmup documented" || fail=1
grep -Fq "model stays loaded for a configured keep-alive window" "$DOC" && echo "PASS: keep-alive policy documented" || fail=1
grep -Fq "worker warming model" "$DOC" && echo "PASS: worker warming state documented" || fail=1
grep -Fq "Phase 12R-C does not change services" "$DOC" && echo "PASS: inspection-only marker documented" || fail=1

echo
echo "=== local source sanity checks ==="
python3 - <<'PY' || fail=1
from pathlib import Path

checks = {
    "queue lane claim support": "queue_lane",
    "allowed models support": "allowed_models",
    "requested model handling": "requested_model",
    "persistent cutover gate": "persistent_lane_cutover_readiness",
}

combined = ""
for p in [Path("edge_controller.py"), Path("edge_modules/laptop_queue.py")]:
    if p.exists():
        combined += p.read_text(errors="ignore")

for label, needle in checks.items():
    if needle in combined:
        print(f"PASS: {label} marker found")
    else:
        print(f"FAIL: {label} marker missing")
        raise SystemExit(1)
PY

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12rc-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health | tee /tmp/phase12rc-health-code.txt || fail=1

python3 -m json.tool /tmp/phase12rc-health.json >/tmp/phase12rc-health.pretty \
  && grep -Fq '"ok": true' /tmp/phase12rc-health.pretty \
  && echo "PASS: controller health ok" || fail=1

echo
echo "=== live gate remains safely blocked ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status \
  | python3 -m json.tool >/tmp/phase12rc-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12rc-system-status.json"))
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

print("PASS: persistent lane cutover remains blocked during warmup strategy inspection")
PY

echo
echo "=== CT101 env and service safety checks ==="
ssh "$CT101" 'pct exec 101 -- bash -lc '"'"'
set -u
fail=0

for f in \
  /etc/ai-platform/laptop-queue-worker.env \
  /etc/ai-platform/laptop-queue-worker-model-tiny.env \
  /etc/ai-platform/laptop-queue-worker-model-small.env
do
  if [ -f "$f" ]; then
    echo "PASS: env file exists: $f"
  else
    echo "FAIL: env file missing: $f"
    fail=1
  fi
done

grep -Fq "LAPTOP_QUEUE_QUEUE_LANE=model-tiny" /etc/ai-platform/laptop-queue-worker-model-tiny.env 2>/dev/null \
  && echo "PASS: model-tiny lane env present" || { echo "FAIL: model-tiny lane env missing"; fail=1; }

grep -Fq "LAPTOP_QUEUE_QUEUE_LANE=model-small" /etc/ai-platform/laptop-queue-worker-model-small.env 2>/dev/null \
  && echo "PASS: model-small lane env present" || { echo "FAIL: model-small lane env missing"; fail=1; }

if grep -Fq "LAPTOP_QUEUE_QUEUE_LANE=" /etc/ai-platform/laptop-queue-worker.env 2>/dev/null; then
  echo "CHECK: primary has explicit queue lane"
  grep -nF "LAPTOP_QUEUE_QUEUE_LANE=" /etc/ai-platform/laptop-queue-worker.env || true
else
  echo "PASS: primary remains unfiltered/no explicit queue lane"
fi

systemctl is-active ai-platform-laptop-queue-worker.service >/tmp/phase12rc-primary-active.txt 2>/dev/null
grep -Fq "active" /tmp/phase12rc-primary-active.txt \
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

curl -sS --max-time 8 http://127.0.0.1:11434/api/tags >/tmp/phase12rc-ollama-tags.json 2>/dev/null \
  && echo "PASS: Ollama tags endpoint reachable" || { echo "CHECK: Ollama tags endpoint not reachable"; }

curl -sS --max-time 8 http://127.0.0.1:11434/api/ps >/tmp/phase12rc-ollama-ps.json 2>/dev/null \
  && echo "PASS: Ollama ps endpoint reachable" || { echo "CHECK: Ollama ps endpoint not reachable"; }

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
  | grep -vF '?? docs/phase-12r-c-model-warmup-keepalive-strategy-inspection.md' \
  | grep -vF '?? ops/smoke/check-phase-12r-c-model-warmup-keepalive-strategy-inspection.sh' || true)"

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12R-C doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12R-C model warmup and keep-alive strategy inspection smoke passed"
else
  echo "FAIL: Phase 12R-C model warmup and keep-alive strategy inspection smoke failed"
fi

[ "$fail" = "0" ]
