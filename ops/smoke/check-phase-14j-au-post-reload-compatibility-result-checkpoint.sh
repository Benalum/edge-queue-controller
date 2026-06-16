#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-AU smoke: post-reload compatibility result checkpoint ==="

DOC="docs/phase-14j-au-post-reload-compatibility-result-checkpoint.md"
DB="edge_queue.sqlite3"
fail=0

echo
echo "=== required artifacts ==="
for p in \
  "$DOC" \
  "docs/phase-14j-aq-controller-service-reload-readiness-plan.md" \
  "ops/smoke/check-phase-14j-aq-controller-service-reload-readiness-plan.sh" \
  "docs/phase-14j-ao-default-off-worker-registration-update-preserve-existing-metadata-wiring-patch.md" \
  "ops/smoke/check-phase-14j-ao-default-off-worker-registration-update-preserve-existing-metadata-wiring-patch.sh" \
  "ops/db/default-off-worker-registry-lane-metadata.sql" \
  "$DB"
do
  if [ -e "$p" ]; then
    echo "PASS: exists $p"
  else
    echo "FAIL: missing $p"
    fail=1
  fi
done

echo
echo "=== documentation markers ==="
python3 - <<'APC_AU_DOC_CHECK'
from pathlib import Path

text = Path("docs/phase-14j-au-post-reload-compatibility-result-checkpoint.md").read_text()
required = [
    "This phase is documentation and smoke only.",
    "Phase 14J-AS status: controller service restart completed successfully",
    "Phase 14J-AT status: read-only post-reload worker registration compatibility inspection completed successfully",
    "controller-only local health returned `200`",
    "no lane-enabled workers exist",
    "no recent traceback/sqlite/500 errors were detected",
    "Post-reload compatibility evidence is not lane dispatch activation.",
    "Phase 14J-AV worker registration compatibility closeout and next-lane-readiness plan, docs/smoke only",
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing))
print("PASS: documentation markers verified")
APC_AU_DOC_CHECK

echo
echo "=== compile check ==="
python3 - <<'APC_AU_COMPILE'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py compiles via in-memory compile")
APC_AU_COMPILE

echo
echo "=== static source validation ==="
python3 - <<'APC_AU_SOURCE'
from pathlib import Path
import ast
import re

text = Path("edge_controller.py").read_text()
helper = "_phase14j_default_off_worker_registration_metadata"

if text.count(f"def {helper}(") != 1:
    raise SystemExit("FAIL: expected exactly one helper definition")
if text.count(f"{helper}(") != 3:
    raise SystemExit("FAIL: expected helper definition plus INSERT and UPDATE calls")

tree = ast.parse(text)
func = next((n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == helper), None)
if func is None:
    raise SystemExit("FAIL: helper not found")

module = ast.Module(body=[func], type_ignores=[])
ast.fix_missing_locations(module)
ns = {}
exec(compile(module, "au_helper_only", "exec"), ns)

expected = {
    "worker_role": "primary",
    "worker_lane": "",
    "accepts_lane_jobs": 0,
    "capabilities": "[]",
    "disabled": 0,
    "current_running_jobs": 0,
    "state": "available",
    "computed_health": "",
}
if ns[helper]() != expected:
    raise SystemExit("FAIL: helper defaults changed")

start = text.index("@app.post(\"/workers/heartbeat\")")
end = text.index("@app.get(\"/workers/registry\")", start)
window = text[start:end]
update_branch, insert_branch = window.split("        else:", 1)

for line in [
    "worker_role = COALESCE(worker_role, ?)",
    "worker_lane = COALESCE(worker_lane, ?)",
    "accepts_lane_jobs = COALESCE(accepts_lane_jobs, ?)",
    "capabilities = COALESCE(capabilities, ?)",
    "disabled = COALESCE(disabled, ?)",
    "current_running_jobs = COALESCE(current_running_jobs, ?)",
    "state = COALESCE(state, ?)",
    "computed_health = COALESCE(computed_health, ?)",
]:
    if line not in update_branch:
        raise SystemExit(f"FAIL: UPDATE branch missing {line}")

insert_match = re.search(r"INSERT INTO workers\s*\((.*?)\)\s*VALUES\s*\((.*?)\)", insert_branch, re.S)
if not insert_match:
    raise SystemExit("FAIL: could not parse INSERT block")
if len([c.strip() for c in insert_match.group(1).split(",") if c.strip()]) != 29:
    raise SystemExit("FAIL: INSERT column count changed")
if insert_match.group(2).count("?") != 29:
    raise SystemExit("FAIL: INSERT placeholder count changed")

for forbidden in [
    "payload.worker_role",
    "payload.worker_lane",
    "payload.accepts_lane_jobs",
    "payload.disabled",
    "payload.current_running_jobs",
    "payload.computed_health",
]:
    if forbidden in window:
        raise SystemExit(f"FAIL: worker payload lane metadata unexpectedly consumed: {forbidden}")

print("PASS: static source validation passed")
APC_AU_SOURCE

echo
echo "=== service and health read-only check ==="
service_active="$(systemctl is-active edge-queue-controller 2>/dev/null || true)"
echo "service_active=${service_active:-unknown}"
if [ "$service_active" = "active" ]; then
  echo "PASS: edge-queue-controller active"
else
  echo "FAIL: edge-queue-controller not active"
  fail=1
fi

health_code="$(
  curl -sS --max-time 5 -o /tmp/phase14j-au-local-health.json \
    -w "%{http_code}" \
    http://127.0.0.1:7070/system/local-health 2>/tmp/phase14j-au-local-health.err || true
)"
echo "local_health_http_code=${health_code:-curl_failed}"
if [ "$health_code" = "200" ]; then
  echo "PASS: controller-only local health returned 200"
else
  echo "FAIL: controller-only local health did not return 200"
  fail=1
fi

echo
echo "=== persistent lane worker flag remains disabled ==="
echo "shell_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=${EDGE_PERSISTENT_LANE_WORKERS_ENABLED-<unset>}"
case "${EDGE_PERSISTENT_LANE_WORKERS_ENABLED-}" in
  1|true|TRUE)
    echo "FAIL: shell persistent lane workers flag appears enabled"
    fail=1
    ;;
  *)
    echo "PASS: shell persistent lane workers flag absent/disabled"
    ;;
esac

service_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
printf '%s\n' "$service_env" | tr ' ' '\n' | grep -q '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=\(1\|true\|TRUE\)$' \
  && { echo "FAIL: service persistent lane workers flag appears enabled"; fail=1; } \
  || echo "PASS: service persistent lane workers flag absent/disabled"

echo
echo "=== read-only SQLite state ==="
sqlite3 "file:$PWD/$DB?mode=ro" "PRAGMA quick_check;" || fail=1

target_columns="$(sqlite3 "file:$PWD/$DB?mode=ro" "
SELECT COUNT(*)
FROM pragma_table_info('workers')
WHERE name IN (
  'worker_role',
  'worker_lane',
  'accepts_lane_jobs',
  'capabilities',
  'disabled',
  'current_running_jobs',
  'state',
  'computed_health'
);
")"
lane_enabled="$(sqlite3 "file:$PWD/$DB?mode=ro" "SELECT COUNT(*) FROM workers WHERE COALESCE(accepts_lane_jobs, 0) != 0;")"
non_default_lane="$(sqlite3 "file:$PWD/$DB?mode=ro" "SELECT COUNT(*) FROM workers WHERE COALESCE(worker_lane, '') != '';" )"
non_primary_role="$(sqlite3 "file:$PWD/$DB?mode=ro" "SELECT COUNT(*) FROM workers WHERE COALESCE(worker_role, 'primary') != 'primary';" )"

echo "target_columns_present=$target_columns"
echo "lane_enabled_worker_count=$lane_enabled"
echo "non_default_worker_lane_count=$non_default_lane"
echo "non_primary_worker_role_count=$non_primary_role"

if [ "$target_columns" = "8" ]; then echo "PASS: target metadata columns present"; else echo "FAIL: target metadata column count not 8"; fail=1; fi
if [ "$lane_enabled" = "0" ]; then echo "PASS: no lane-enabled workers"; else echo "FAIL: lane-enabled workers detected"; fail=1; fi
if [ "$non_default_lane" = "0" ]; then echo "PASS: no non-empty worker_lane"; else echo "FAIL: non-empty worker_lane detected"; fail=1; fi
if [ "$non_primary_role" = "0" ]; then echo "PASS: no non-primary worker_role"; else echo "FAIL: non-primary worker_role detected"; fail=1; fi

echo
echo "=== recent service error scan ==="
recent_errors="$(
  journalctl -u edge-queue-controller --since "20 minutes ago" --no-pager \
    | grep -Ei 'Traceback|Exception in ASGI|sqlite3\.|OperationalError|ProgrammingError|IntegrityError|HTTP/1\.1" 500|Internal Server Error' \
    | tail -40 || true
)"
if [ -n "$recent_errors" ]; then
  echo "FAIL: recent service log errors detected"
  echo "$recent_errors"
  fail=1
else
  echo "PASS: no recent traceback/sqlite/500 errors detected"
fi

echo
echo "=== source remains docs/smoke only for AU ==="
if git diff --name-only | grep -q '^edge_controller.py$'; then
  echo "FAIL: edge_controller.py changed during AU"
  fail=1
else
  echo "PASS: edge_controller.py unchanged in AU"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 14J-AU smoke complete"
else
  echo "FAIL: Phase 14J-AU smoke failed"
fi

exit "$fail"
