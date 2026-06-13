#!/usr/bin/env bash
set -u

fail=0
DOC="docs/phase-12c-ct101-dormant-worker-capacity-metadata.md"
CT101="root@100.88.194.19"
TAG="ai-platform-phase-12c-dormant-worker-capacity-metadata-2026-06-13"

echo "=== Phase 12C smoke: CT101 dormant worker capacity metadata checkpoint ==="
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== local git baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== doc marker checks ==="
grep -Fq "Phase 12C CT101 Dormant Worker Capacity Metadata" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "CT101 commit: 4d74475" "$DOC" && echo "PASS: CT101 commit doc marker found" || fail=1
grep -Fq "CT101 tag: ai-platform-phase-12c-dormant-worker-capacity-metadata-2026-06-13" "$DOC" && echo "PASS: CT101 tag doc marker found" || fail=1
grep -Fq "node_max_concurrent_jobs" "$DOC" && echo "PASS: node capacity doc marker found" || fail=1
grep -Fq "lane_capacity" "$DOC" && echo "PASS: lane capacity doc marker found" || fail=1
grep -Fq "LAPTOP_QUEUE_MAX_JOBS_PER_RUN remains pinned to 1" "$DOC" && echo "PASS: max jobs doc marker found" || fail=1
grep -Fq "Only the intended CT101 poller file was staged and committed." "$DOC" && echo "PASS: staged target doc marker found" || fail=1

echo
echo "=== CT101 git commit/tag verification ==="
ssh "$CT101" "pct exec 101 -- git -C /opt/ai-platform rev-parse --short HEAD" >/tmp/phase12c-ai-head.txt && echo "PASS: CT101 HEAD captured" || fail=1
cat /tmp/phase12c-ai-head.txt
grep -Fq "4d74475" /tmp/phase12c-ai-head.txt && echo "PASS: CT101 HEAD is Phase 12C commit" || fail=1
ssh "$CT101" "pct exec 101 -- git -C /opt/ai-platform tag --points-at HEAD" >/tmp/phase12c-ai-tags.txt && echo "PASS: CT101 tags captured" || fail=1
cat /tmp/phase12c-ai-tags.txt
grep -Fq "$TAG" /tmp/phase12c-ai-tags.txt && echo "PASS: CT101 Phase 12C tag points at HEAD" || fail=1

echo
echo "=== CT101 marker and syntax verification ==="
ssh "$CT101" "pct exec 101 -- grep -nF STAGE_5P12C_DORMANT_WORKER_CAPACITY_METADATA /opt/ai-platform/ops/smoke/laptop_queue_bounded_synthetic_poller.py" >/tmp/phase12c-markers.txt && echo "PASS: CT101 Phase 12C markers found" || fail=1
cat /tmp/phase12c-markers.txt
ssh "$CT101" "pct exec 101 -- grep -nE \"max_jobs_per_run|node_max_concurrent_jobs|supported_lanes|supported_model_tiers|allowed_models|lane_capacity|runtime_backend|ollama_num_parallel\" /opt/ai-platform/ops/smoke/laptop_queue_bounded_synthetic_poller.py" >/tmp/phase12c-capacity-refs.txt && echo "PASS: CT101 capacity refs found" || fail=1
cat /tmp/phase12c-capacity-refs.txt
ssh "$CT101" "pct exec 101 -- python3 -m py_compile /opt/ai-platform/ops/smoke/laptop_queue_bounded_synthetic_poller.py" && echo "PASS: CT101 poller py_compile ok" || fail=1

echo
echo "=== CT101 dormant env/max-jobs verification ==="
if ssh "$CT101" "pct exec 101 -- grep -RInE \"^LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS=|^LAPTOP_QUEUE_SUPPORTED_LANES=|^LAPTOP_QUEUE_SUPPORTED_MODEL_TIERS=|^LAPTOP_QUEUE_ALLOWED_MODELS=\" /opt/ai-platform/.env /opt/ai-platform/.secrets/laptop-queue.env /etc/ai-platform/laptop-queue-worker.env" >/tmp/phase12c-capacity-env.txt 2>/dev/null; then
  echo "FAIL: future capacity env is persistently configured"
  cat /tmp/phase12c-capacity-env.txt
  fail=1
else
  echo "PASS: future capacity env remains unset"
fi
if ssh "$CT101" "pct exec 101 -- grep -RInE \"^LAPTOP_QUEUE_QUEUE_LANE=\" /opt/ai-platform/.env /opt/ai-platform/.secrets/laptop-queue.env /etc/ai-platform/laptop-queue-worker.env" >/tmp/phase12c-queue-lane-env.txt 2>/dev/null; then
  echo "FAIL: queue lane env is persistently configured"
  cat /tmp/phase12c-queue-lane-env.txt
  fail=1
else
  echo "PASS: queue lane env remains unset"
fi
ssh "$CT101" "pct exec 101 -- grep -nF \"LAPTOP_QUEUE_MAX_JOBS_PER_RUN must be 1\" /opt/ai-platform/ops/runtime/laptop-queue-worker-preflight.sh" && echo "PASS: max jobs preflight guard remains" || fail=1

echo
echo "=== CT101 remaining dirty state verification ==="
ssh "$CT101" "pct exec 101 -- git -C /opt/ai-platform status --short" >/tmp/phase12c-ai-status.txt && echo "PASS: CT101 status captured" || fail=1
cat /tmp/phase12c-ai-status.txt
if grep -Fq "ops/smoke/laptop_queue_bounded_synthetic_poller.py" /tmp/phase12c-ai-status.txt; then echo "FAIL: poller target file still dirty after commit"; fail=1; else echo "PASS: poller target file clean after CT101 commit"; fi
grep -Fq " M docker-compose.yml" /tmp/phase12c-ai-status.txt && echo "PASS: unrelated docker-compose dirty state remains unstaged/uncommitted" || fail=1
grep -Fq " M ops/ct101-scripts/ai-platform-send-edge-heartbeat" /tmp/phase12c-ai-status.txt && echo "PASS: unrelated heartbeat dirty state remains unstaged/uncommitted" || fail=1

echo
echo "=== CT101 worker active/no-restart-state check ==="
ssh "$CT101" "pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service" >/tmp/phase12c-worker-active.txt && echo "PASS: worker service status command worked" || fail=1
grep -Fq "active" /tmp/phase12c-worker-active.txt && echo "PASS: CT101 worker service active" || fail=1
ssh "$CT101" "pct exec 101 -- systemctl show ai-platform-laptop-queue-worker.service -p MainPID -p ActiveState -p SubState --no-pager"

echo
echo "=== local controller health/router guard ==="
curl -sS --max-time 8 -o /tmp/phase12c-controller-health.json -w "health_code=%{http_code} time=%{time_total}\n" http://127.0.0.1:7070/health || fail=1
python3 -m json.tool /tmp/phase12c-controller-health.json >/tmp/phase12c-controller-health.pretty && grep -Fq "\"ok\": true" /tmp/phase12c-controller-health.pretty && echo "PASS: controller health ok" || fail=1
if systemctl show edge-queue-controller -p Environment --value | tr " " "\n" | grep -E "ROUTER.*DRY_RUN|PERSISTENT.*ROLLOUT.*ENABLED=1"; then
  echo "FAIL: unexpected router rollout env found"
  fail=1
else
  echo "PASS: no active router rollout env found"
fi

echo
echo "=== changed files guard ==="
bad_status="$(git status --short | grep -vE "^[?][?] docs/phase-12c-ct101-dormant-worker-capacity-metadata\.md$" | grep -vE "^[?][?] ops/smoke/check-phase-12c-ct101-dormant-worker-capacity-metadata\.sh$" || true)"
git status --short
if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12C controller doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12C controller checkpoint smoke passed"
else
  echo "FAIL: Phase 12C controller checkpoint smoke failed"
fi

[ "$fail" = "0" ]
