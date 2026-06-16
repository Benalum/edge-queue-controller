#!/usr/bin/env bash
set -euo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO"

PHASE="phase-14j-bk-runtime-activation-preflight-checklist-and-rollback-verification-plan"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
SERVICE="edge-queue-controller"
DB="edge_queue.sqlite3"

fail() { echo "FAIL: $*"; exit 1; }
pass() { echo "PASS: $*"; }

is_enabled_value() {
  v="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"
  case "$v" in
    1|true|yes|on|enabled) return 0 ;;
    *) return 1 ;;
  esac
}

echo "=== Phase 14J-BK smoke: docs/smoke-only runtime activation preflight checklist ==="

echo
echo "=== required artifacts ==="
[ -f "$DOC" ] || fail "missing $DOC"
[ -f "$SMOKE" ] || fail "missing $SMOKE"
pass "required BK artifacts exist"

echo
echo "=== compile baseline, in memory only ==="
python3 - <<'PY'
from pathlib import Path
path = Path("edge_controller.py")
compile(path.read_text(), str(path), "exec")
print("PASS: edge_controller.py compiles in memory")
PY

echo
echo "=== documentation contract markers ==="
for marker in \
  "Phase 14J-BK" \
  "docs/smoke-only checkpoint" \
  "Activation remains blocked" \
  "runtime_activation_approval_required" \
  "rollback_runtime_evidence_pending" \
  "worker_role" \
  "worker_lane" \
  "accepts_lane_jobs" \
  "capabilities" \
  "disabled" \
  "current_running_jobs" \
  "state" \
  "computed_health" \
  "No-lane jobs keep the primary/default worker path" \
  "Lane-tagged jobs requiring a lane worker do not silently fall back to primary" \
  "Lane-tagged jobs with no eligible matching lane worker remain blocked/deferred" \
  "BK is a docs/smoke-only preflight checkpoint"
do
  grep -F "$marker" "$DOC" >/dev/null || fail "missing doc marker: $marker"
done
pass "BK documentation markers verified"

echo
echo "=== generated doc forbidden executable-fragment scan ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14j-bk-runtime-activation-preflight-checklist-and-rollback-verification-plan.md")
text = doc.read_text()

blocked_fragments = [
    "pct " + "exec",
    "ssh " + "root@",
    ":114" + "34",
    ":808" + "8",
    "EDGE_PERSISTENT_LANE_WORKERS_ENABLED=" + "1",
    "APPLY_DEFAULT_OFF_WORKER_LANE_METADATA=" + "1",
    "systemctl " + "restart",
    "systemctl " + "reload",
    "UPDATE " + "jobs",
    "DELETE " + "FROM jobs",
]

bad = [frag for frag in blocked_fragments if frag in text]
if bad:
    print("FAIL: generated doc contains forbidden executable fragments:")
    for frag in bad:
        print(f" - {frag}")
    raise SystemExit(1)

print("PASS: generated doc contains no forbidden executable fragments")
PY

echo
echo "=== SQLite worker metadata read-only verification ==="
[ -f "$DB" ] || fail "missing DB: $DB"
quick="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "PRAGMA quick_check;" | tr -d '\r')"
echo "quick_check=$quick"
[ "$quick" = "ok" ] || fail "SQLite quick_check expected ok"

python3 - <<'PY'
import sqlite3
from pathlib import Path

db = Path("edge_queue.sqlite3").resolve()
canonical = [
    "worker_role",
    "worker_lane",
    "accepts_lane_jobs",
    "capabilities",
    "disabled",
    "current_running_jobs",
    "state",
    "computed_health",
]

def qident(name: str) -> str:
    return '"' + name.replace('"', '""') + '"'

con = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
tables = [row[0] for row in con.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")]

matches = []
for table in tables:
    cols = [row[1] for row in con.execute(f"PRAGMA table_info({qident(table)})")]
    if all(col in cols for col in canonical):
        matches.append(table)

if not matches:
    print("FAIL: no table has all canonical worker metadata columns")
    raise SystemExit(1)

table = matches[0]
print(f"worker_metadata_table={table}")
print("canonical_columns_present=" + ",".join(canonical))

row = con.execute(f"""
SELECT
  COUNT(*) AS worker_count,
  COALESCE(SUM(CASE
    WHEN lower(COALESCE(CAST(accepts_lane_jobs AS TEXT), '0')) IN ('1','true','yes','on','enabled')
    THEN 1 ELSE 0 END), 0) AS lane_enabled_worker_count,
  COALESCE(SUM(CASE
    WHEN lower(COALESCE(CAST(worker_lane AS TEXT), 'primary')) NOT IN ('primary','default','')
    THEN 1 ELSE 0 END), 0) AS non_default_worker_lane_count,
  COALESCE(SUM(CASE
    WHEN lower(COALESCE(CAST(worker_role AS TEXT), 'primary')) NOT IN ('primary','default','')
    THEN 1 ELSE 0 END), 0) AS non_primary_worker_role_count
FROM {qident(table)}
""").fetchone()

labels = [
    "worker_count",
    "lane_enabled_worker_count",
    "non_default_worker_lane_count",
    "non_primary_worker_role_count",
]
for label, value in zip(labels, row):
    print(f"{label}={value}")

if tuple(int(v) for v in row) != (0, 0, 0, 0):
    print("FAIL: worker metadata default-off counts changed")
    raise SystemExit(1)

print("PASS: worker metadata canonical/default-off state verified")
PY

echo
echo "=== persistent lane worker env flag remains disabled ==="
shell_flag="$(printenv EDGE_PERSISTENT_LANE_WORKERS_ENABLED 2>/dev/null || true)"
if [ -n "$shell_flag" ] && is_enabled_value "$shell_flag"; then
  fail "shell EDGE_PERSISTENT_LANE_WORKERS_ENABLED is enabled"
fi
pass "shell EDGE_PERSISTENT_LANE_WORKERS_ENABLED absent/disabled"

service_env="$(systemctl show "$SERVICE" -p Environment --value 2>/dev/null || true)"
service_flag="$(
  printf '%s\n' "$service_env" \
    | tr ' ' '\n' \
    | awk -F= '$1=="EDGE_PERSISTENT_LANE_WORKERS_ENABLED" {print $2}' \
    | tail -n 1
)"
if [ -n "$service_flag" ] && is_enabled_value "$service_flag"; then
  fail "service EDGE_PERSISTENT_LANE_WORKERS_ENABLED is enabled"
fi
pass "service EDGE_PERSISTENT_LANE_WORKERS_ENABLED absent/disabled"

echo
echo "=== hard boundary evidence ==="
pass "BK smoke did not rerun schema apply wrapper"
pass "BK smoke did not restart/reload services"
pass "BK smoke did not call CT101, Ollama, or live model endpoints"
pass "BK smoke did not mutate jobs"
pass "BK smoke did not activate scheduler lane dispatch, primary-worker filtering, router rollout, warmup execution, or persistent lane workers"

echo
echo "PASS: Phase 14J-BK smoke complete"
