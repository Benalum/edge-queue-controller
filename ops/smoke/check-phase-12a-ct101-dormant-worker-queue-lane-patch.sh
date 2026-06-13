#!/usr/bin/env bash
set -u

fail=0
DOC="docs/phase-12a-ct101-dormant-worker-queue-lane-patch.md"
CT101="root@100.88.194.19"
TAG="ai-platform-phase-12a-dormant-worker-queue-lane-2026-06-13"

echo "=== Phase 12A smoke: CT101 dormant worker queue_lane patch checkpoint ==="
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== local git baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== doc marker checks ==="
grep -Fq "Phase 12A CT101 Dormant Worker Queue Lane Patch" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "CT101 commit: bc829ca" "$DOC" && echo "PASS: CT101 commit doc marker found" || fail=1
grep -Fq "CT101 tag: ai-platform-phase-12a-dormant-worker-queue-lane-2026-06-13" "$DOC" && echo "PASS: CT101 tag doc marker found" || fail=1
grep -Fq "LAPTOP_QUEUE_QUEUE_LANE remains unset" "$DOC" && echo "PASS: dormant env doc marker found" || fail=1
grep -Fq "LAPTOP_QUEUE_MAX_JOBS_PER_RUN remains pinned to 1" "$DOC" && echo "PASS: max jobs doc marker found" || fail=1
grep -Fq "Only the two intended CT101 target files were staged and committed." "$DOC" && echo "PASS: staged target doc marker found" || fail=1

echo
echo "=== CT101 git commit/tag verification ==="
ssh "$CT101" "pct exec 101 -- git -C /opt/ai-platform rev-parse --short HEAD" >/tmp/phase12a-ai-head.txt && echo "PASS: CT101 HEAD captured" || fail=1
cat /tmp/phase12a-ai-head.txt
grep -Fq "bc829ca" /tmp/phase12a-ai-head.txt && echo "PASS: CT101 HEAD is Phase 12A commit" || fail=1
ssh "$CT101" "pct exec 101 -- git -C /opt/ai-platform tag --points-at HEAD" >/tmp/phase12a-ai-tags.txt && echo "PASS: CT101 tags captured" || fail=1
cat /tmp/phase12a-ai-tags.txt
grep -Fq "$TAG" /tmp/phase12a-ai-tags.txt && echo "PASS: CT101 Phase 12A tag points at HEAD" || fail=1

echo
echo "=== CT101 marker and syntax verification ==="
ssh "$CT101" "pct exec 101 -- grep -RInF STAGE_5P12A_DORMANT_WORKER_QUEUE_LANE /opt/ai-platform/backend/app/worker/laptop_queue_client.py /opt/ai-platform/ops/smoke/laptop_queue_bounded_synthetic_poller.py" >/tmp/phase12a-markers.txt && echo "PASS: CT101 Phase 12A markers found" || fail=1
cat /tmp/phase12a-markers.txt
ssh "$CT101" "pct exec 101 -- python3 -m py_compile /opt/ai-platform/backend/app/worker/laptop_queue_client.py /opt/ai-platform/ops/smoke/laptop_queue_bounded_synthetic_poller.py" && echo "PASS: CT101 target py_compile ok" || fail=1

echo
echo "=== CT101 dormant env/max-jobs verification ==="
if ssh "$CT101" "pct exec 101 -- grep -RInE \"^LAPTOP_QUEUE_QUEUE_LANE=\" /opt/ai-platform/.env /opt/ai-platform/.secrets/laptop-queue.env /etc/ai-platform/laptop-queue-worker.env" >/tmp/phase12a-env.txt 2>/dev/null; then
  echo "FAIL: LAPTOP_QUEUE_QUEUE_LANE is persistently configured"
  cat /tmp/phase12a-env.txt
  fail=1
else
  echo "PASS: LAPTOP_QUEUE_QUEUE_LANE remains unset"
fi
ssh "$CT101" "pct exec 101 -- grep -nF \"LAPTOP_QUEUE_MAX_JOBS_PER_RUN must be 1\" /opt/ai-platform/ops/runtime/laptop-queue-worker-preflight.sh" && echo "PASS: max jobs preflight guard remains" || fail=1

echo
echo "=== CT101 remaining dirty state verification ==="
ssh "$CT101" "pct exec 101 -- git -C /opt/ai-platform status --short" >/tmp/phase12a-ai-status.txt && echo "PASS: CT101 status captured" || fail=1
cat /tmp/phase12a-ai-status.txt
if grep -Fq "backend/app/worker/laptop_queue_client.py" /tmp/phase12a-ai-status.txt; then echo "FAIL: client target file still dirty after commit"; fail=1; else echo "PASS: client target file clean after CT101 commit"; fi
if grep -Fq "ops/smoke/laptop_queue_bounded_synthetic_poller.py" /tmp/phase12a-ai-status.txt; then echo "FAIL: poller target file still dirty after commit"; fail=1; else echo "PASS: poller target file clean after CT101 commit"; fi
grep -Fq " M docker-compose.yml" /tmp/phase12a-ai-status.txt && echo "PASS: unrelated docker-compose dirty state remains unstaged/uncommitted" || fail=1
grep -Fq " M ops/ct101-scripts/ai-platform-send-edge-heartbeat" /tmp/phase12a-ai-status.txt && echo "PASS: unrelated heartbeat dirty state remains unstaged/uncommitted" || fail=1

echo
echo "=== CT101 worker active/no-restart-state check ==="
ssh "$CT101" "pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service" >/tmp/phase12a-worker-active.txt && echo "PASS: worker service status command worked" || fail=1
grep -Fq "active" /tmp/phase12a-worker-active.txt && echo "PASS: CT101 worker service active" || fail=1
ssh "$CT101" "pct exec 101 -- systemctl show ai-platform-laptop-queue-worker.service -p MainPID -p ActiveState -p SubState --no-pager"

echo
echo "=== local controller health/router guard ==="
curl -sS --max-time 8 -o /tmp/phase12a-controller-health.json -w "health_code=%{http_code} time=%{time_total}\n" http://127.0.0.1:7070/health || fail=1
python3 -c "import json; d=json.load(open(\"/tmp/phase12a-controller-health.json\")); assert d.get(\"ok\") is True; print(\"PASS: controller health ok\")" || fail=1
if systemctl show edge-queue-controller -p Environment --value | tr " " "\n" | grep -E "ROUTER.*DRY_RUN|PERSISTENT.*ROLLOUT.*ENABLED=1"; then
  echo "FAIL: unexpected router rollout env found"
  fail=1
else
  echo "PASS: no active router rollout env found"
fi

echo
echo "=== changed files guard ==="
bad_status="$(git status --short | grep -vE "^[?][?] docs/phase-12a-ct101-dormant-worker-queue-lane-patch\.md$" | grep -vE "^[?][?] ops/smoke/check-phase-12a-ct101-dormant-worker-queue-lane-patch\.sh$" || true)"
git status --short
if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12A controller doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12A controller checkpoint smoke passed"
else
  echo "FAIL: Phase 12A controller checkpoint smoke failed"
fi

[ "$fail" = "0" ]
