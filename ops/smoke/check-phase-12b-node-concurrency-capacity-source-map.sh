#!/usr/bin/env bash
set -u

fail=0
DOC="docs/phase-12b-node-concurrency-capacity-source-map.md"
CT101="root@100.88.194.19"

echo "=== Phase 12B smoke: node concurrency capacity source map ==="
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== local git baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== doc marker checks ==="
grep -Fq "Phase 12B Node Concurrency Capacity Source Map" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "current_jobs, max_concurrent_jobs, and queue_depth" "$DOC" && echo "PASS: legacy capacity doc marker found" || fail=1
grep -Fq "app_workers path currently tracks a single current_job_id" "$DOC" && echo "PASS: laptop queue current_job_id doc marker found" || fail=1
grep -Fq "LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1" "$DOC" && echo "PASS: max jobs doc marker found" || fail=1
grep -Fq "lane_capacity" "$DOC" && echo "PASS: lane capacity doc marker found" || fail=1
grep -Fq "node_max_concurrent_jobs" "$DOC" && echo "PASS: node max concurrency doc marker found" || fail=1
grep -Fq "None in Phase 12B." "$DOC" && echo "PASS: runtime unchanged doc marker found" || fail=1
grep -Fq "This phase is inspection/documentation only." "$DOC" && echo "PASS: inspection only doc marker found" || fail=1

echo
echo "=== controller source marker checks ==="
grep -nF "max_concurrent_jobs INTEGER NOT NULL DEFAULT 1" edge_controller.py && echo "PASS: legacy workers max_concurrent_jobs exists" || fail=1
grep -nF "current_jobs INTEGER NOT NULL DEFAULT 0" edge_controller.py && echo "PASS: legacy workers current_jobs exists" || fail=1
grep -nF "queue_depth INTEGER NOT NULL DEFAULT 0" edge_controller.py && echo "PASS: legacy workers queue_depth exists" || fail=1
grep -nF "worker at max concurrency" edge_controller.py && echo "PASS: legacy worker scorer max concurrency guard exists" || fail=1
grep -nF "current_job_id = (SELECT id FROM updated_job)" edge_modules/laptop_queue.py && echo "PASS: laptop queue claim sets current_job_id" || fail=1
grep -nF "current_job_id = NULL" edge_modules/laptop_queue.py && echo "PASS: laptop queue completion clears current_job_id" || fail=1
grep -nF "payload_json->>queue_lane" edge_modules/laptop_queue.py >/dev/null 2>&1 && echo "PASS: queue_lane claim filter exists" || grep -nF "payload_json->>'queue_lane'" edge_modules/laptop_queue.py && echo "PASS: queue_lane claim filter exists" || fail=1
grep -nF "lane_summary" edge_controller.py && echo "PASS: lane summary status source exists" || fail=1

echo
echo "=== CT101 simple capacity/source checks ==="
ssh "$CT101" "pct exec 101 -- git -C /opt/ai-platform rev-parse --short HEAD" >/tmp/phase12b-ai-head.txt && echo "PASS: CT101 ai-platform HEAD captured" || fail=1
cat /tmp/phase12b-ai-head.txt
grep -Fq "bc829ca" /tmp/phase12b-ai-head.txt && echo "PASS: CT101 is at Phase 12A ai-platform commit" || fail=1
ssh "$CT101" "pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service" >/tmp/phase12b-worker-active.txt && echo "PASS: worker status command worked" || fail=1
grep -Fq "active" /tmp/phase12b-worker-active.txt && echo "PASS: CT101 worker service active" || fail=1
ssh "$CT101" "pct exec 101 -- grep -nF \"LAPTOP_QUEUE_MAX_JOBS_PER_RUN must be 1\" /opt/ai-platform/ops/runtime/laptop-queue-worker-preflight.sh" && echo "PASS: CT101 preflight pins max jobs to 1" || fail=1
ssh "$CT101" "pct exec 101 -- grep -nF \"LAPTOP_QUEUE_MAX_JOBS_PER_RUN\" /etc/ai-platform/laptop-queue-worker.env /opt/ai-platform/.env /opt/ai-platform/.secrets/laptop-queue.env 2>/dev/null" >/tmp/phase12b-maxjobs.txt || true
cat /tmp/phase12b-maxjobs.txt
grep -Fq "LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1" /tmp/phase12b-maxjobs.txt && echo "PASS: CT101 env max jobs remains 1" || fail=1
ssh "$CT101" "pct exec 101 -- grep -nF \"LAPTOP_QUEUE_JOB_TYPES\" /etc/ai-platform/laptop-queue-worker.env /opt/ai-platform/.env /opt/ai-platform/.secrets/laptop-queue.env 2>/dev/null" >/tmp/phase12b-jobtypes.txt || true
cat /tmp/phase12b-jobtypes.txt
grep -Fq "LAPTOP_QUEUE_JOB_TYPES=ollama_chat" /tmp/phase12b-jobtypes.txt && echo "PASS: CT101 job types remain ollama_chat" || fail=1
if ssh "$CT101" "pct exec 101 -- grep -RInE \"node_max_concurrent_jobs|lane_capacity|supported_lanes|allowed_models\" /opt/ai-platform/ops/smoke/laptop_queue_bounded_synthetic_poller.py /opt/ai-platform/backend/app/worker/laptop_queue_client.py" >/tmp/phase12b-future-capacity.txt 2>/dev/null; then
  echo "FAIL: CT101 already has future capacity metadata markers"
  cat /tmp/phase12b-future-capacity.txt
  fail=1
else
  echo "PASS: CT101 capacity metadata has not been added yet"
fi
ssh "$CT101" "pct exec 101 -- grep -nF \"LAPTOP_QUEUE_QUEUE_LANE\" /opt/ai-platform/ops/smoke/laptop_queue_bounded_synthetic_poller.py" && echo "PASS: CT101 dormant queue lane env reader exists from Phase 12A" || fail=1
if ssh "$CT101" "pct exec 101 -- grep -RInE \"^LAPTOP_QUEUE_QUEUE_LANE=\" /etc/ai-platform/laptop-queue-worker.env /opt/ai-platform/.env /opt/ai-platform/.secrets/laptop-queue.env" >/tmp/phase12b-queue-lane-env.txt 2>/dev/null; then
  echo "FAIL: CT101 queue lane is persistently configured"
  cat /tmp/phase12b-queue-lane-env.txt
  fail=1
else
  echo "PASS: CT101 queue lane remains unset"
fi

echo
echo "=== live controller status check ==="
curl -sS --max-time 8 -o /tmp/phase12b-controller-health.json -w "health_code=%{http_code} time=%{time_total}\n" http://127.0.0.1:7070/health || fail=1
python3 -m json.tool /tmp/phase12b-controller-health.json >/tmp/phase12b-controller-health.pretty && grep -Fq "\"ok\": true" /tmp/phase12b-controller-health.pretty && echo "PASS: controller health ok" || fail=1
curl -sS --max-time 10 http://127.0.0.1:7070/system/status | python3 -m json.tool >/tmp/phase12b-system-status.json && echo "PASS: /system/status JSON ok" || fail=1
grep -Fq "\"lane_summary\"" /tmp/phase12b-system-status.json && echo "PASS: live system status includes lane_summary" || fail=1

echo
echo "=== router rollout parked guard ==="
if systemctl show edge-queue-controller -p Environment --value | tr " " "\n" | grep -E "ROUTER.*DRY_RUN|PERSISTENT.*ROLLOUT.*ENABLED=1"; then
  echo "FAIL: unexpected router rollout env found"
  fail=1
else
  echo "PASS: no active router rollout env found"
fi

echo
echo "=== changed files guard ==="
bad_status="$(git status --short | grep -vE "^[?][?] docs/phase-12b-node-concurrency-capacity-source-map\.md$" | grep -vE "^[?][?] ops/smoke/check-phase-12b-node-concurrency-capacity-source-map\.sh$" || true)"
git status --short
if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12B doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12B node concurrency capacity source map smoke passed"
else
  echo "FAIL: Phase 12B node concurrency capacity source map smoke failed"
fi

[ "$fail" = "0" ]
