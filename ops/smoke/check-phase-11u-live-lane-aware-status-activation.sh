#!/usr/bin/env bash
set -u

fail=0

echo "=== Phase 11U smoke: live lane-aware status activation ==="

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root" || fail=1

echo
echo "=== git baseline ==="
git status --short
git log --oneline -6
git tag --points-at HEAD

echo
echo "=== source markers ==="
python3 -m py_compile edge_controller.py || fail=1

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
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase11u-smoke-health.json -w "health_code=%{http_code} time=%{time_total}\n" http://127.0.0.1:7070/health || fail=1
cat /tmp/phase11u-smoke-health.json || true
echo

if grep -Fq '"ok":true' /tmp/phase11u-smoke-health.json; then
  echo "PASS: controller health ok"
else
  echo "FAIL: controller health did not contain ok=true"
  fail=1
fi

echo
echo "=== process freshness ==="
main_pid="$(systemctl show edge-queue-controller -p MainPID --value 2>/dev/null || true)"
module_mtime="$(stat -c %Y edge_controller.py 2>/dev/null || echo 0)"
echo "main_pid=$main_pid"
echo "module_mtime=$module_mtime"

if [ -n "$main_pid" ] && [ "$main_pid" != "0" ] && [ -e "/proc/$main_pid" ]; then
  proc_start="$(stat -c %Y "/proc/$main_pid" 2>/dev/null || echo 0)"
  echo "proc_start=$proc_start"
  if [ "$proc_start" -ge "$module_mtime" ]; then
    echo "PASS: live controller process is newer than Phase 11T source"
  else
    echo "FAIL: live controller process is older than Phase 11T source"
    fail=1
  fi
else
  echo "FAIL: controller MainPID unavailable"
  fail=1
fi

echo
echo "=== live /system/status lane summary ==="
curl -sS --max-time 15 -o /tmp/phase11u-smoke-system-status.json http://127.0.0.1:7070/system/status || fail=1

python3 - <<'PY' || fail=1
import json
from pathlib import Path

text = Path("/tmp/phase11u-smoke-system-status.json").read_text(errors="replace")
data = json.loads(text)

matches = []

def walk(obj, path=""):
    if isinstance(obj, dict):
        if "lane_summary" in obj:
            matches.append((path, obj["lane_summary"]))
        for key, value in obj.items():
            walk(value, f"{path}.{key}" if path else str(key))
    elif isinstance(obj, list):
        for idx, value in enumerate(obj):
            walk(value, f"{path}[{idx}]")

walk(data)

if not matches:
    print("FAIL: no lane_summary found in /system/status")
    raise SystemExit(1)

found_keys = False
found_tiny = False

for path, summary in matches:
    if not isinstance(summary, dict):
        continue
    if "active_by_queue_lane" in summary and "by_status_tier_lane" in summary:
        found_keys = True
    for row in summary.get("by_status_tier_lane") or []:
        if not isinstance(row, dict):
            continue
        if (
            row.get("model_tier") == "tiny"
            and row.get("model_lane") == "model-tiny"
            and row.get("queue_lane") == "model-tiny"
            and row.get("requested_model") == "qwen3:0.6b"
        ):
            found_tiny = True

if not found_keys:
    print("FAIL: lane_summary missing expected keys")
    raise SystemExit(1)

if not found_tiny:
    print("FAIL: lane_summary missing tiny qwen3:0.6b row")
    raise SystemExit(1)

print("PASS: lane_summary contains expected keys and tiny model lane row")
PY

echo
echo "=== DB lane summary still present ==="
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
  " | tee /tmp/phase11u-smoke-db-lanes.tsv || fail=1

  if grep -Fq $'complete\ttiny\tmodel-tiny\tmodel-tiny\tqwen3:0.6b' /tmp/phase11u-smoke-db-lanes.tsv; then
    echo "PASS: DB still contains tiny model lane summary row"
  else
    echo "FAIL: expected tiny model lane DB row not found"
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
    | grep -vE '^[ M?A]{1,2} docs/phase-11u-live-lane-aware-status-activation\.md$' \
    | grep -vE '^[ M?A]{1,2} ops/smoke/check-phase-11u-live-lane-aware-status-activation\.sh$' \
    || true
)"

git status --short

if [ -n "$bad_status" ]; then
  echo
  echo "FAIL: unexpected changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 11U expected files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 11U live lane-aware status activation smoke passed"
else
  echo "FAIL: Phase 11U live lane-aware status activation smoke failed"
fi

[ "$fail" = "0" ]
