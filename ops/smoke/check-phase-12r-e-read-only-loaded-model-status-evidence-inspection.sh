#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"
OLLAMA_BASE="http://100.88.245.33:11434"

echo "=== Phase 12R-E smoke: read-only loaded model status evidence inspection ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

DOC="docs/phase-12r-e-read-only-loaded-model-status-evidence-inspection.md"

echo
echo "=== repo state ==="
git status --short
git log --oneline -8
git tag --points-at HEAD || true

echo
echo "=== doc checks ==="
grep -Fq "Phase 12R-E Read-Only Loaded Model Status Evidence Inspection" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "http://100.88.245.33:11434" "$DOC" && echo "PASS: discovered Ollama base URL documented" || fail=1
grep -Fq "installed models from the Ollama tags API" "$DOC" && echo "PASS: installed model evidence documented" || fail=1
grep -Fq "loaded or running models from the Ollama ps API" "$DOC" && echo "PASS: loaded model evidence documented" || fail=1
grep -Fq "safe eviction candidates" "$DOC" && echo "PASS: safe eviction candidates documented" || fail=1
grep -Fq "Phase 12R-E must not" "$DOC" && echo "PASS: safety policy documented" || fail=1
grep -Fq "Phase 12R-E is documentation and smoke only" "$DOC" && echo "PASS: inspection-only marker documented" || fail=1

echo
echo "=== local source sanity checks ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text(errors="ignore")
checks = {
    "system status route exists": '@app.get("/system/status")',
    "ct101 worker status helper exists": "def _system_ct101_laptop_queue_worker_status",
    "lane dispatch readiness exists": "lane_dispatch_readiness",
    "persistent cutover readiness exists": "persistent_lane_cutover_readiness",
    "worker state marker exists": "worker_state",
}
for label, needle in checks.items():
    if needle in text:
        print(f"PASS: {label}")
    else:
        print(f"FAIL: {label}")
        raise SystemExit(1)
PY

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12re-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health | tee /tmp/phase12re-health-code.txt || fail=1

python3 -m json.tool /tmp/phase12re-health.json >/tmp/phase12re-health.pretty \
  && grep -Fq '"ok": true' /tmp/phase12re-health.pretty \
  && echo "PASS: controller health ok" || fail=1

echo
echo "=== live gate remains blocked safely ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status \
  | python3 -m json.tool >/tmp/phase12re-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12re-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker missing"

gate = worker.get("persistent_lane_cutover_readiness") or {}
reasons = set(gate.get("reasons") or [])
evidence = gate.get("evidence") or {}

summary = {
    "worker_state": worker.get("state"),
    "ready": gate.get("ready"),
    "dry_run_only": gate.get("dry_run_only"),
    "reasons": sorted(reasons),
    "primary_worker_queue_lane": evidence.get("primary_worker_queue_lane"),
}
print(json.dumps(summary, indent=2, sort_keys=True))

assert worker.get("state") == "online", summary
assert gate.get("ready") is False, gate
assert gate.get("dry_run_only") is True, gate
assert "primary_worker_unfiltered" in reasons, gate
assert "persistent_lane_workers_not_active" in reasons, gate
assert evidence.get("primary_worker_queue_lane") in (None, ""), evidence

print("PASS: persistent lane cutover remains blocked during loaded-model status inspection")
PY

echo
echo "=== CT101 safety and read-only Ollama evidence checks ==="
ssh "$CT101" 'pct exec 101 -- bash -lc '"'"'
set -u
fail=0
OLLAMA_BASE="http://100.88.245.33:11434"

systemctl is-active ai-platform-laptop-queue-worker.service >/tmp/phase12re-primary-active.txt 2>/dev/null
grep -Fq "active" /tmp/phase12re-primary-active.txt \
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

echo "--- memory snapshot ---"
free -h | sed -n "1,3p"

echo "--- Ollama version/tags/ps through discovered base URL ---"
version_code="$(curl -sS --max-time 5 -o /tmp/phase12re-version.json -w "%{http_code}" "$OLLAMA_BASE/api/version" 2>/tmp/phase12re-version.err || true)"
tags_code="$(curl -sS --max-time 8 -o /tmp/phase12re-tags.json -w "%{http_code}" "$OLLAMA_BASE/api/tags" 2>/tmp/phase12re-tags.err || true)"
ps_code="$(curl -sS --max-time 8 -o /tmp/phase12re-ps.json -w "%{http_code}" "$OLLAMA_BASE/api/ps" 2>/tmp/phase12re-ps.err || true)"

echo "version_code=$version_code"
echo "tags_code=$tags_code"
echo "ps_code=$ps_code"

if [ "$version_code" = "200" ]; then
  echo "PASS: Ollama version reachable"
  python3 -m json.tool /tmp/phase12re-version.json | sed -n "1,60p" || true
else
  echo "FAIL: Ollama version not reachable"
  cat /tmp/phase12re-version.err || true
  fail=1
fi

if [ "$tags_code" = "200" ]; then
  echo "PASS: Ollama tags reachable"
  python3 - <<PY
import json
data=json.load(open("/tmp/phase12re-tags.json"))
models=data.get("models") or []
print("installed_model_count=", len(models))
print("installed_model_names=", [m.get("name") or m.get("model") for m in models][:20])
PY
else
  echo "FAIL: Ollama tags not reachable"
  cat /tmp/phase12re-tags.err || true
  fail=1
fi

if [ "$ps_code" = "200" ]; then
  echo "PASS: Ollama ps reachable"
  python3 - <<PY
import json
data=json.load(open("/tmp/phase12re-ps.json"))
models=data.get("models") or []
print("loaded_model_count=", len(models))
print("loaded_model_names=", [m.get("name") or m.get("model") for m in models])
PY
else
  echo "FAIL: Ollama ps not reachable"
  cat /tmp/phase12re-ps.err || true
  fail=1
fi

echo "PASS: no model warmup/unload commands executed"

if [ "$fail" = "0" ]; then
  true
else
  false
fi
'"'"'' || fail=1

echo
echo "=== guard: inspection-only no-action markers ==="
grep -Fq "Phase 12R-E must not" "$DOC" && echo "PASS: no-action safety section documented" || fail=1
grep -Fq "unload models" "$DOC" && echo "PASS: unload prohibition documented" || fail=1
grep -Fq "warm models" "$DOC" && echo "PASS: warmup prohibition documented" || fail=1
echo "PASS: smoke performs read-only Ollama version/tags/ps checks only"

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
  | grep -vF '?? docs/phase-12r-e-read-only-loaded-model-status-evidence-inspection.md' \
  | grep -vF '?? ops/smoke/check-phase-12r-e-read-only-loaded-model-status-evidence-inspection.sh' || true)"

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12R-E doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12R-E read-only loaded model status evidence inspection smoke passed"
else
  echo "FAIL: Phase 12R-E read-only loaded model status evidence inspection smoke failed"
fi

[ "$fail" = "0" ]
