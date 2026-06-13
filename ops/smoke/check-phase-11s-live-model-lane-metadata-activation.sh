#!/usr/bin/env bash
set -u

fail=0

echo "=== Phase 11S smoke: live model lane metadata activation ==="

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root" || fail=1

echo
echo "=== git baseline ==="
git status --short
git log --oneline -6
git tag --points-at HEAD

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase11s-smoke-health.out -w "health_code=%{http_code} time=%{time_total}\n" http://127.0.0.1:7070/health || fail=1
cat /tmp/phase11s-smoke-health.out || true
echo

if grep -Fq '"ok":true' /tmp/phase11s-smoke-health.out; then
  echo "PASS: controller health ok"
else
  echo "FAIL: controller health response did not contain ok=true"
  fail=1
fi

echo
echo "=== process freshness ==="
main_pid="$(systemctl show edge-queue-controller -p MainPID --value 2>/dev/null || true)"
module_file="edge_modules/chat_queue_real_user_creation.py"
module_mtime="$(stat -c %Y "$module_file" 2>/dev/null || echo 0)"
proc_start=0

echo "main_pid=$main_pid"
echo "module_mtime=$module_mtime"

if [ -n "$main_pid" ] && [ "$main_pid" != "0" ] && [ -e "/proc/$main_pid" ]; then
  proc_start="$(stat -c %Y "/proc/$main_pid" 2>/dev/null || echo 0)"
  echo "proc_start=$proc_start"

  if [ "$proc_start" -ge "$module_mtime" ]; then
    echo "PASS: live controller process is newer than Phase 11R helper source"
  else
    echo "FAIL: live controller process is older than Phase 11R helper source"
    fail=1
  fi
else
  echo "FAIL: controller MainPID unavailable"
  fail=1
fi

echo
echo "=== source contract markers ==="
python3 -m py_compile edge_modules/chat_queue_real_user_creation.py || fail=1

for marker in \
  "STAGE_5P11R_MODEL_LANE_CONTRACT_BEGIN" \
  "STAGE_5P11R_MODEL_LANE_CONTRACT_END" \
  "\"routing_decision\": routing_decision" \
  "\"model_tier\": routing_decision[\"model_tier\"]" \
  "\"queue_lane\": routing_decision[\"queue_lane\"]"
do
  if grep -Fq "$marker" edge_modules/chat_queue_real_user_creation.py; then
    echo "PASS: marker found: $marker"
  else
    echo "FAIL: marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== database metadata verification ==="
ENV_FILE="${AI_PLATFORM_CONTROLLER_DB_ENV:-$HOME/.config/ai-platform-controller/postgres.env}"

if [ -f "$ENV_FILE" ]; then
  set -a
  . "$ENV_FILE"
  set +a

  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -Atc "
    SELECT
      id || E'\t' ||
      status || E'\t' ||
      COALESCE(requested_model, '') || E'\t' ||
      COALESCE(payload_json->>'routing_contract_version', '') || E'\t' ||
      COALESCE(payload_json->>'model_tier', '') || E'\t' ||
      COALESCE(payload_json->>'model_lane', '') || E'\t' ||
      COALESCE(payload_json->>'queue_lane', '') || E'\t' ||
      COALESCE(payload_json->>'model_max_parallel_hint', '')
    FROM app_jobs
    WHERE payload_json->>'routing_contract_version' = 'stage_5p11r_v1'
      AND payload_json->>'model_tier' = 'tiny'
      AND payload_json->>'model_lane' = 'model-tiny'
      AND payload_json->>'queue_lane' = 'model-tiny'
    ORDER BY created_at DESC
    LIMIT 5;
  " | tee /tmp/phase11s-smoke-jobs.tsv || fail=1

  if grep -Fq $'qwen3:0.6b\tstage_5p11r_v1\ttiny\tmodel-tiny\tmodel-tiny\t4' /tmp/phase11s-smoke-jobs.tsv; then
    echo "PASS: DB contains live Phase 11S tiny lane metadata row"
  else
    echo "FAIL: expected live Phase 11S lane metadata row not found"
    fail=1
  fi
else
  echo "FAIL: controller DB env not found"
  fail=1
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
    | grep -vE '^[ M?A]{1,2} docs/phase-11s-live-model-lane-metadata-activation\.md$' \
    | grep -vE '^[ M?A]{1,2} ops/smoke/check-phase-11s-live-model-lane-metadata-activation\.sh$' \
    || true
)"

git status --short

if [ -n "$bad_status" ]; then
  echo
  echo "FAIL: unexpected changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 11S expected files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 11S live model lane metadata activation smoke passed"
else
  echo "FAIL: Phase 11S live model lane metadata activation smoke failed"
fi

[ "$fail" = "0" ]
