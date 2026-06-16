#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BR reusable smoke: runtime-parked surface static contracts ==="
echo "MUTATION_SCOPE=read_only_static_contracts"
echo "NO service restart/reload"
echo "NO DB mutation"
echo "NO job mutation"
echo "NO CT101 call"
echo "NO model/Ollama endpoint call"
echo "NO scheduler activation"
echo "NO worker activation"
echo "NO runtime activation"

DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller"

test -f edge_controller.py
python3 -m py_compile edge_controller.py
echo "PASS: edge_controller.py compiles"

echo
echo "=== lane activation source markers ==="
for marker in \
  "def _phase14j_lane_workers_enabled" \
  "def _phase14j_default_off_worker_registration_metadata" \
  "def _phase14j_job_lane_metadata" \
  "def _phase14j_worker_lane_metadata" \
  "def _phase14j_worker_eligible_for_job" \
  "def _phase14j_filter_workers_for_lane" \
  "phase14j_lane_scheduler_gate_enabled = _phase14j_lane_workers_enabled()" \
  "workers = _phase14j_filter_workers_for_lane(workers, job)" \
  "registration_metadata = _phase14j_default_off_worker_registration_metadata()" \
  "\"reason_code\": \"lane_gate_disabled\""
do
  grep -F "$marker" edge_controller.py >/dev/null
  echo "PASS: marker present: $marker"
done

echo
echo "=== parked router/warmup/model risk markers, static only ==="
router_hits="$(grep -RIn --exclude-dir=.git --exclude-dir=.cleanup-archive --exclude-dir=.cleanup-backups --exclude='*.sqlite3' --exclude='*.db' -E 'router|warmup|Ollama|ollama|model selection|model_selection' . 2>/dev/null | wc -l | tr -d ' ')"
printf 'router_warmup_static_hits=%s\n' "$router_hits"
echo "PASS: router/warmup/model surface counted statically only"

echo
echo "=== SQLite read-only quick_check and worker default-off ==="
quick_check="$(sqlite3 "file:${DB}?mode=ro" 'PRAGMA quick_check;')"
worker_count="$(sqlite3 "file:${DB}?mode=ro" 'SELECT COUNT(*) FROM workers;')"
lane_enabled_worker_count="$(sqlite3 "file:${DB}?mode=ro" "SELECT COALESCE(SUM(CASE WHEN COALESCE(accepts_lane_jobs,0) NOT IN (0,'0','false','False','') THEN 1 ELSE 0 END),0) FROM workers;")"
non_default_worker_lane_count="$(sqlite3 "file:${DB}?mode=ro" "SELECT COALESCE(SUM(CASE WHEN COALESCE(worker_lane,'primary') <> 'primary' THEN 1 ELSE 0 END),0) FROM workers;")"
non_primary_worker_role_count="$(sqlite3 "file:${DB}?mode=ro" "SELECT COALESCE(SUM(CASE WHEN COALESCE(worker_role,'primary') <> 'primary' THEN 1 ELSE 0 END),0) FROM workers;")"

printf 'quick_check=%s\n' "$quick_check"
printf 'worker_count=%s\n' "$worker_count"
printf 'lane_enabled_worker_count=%s\n' "$lane_enabled_worker_count"
printf 'non_default_worker_lane_count=%s\n' "$non_default_worker_lane_count"
printf 'non_primary_worker_role_count=%s\n' "$non_primary_worker_role_count"

test "$quick_check" = "ok"
test "$worker_count" = "0"
test "$lane_enabled_worker_count" = "0"
test "$non_default_worker_lane_count" = "0"
test "$non_primary_worker_role_count" = "0"

echo
echo "=== persistent lane worker flag guard ==="
shell_flag="${EDGE_PERSISTENT_LANE_WORKERS_ENABLED:-}"
printf 'shell_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=%s\n' "${shell_flag:-<unset>}"

case "${shell_flag,,}" in
  ""|"0"|"false"|"no"|"off")
    echo "PASS: shell persistent lane worker flag absent/disabled"
    ;;
  *)
    echo "FAIL: shell persistent lane worker flag appears enabled"
    exit 1
    ;;
esac

service_env="$(systemctl show "$SERVICE" -p Environment --value 2>/dev/null || true)"
service_flag="$(printf '%s\n' "$service_env" | tr ' ' '\n' | grep -E '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=' || true)"
printf 'service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=%s\n' "${service_flag:-<unset>}"

if [ -z "$service_flag" ]; then
  echo "PASS: service persistent lane worker flag absent"
else
  service_value="${service_flag#*=}"
  case "${service_value,,}" in
    ""|"0"|"false"|"no"|"off")
      echo "PASS: service persistent lane worker flag disabled"
      ;;
    *)
      echo "FAIL: service persistent lane worker flag appears enabled"
      exit 1
      ;;
  esac
fi

echo
echo "PASS: runtime-parked static contracts remain default-off"
