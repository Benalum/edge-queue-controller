#!/usr/bin/env bash
set -u

fail=0
DOC="docs/phase-11z-ct101-worker-repo-versioning-before-dormant-lane-patch.md"
CT101="root@100.88.194.19"

echo "=== Phase 11Z smoke: CT101 worker repo/versioning checkpoint ==="
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== git baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== doc marker checks ==="
grep -Fq "Phase 11Z CT101 Worker Repo Versioning Before Dormant Lane Patch" "$DOC" && echo "PASS: Phase 11Z title found" || fail=1
grep -Fq "CT101 is a git repo." "$DOC" && echo "PASS: git repo doc marker found" || fail=1
grep -Fq "Existing unrelated dirty state was observed before any Phase 11Z patch" "$DOC" && echo "PASS: dirty state doc marker found" || fail=1
grep -Fq "claim payload does not include queue_lane" "$DOC" && echo "PASS: no queue_lane doc marker found" || fail=1
grep -Fq "Phase 11Z does not patch CT101." "$DOC" && echo "PASS: no patch doc marker found" || fail=1
grep -Fq "None in Phase 11Z." "$DOC" && echo "PASS: no runtime changes doc marker found" || fail=1

echo
echo "=== CT101 git repo check ==="
ssh "$CT101" "pct exec 101 -- git -C /opt/ai-platform rev-parse --is-inside-work-tree" >/tmp/phase11z-ct101-git-repo.txt && echo "PASS: CT101 git command worked" || fail=1
grep -Fq "true" /tmp/phase11z-ct101-git-repo.txt && echo "PASS: CT101 /opt/ai-platform is git repo" || fail=1
ssh "$CT101" "pct exec 101 -- git -C /opt/ai-platform rev-parse --short HEAD" >/tmp/phase11z-ct101-head.txt && echo "PASS: CT101 HEAD captured" || fail=1
cat /tmp/phase11z-ct101-head.txt

echo
echo "=== CT101 existing dirty state check ==="
ssh "$CT101" "pct exec 101 -- git -C /opt/ai-platform status --short" >/tmp/phase11z-ct101-status.txt || fail=1
cat /tmp/phase11z-ct101-status.txt
grep -Fq " M docker-compose.yml" /tmp/phase11z-ct101-status.txt && echo "PASS: existing docker-compose dirty state documented" || fail=1
grep -Fq " M ops/ct101-scripts/ai-platform-send-edge-heartbeat" /tmp/phase11z-ct101-status.txt && echo "PASS: existing heartbeat dirty state documented" || fail=1
grep -Fq "?? ops/runtime/" /tmp/phase11z-ct101-status.txt && echo "PASS: existing untracked ops/runtime state documented" || fail=1

echo
echo "=== CT101 target worker source state check ==="
ssh "$CT101" "pct exec 101 -- grep -F \"def claim_one(self, job_type: str = \\\"ollama_chat\\\")\" /opt/ai-platform/backend/app/worker/laptop_queue_client.py" >/dev/null && echo "PASS: CT101 claim_one still has job_type-only signature" || fail=1
ssh "$CT101" "pct exec 101 -- grep -F \"client.claim_one(job_type=job_types[0])\" /opt/ai-platform/ops/smoke/laptop_queue_bounded_synthetic_poller.py" >/dev/null && echo "PASS: CT101 poller still calls claim_one by job_type only" || fail=1
ssh "$CT101" "pct exec 101 -- grep -F \"LAPTOP_QUEUE_MAX_JOBS_PER_RUN must be 1\" /opt/ai-platform/ops/runtime/laptop-queue-worker-preflight.sh" >/dev/null && echo "PASS: CT101 preflight still pins max jobs to 1" || fail=1
if ssh "$CT101" "pct exec 101 -- grep -RInF queue_lane /opt/ai-platform/backend/app/worker/laptop_queue_client.py /opt/ai-platform/ops/smoke/laptop_queue_bounded_synthetic_poller.py /opt/ai-platform/ops/runtime/laptop-queue-worker-loop.sh /opt/ai-platform/ops/runtime/laptop-queue-worker-preflight.sh" >/tmp/phase11z-queue-lane.txt 2>/dev/null; then
  echo "FAIL: CT101 target worker files already reference queue_lane"
  cat /tmp/phase11z-queue-lane.txt
  fail=1
else
  echo "PASS: CT101 target worker files still have no queue_lane references"
fi

echo
echo "=== CT101 worker service still active ==="
ssh "$CT101" "pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service" >/tmp/phase11z-worker-active.txt && echo "PASS: worker service status command worked" || fail=1
grep -Fq "active" /tmp/phase11z-worker-active.txt && echo "PASS: CT101 worker service active" || fail=1

echo
echo "=== changed files guard ==="
bad_status="$(git status --short | grep -vE "^[?][?] docs/phase-11z-ct101-worker-repo-versioning-before-dormant-lane-patch\.md$" | grep -vE "^[?][?] ops/smoke/check-phase-11z-ct101-worker-repo-versioning-before-dormant-lane-patch\.sh$" || true)"
git status --short
if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 11Z doc/smoke files changed"
fi

echo
echo "=== router rollout parked guard ==="
if systemctl show edge-queue-controller -p Environment --value | tr " " "\n" | grep -E "ROUTER.*DRY_RUN|PERSISTENT.*ROLLOUT.*ENABLED=1"; then
  echo "FAIL: unexpected router rollout env found"
  fail=1
else
  echo "PASS: no active router rollout env found"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 11Z CT101 repo/versioning checkpoint smoke passed"
else
  echo "FAIL: Phase 11Z CT101 repo/versioning checkpoint smoke failed"
fi

[ "$fail" = "0" ]
