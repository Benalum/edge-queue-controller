#!/usr/bin/env bash
set -u

fail=0
DOC="docs/phase-11y-ct101-worker-side-lane-claim-source-map.md"
CT101="root@100.88.194.19"

echo "=== Phase 11Y smoke: CT101 worker-side lane claim source map ==="
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== git baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== local checkpoint markers ==="
grep -Fq "STAGE_5P11W_OPTIONAL_QUEUE_LANE_CLAIM_BEGIN" edge_modules/laptop_queue.py && echo "PASS: Phase 11W local source marker found" || fail=1
grep -Fq "Phase 11X Live Optional Queue Lane Claim Endpoint Activation" docs/phase-11x-live-optional-queue-lane-claim-endpoint-activation.md && echo "PASS: Phase 11X doc marker found" || fail=1

echo
echo "=== doc marker checks ==="
grep -Fq "Phase 11Y CT101 Worker-Side Lane Claim Source Map" "$DOC" && echo "PASS: Phase 11Y title found" || fail=1
grep -Fq "Phase 11Y is documentation/source-map only." "$DOC" && echo "PASS: source-map-only marker found" || fail=1
grep -Fq "Observed method: claim_one(self, job_type=\"ollama_chat\")." "$DOC" && echo "PASS: claim_one doc marker found" || fail=1
grep -Fq "Current claim payload does not send queue_lane." "$DOC" && echo "PASS: no queue_lane payload doc marker found" || fail=1
grep -Fq "The bounded poller calls client.claim_one(job_type=job_types[0])." "$DOC" && echo "PASS: poller claim doc marker found" || fail=1
grep -Fq "CT101 still uses LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1 through preflight." "$DOC" && echo "PASS: max jobs doc marker found" || fail=1
grep -Fq "None in Phase 11Y." "$DOC" && echo "PASS: no runtime changes doc marker found" || fail=1
grep -Fq "This phase is inspection/documentation only." "$DOC" && echo "PASS: inspection-only doc marker found" || fail=1

echo
echo "=== CT101 static source checks over SSH ==="
ssh "$CT101" "pct exec 101 -- grep -F \"def claim_one\" /opt/ai-platform/backend/app/worker/laptop_queue_client.py" >/tmp/phase11y-claim-one.txt && echo "PASS: CT101 claim_one method found" || fail=1
grep -Fq "job_type" /tmp/phase11y-claim-one.txt && echo "PASS: CT101 claim_one still uses job_type signature" || fail=1
ssh "$CT101" "pct exec 101 -- grep -F \"worker_id\" /opt/ai-platform/backend/app/worker/laptop_queue_client.py" >/dev/null && echo "PASS: CT101 client references worker_id" || fail=1
ssh "$CT101" "pct exec 101 -- grep -F \"job_type\" /opt/ai-platform/backend/app/worker/laptop_queue_client.py" >/dev/null && echo "PASS: CT101 client references job_type" || fail=1
ssh "$CT101" "pct exec 101 -- grep -F \"client.claim_one(job_type=job_types[0])\" /opt/ai-platform/ops/smoke/laptop_queue_bounded_synthetic_poller.py" >/dev/null && echo "PASS: CT101 bounded poller claims by job_type only" || fail=1
ssh "$CT101" "pct exec 101 -- grep -F \"python3 ops/smoke/laptop_queue_bounded_synthetic_poller.py\" /opt/ai-platform/ops/runtime/laptop-queue-worker-loop.sh" >/dev/null && echo "PASS: CT101 loop runs bounded poller" || fail=1
ssh "$CT101" "pct exec 101 -- grep -F \"LAPTOP_QUEUE_MAX_JOBS_PER_RUN must be 1\" /opt/ai-platform/ops/runtime/laptop-queue-worker-preflight.sh" >/dev/null && echo "PASS: CT101 preflight keeps max jobs at 1" || fail=1
if ssh "$CT101" "pct exec 101 -- grep -RInF queue_lane /opt/ai-platform/backend/app/worker /opt/ai-platform/ops/runtime /opt/ai-platform/ops/smoke/laptop_queue_bounded_synthetic_poller.py" >/tmp/phase11y-queue-lane.txt 2>/dev/null; then
  echo "FAIL: CT101 worker path already references queue_lane"
  cat /tmp/phase11y-queue-lane.txt
  fail=1
else
  echo "PASS: CT101 worker path has no queue_lane references"
fi

echo
echo "=== changed files guard ==="
bad_status="$(git status --short | grep -vE "^[?][?] docs/phase-11y-ct101-worker-side-lane-claim-source-map\.md$" | grep -vE "^[?][?] ops/smoke/check-phase-11y-ct101-worker-side-lane-claim-source-map\.sh$" || true)"
git status --short
if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 11Y doc/smoke files changed"
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
  echo "PASS: Phase 11Y CT101 worker-side lane claim source map smoke passed"
else
  echo "FAIL: Phase 11Y CT101 worker-side lane claim source map smoke failed"
fi

[ "$fail" = "0" ]
