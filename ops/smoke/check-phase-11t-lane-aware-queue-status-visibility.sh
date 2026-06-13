#!/usr/bin/env bash
set -u

fail=0

echo "=== Phase 11T smoke: lane-aware queue status visibility ==="

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root" || fail=1

echo
echo "=== git baseline ==="
git status --short
git log --oneline -6
git tag --points-at HEAD

echo
echo "=== syntax ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== source markers ==="
for marker in \
  "STAGE_5P11T_LANE_AWARE_QUEUE_VISIBILITY_BEGIN" \
  "STAGE_5P11T_LANE_AWARE_QUEUE_VISIBILITY_END" \
  "_stage5p11t_app_jobs_lane_summary" \
  '"lane_summary": _stage5p11t_app_jobs_lane_summary()' \
  "by_status_tier_lane" \
  "active_by_queue_lane"
do
  if grep -Fq "$marker" edge_controller.py; then
    echo "PASS: marker found: $marker"
  else
    echo "FAIL: marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== DB lane summary query ==="
ENV_FILE="${AI_PLATFORM_CONTROLLER_DB_ENV:-$HOME/.config/ai-platform-controller/postgres.env}"

if [ -f "$ENV_FILE" ]; then
  set -a
  . "$ENV_FILE"
  set +a

  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -Atc "
    SELECT
      status || E'\t' ||
      COALESCE(payload_json->>'model_tier', '(none)') || E'\t' ||
      COALESCE(payload_json->>'model_lane', '(none)') || E'\t' ||
      COALESCE(payload_json->>'queue_lane', '(none)') || E'\t' ||
      COALESCE(requested_model, '(none)') || E'\t' ||
      COUNT(*)::text
    FROM app_jobs
    WHERE job_type = 'ollama_chat'
    GROUP BY
      status,
      COALESCE(payload_json->>'model_tier', '(none)'),
      COALESCE(payload_json->>'model_lane', '(none)'),
      COALESCE(payload_json->>'queue_lane', '(none)'),
      COALESCE(requested_model, '(none)')
    ORDER BY
      status,
      COALESCE(payload_json->>'model_tier', '(none)'),
      COALESCE(payload_json->>'model_lane', '(none)'),
      COALESCE(payload_json->>'queue_lane', '(none)'),
      COALESCE(requested_model, '(none)');
  " | tee /tmp/phase11t-lane-summary.tsv || fail=1

  if grep -Fq $'complete\ttiny\tmodel-tiny\tmodel-tiny\tqwen3:0.6b' /tmp/phase11t-lane-summary.tsv; then
    echo "PASS: DB contains tiny model lane summary row"
  else
    echo "FAIL: expected tiny model lane row not found"
    fail=1
  fi
else
  echo "FAIL: controller DB env not found"
  fail=1
fi

echo
echo "=== no schema/scheduling/runtime mutation guard ==="
if git diff -- edge_controller.py docs/phase-11t-lane-aware-queue-status-visibility.md ops/smoke/check-phase-11t-lane-aware-queue-status-visibility.sh \
  | grep -E 'ALTER TABLE|claim_next_job|OLLAMA_NUM_PARALLEL|MAX_JOBS_PER_RUN|WORKER_POLL_SECONDS|FOR UPDATE SKIP LOCKED|status = .running'; then
  echo "FAIL: schema/scheduling/runtime mutation marker found"
  fail=1
else
  echo "PASS: no schema/scheduling/runtime mutation markers found"
fi

echo
echo "=== router rollout parked guards ==="
if systemctl show edge-queue-controller -p Environment --value | tr ' ' '\n' | grep -E 'ROUTER.*DRY_RUN|PERSISTENT.*ROLLOUT.*ENABLED=1'; then
  echo "FAIL: unexpected router rollout env found"
  fail=1
else
  echo "PASS: no active router rollout env found"
fi

echo
echo "=== changed files guard ==="
bad_status="$(
  git status --short \
    | grep -vE '^[ M?A]{1,2} edge_controller\.py$' \
    | grep -vE '^[ M?A]{1,2} docs/phase-11t-lane-aware-queue-status-visibility\.md$' \
    | grep -vE '^[ M?A]{1,2} ops/smoke/check-phase-11t-lane-aware-queue-status-visibility\.sh$' \
    || true
)"

git status --short

if [ -n "$bad_status" ]; then
  echo
  echo "FAIL: unexpected changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 11T expected files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 11T lane-aware queue status visibility smoke passed"
else
  echo "FAIL: Phase 11T lane-aware queue status visibility smoke failed"
fi

[ "$fail" = "0" ]
