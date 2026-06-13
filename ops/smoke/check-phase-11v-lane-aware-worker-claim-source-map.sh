#!/usr/bin/env bash
set -u

fail=0
DOC="docs/phase-11v-lane-aware-worker-claim-source-map.md"

echo "=== Phase 11V smoke: lane-aware worker claim source map ==="

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root" || fail=1

echo
echo "=== git baseline ==="
git status --short
git log --oneline -6
git tag --points-at HEAD

echo
echo "=== source checks ==="

if grep -Fq "def claim_next_job" edge_modules/laptop_queue.py; then echo "PASS: claim helper found"; else echo "FAIL: claim helper missing"; fail=1; fi
if grep -Fq "FOR UPDATE SKIP LOCKED" edge_modules/laptop_queue.py; then echo "PASS: skip locked found"; else echo "FAIL: skip locked missing"; fail=1; fi
if grep -Fq "ORDER BY created_at, id" edge_modules/laptop_queue.py; then echo "PASS: claim order found"; else echo "FAIL: claim order missing"; fail=1; fi
if grep -Fq "class _S5E4ClaimRequest" edge_controller.py; then echo "PASS: claim request model found"; else echo "FAIL: claim request model missing"; fail=1; fi
if grep -Fq "/internal/laptop-queue/jobs/claim" edge_controller.py; then echo "PASS: internal claim endpoint found"; else echo "FAIL: internal claim endpoint missing"; fail=1; fi

echo
echo "=== doc checks ==="

if grep -Fq "Phase 11V Lane-Aware Worker Claim Source Map" "$DOC"; then echo "PASS: title found"; else echo "FAIL: title missing"; fail=1; fi
if grep -Fq "Phase 11V is documentation/source-map only" "$DOC"; then echo "PASS: source-map-only marker found"; else echo "FAIL: source-map-only marker missing"; fail=1; fi
if grep -Fq "LaptopQueueClient.claim_next_job(worker_id, job_type=None)" "$DOC"; then echo "PASS: claim helper doc found"; else echo "FAIL: claim helper doc missing"; fail=1; fi
if grep -Fq "There is no queue lane, model lane, model tier, or capacity field yet." "$DOC"; then echo "PASS: no-lane-field marker found"; else echo "FAIL: no-lane-field marker missing"; fail=1; fi
if grep -Fq "LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1" "$DOC"; then echo "PASS: max jobs marker found"; else echo "FAIL: max jobs marker missing"; fail=1; fi
if grep -Fq "If queue_lane is missing, claim behavior remains exactly the same as today." "$DOC"; then echo "PASS: backward compatibility marker found"; else echo "FAIL: backward compatibility marker missing"; fail=1; fi
if grep -Fq "None in Phase 11V." "$DOC"; then echo "PASS: no runtime changes marker found"; else echo "FAIL: no runtime changes marker missing"; fail=1; fi

echo
echo "=== paste artifact guard ==="
if grep -nE "fiecho|==\"\"|^>|mode\.ing|}\s*\"queue_lane\"" "$DOC"; then
  echo "FAIL: paste artifact found in doc"
  fail=1
else
  echo "PASS: no obvious paste artifacts"
fi

echo
echo "=== changed files guard ==="
bad_status="$(git status --short | grep -vE "^[ M?A]{1,2} docs/phase-11v-lane-aware-worker-claim-source-map\.md$" | grep -vE "^[ M?A]{1,2} ops/smoke/check-phase-11v-lane-aware-worker-claim-source-map\.sh$" || true)"
git status --short
if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 11V expected files changed"
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
  echo "PASS: Phase 11V lane-aware worker claim source map smoke passed"
else
  echo "FAIL: Phase 11V lane-aware worker claim source map smoke failed"
fi

[ "$fail" = "0" ]
