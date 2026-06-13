#!/usr/bin/env bash
set -u

fail=0

echo "=== Phase 11W smoke: optional queue_lane claim support ==="

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root" || fail=1

DOC="docs/phase-11w-optional-queue-lane-claim-support.md"

echo
echo "=== git baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== syntax check ==="
python3 -m py_compile edge_modules/laptop_queue.py edge_controller.py || fail=1

echo
echo "=== source marker checks ==="
for marker in \
  "STAGE_5P11W_OPTIONAL_QUEUE_LANE_CLAIM_BEGIN" \
  "STAGE_5P11W_OPTIONAL_QUEUE_LANE_CLAIM_END" \
  "queue_lane_filter" \
  "payload_json->>'queue_lane'" \
  "queue_lane: str | None = None" \
  "queue_lane=request.queue_lane"
do
  if grep -R -Fq "$marker" edge_modules/laptop_queue.py edge_controller.py; then
    echo "PASS: source marker found: $marker"
  else
    echo "FAIL: source marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== doc marker checks ==="
for marker in \
  "Phase 11W Optional Queue Lane Claim Support" \
  "queue_lane is optional." \
  "If queue_lane is omitted, claim behavior remains the same as before Phase 11W." \
  "This phase does not change CT101 worker behavior." \
  "This phase does not restart the controller." \
  "Phase 11X should perform guarded live activation"
do
  if grep -Fq "$marker" "$DOC"; then
    echo "PASS: doc marker found: $marker"
  else
    echo "FAIL: doc marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== runtime/concurrency guard ==="
if git diff -- edge_modules/laptop_queue.py edge_controller.py docs/phase-11w-optional-queue-lane-claim-support.md ops/smoke/check-phase-11w-optional-queue-lane-claim-support.sh \
  | grep -E 'LAPTOP_QUEUE_MAX_JOBS_PER_RUN=|OLLAMA_NUM_PARALLEL|systemctl restart|docker compose|pct exec|ALTER TABLE'; then
  echo "FAIL: forbidden runtime/concurrency/schema marker found in Phase 11W diff"
  fail=1
else
  echo "PASS: no forbidden runtime/concurrency/schema markers found"
fi

echo
echo "=== direct helper synthetic queue_lane claim behavior ==="
python3 - <<'PYSMOKE'
import json
import time

from edge_modules.laptop_queue import LaptopQueueClient

suffix = f"p11w-{int(time.time())}"
user_id = f"s5p11w-user-{suffix}"
node_id = f"s5p11w-node-{suffix}"
worker_id = f"s5p11w-worker-{suffix}"
job_tiny = f"s5p11w-job-tiny-{suffix}"
job_small = f"s5p11w-job-small-{suffix}"
job_ids = [job_tiny, job_small]

client = LaptopQueueClient()

try:
    client.cleanup_synthetic(
        user_id=user_id,
        node_id=node_id,
        worker_id=worker_id,
        job_ids=job_ids,
    )

    client.create_synthetic_user(
        user_id=user_id,
        email=f"{user_id}@example.local",
        display_name="Stage 5P11W Synthetic User",
    )

    client.create_synthetic_worker_node(
        node_id=node_id,
        name="Stage 5P11W Synthetic Node",
        capabilities={"job_types": ["ollama_chat"], "lanes": ["model-tiny", "model-small"]},
    )

    client.create_synthetic_worker(
        worker_id=worker_id,
        node_id=node_id,
        name="Stage 5P11W Synthetic Worker",
        capabilities={"job_types": ["ollama_chat"], "lanes": ["model-tiny", "model-small"]},
    )

    client.create_job(
        job_id=job_tiny,
        user_id=user_id,
        job_type="ollama_chat",
        requested_model="qwen3:0.6b",
        payload={"prompt": "phase 11w tiny lane job", "queue_lane": "model-tiny"},
    )

    client.create_job(
        job_id=job_small,
        user_id=user_id,
        job_type="ollama_chat",
        requested_model="qwen3:1.7b",
        payload={"prompt": "phase 11w small lane job", "queue_lane": "model-small"},
    )

    claimed_small = client.claim_next_job(
        worker_id=worker_id,
        job_type="ollama_chat",
        queue_lane="model-small",
    )

    if not claimed_small:
        raise RuntimeError("queue_lane=model-small claim returned no job")

    if claimed_small.get("id") != job_small:
        raise RuntimeError(f"queue_lane=model-small claimed wrong job: {claimed_small}")

    payload = claimed_small.get("payload_json") or {}
    if isinstance(payload, str):
        payload = json.loads(payload)

    if payload.get("queue_lane") != "model-small":
        raise RuntimeError(f"claimed small job has wrong queue_lane payload: {payload}")

    client.complete_job(
        job_id=job_small,
        worker_id=worker_id,
        ok=True,
        result={"source": "phase_11w_smoke", "claimed_lane": "model-small"},
    )

    claimed_next = client.claim_next_job(
        worker_id=worker_id,
        job_type="ollama_chat",
    )

    if not claimed_next:
        raise RuntimeError("backward-compatible claim without queue_lane returned no job")

    if claimed_next.get("id") != job_tiny:
        raise RuntimeError(f"claim without queue_lane claimed wrong remaining job: {claimed_next}")

    payload = claimed_next.get("payload_json") or {}
    if isinstance(payload, str):
        payload = json.loads(payload)

    if payload.get("queue_lane") != "model-tiny":
        raise RuntimeError(f"claimed tiny job has wrong queue_lane payload: {payload}")

    client.complete_job(
        job_id=job_tiny,
        worker_id=worker_id,
        ok=True,
        result={"source": "phase_11w_smoke", "claimed_without_lane": True},
    )

    print("PASS: queue_lane filtered claim and backward-compatible claim both worked")

finally:
    client.cleanup_synthetic(
        user_id=user_id,
        node_id=node_id,
        worker_id=worker_id,
        job_ids=job_ids,
    )
    leftover = client.synthetic_leftover_count(
        user_id=user_id,
        node_id=node_id,
        worker_id=worker_id,
        job_ids=job_ids,
    )
    if leftover:
        raise RuntimeError(f"synthetic cleanup left {leftover} row(s)")
    print("PASS: synthetic rows cleaned up")
PYSMOKE

helper_rc="$?"
if [ "$helper_rc" != "0" ]; then
  echo "FAIL: direct helper synthetic queue_lane claim behavior failed"
  fail=1
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
echo "=== changed files guard ==="
bad_status="$(
  git status --short \
    | grep -vE '^[ M]{1,2} edge_controller\.py$' \
    | grep -vE '^[ M]{1,2} edge_modules/laptop_queue\.py$' \
    | grep -vE '^[ M?A]{1,2} docs/phase-11w-optional-queue-lane-claim-support\.md$' \
    | grep -vE '^[ M?A]{1,2} ops/smoke/check-phase-11w-optional-queue-lane-claim-support\.sh$' \
    || true
)"

git status --short

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 11W expected files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 11W optional queue_lane claim support smoke passed"
else
  echo "FAIL: Phase 11W optional queue_lane claim support smoke failed"
fi

[ "$fail" = "0" ]
