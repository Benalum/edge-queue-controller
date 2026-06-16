#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-CA smoke: BZ static UI patch post-verify ==="
echo "MUTATION_SCOPE=read_only_post_patch_verification"
echo "NO CT101 call"
echo "NO model/Ollama endpoint call"
echo "NO DB mutation"
echo "NO job mutation"
echo "NO service restart/reload"
echo "NO scheduler activation"
echo "NO worker activation"
echo "NO runtime activation"

HTML="frontend/study-ui/index.html"
JS="frontend/study-ui/app.js"
MANIFEST="docs/phase-14j-bz-static-ui-copy-layout-patch-manifest.md"
BZ_REF="controller-phase-14j-bz-bounded-exact-static-ui-copy-layout-patch-2026-06-16"

test -f "$HTML"
test -f "$JS"
test -f "$MANIFEST"
git ls-files --error-unmatch "$HTML" >/dev/null
git ls-files --error-unmatch "$JS" >/dev/null
git ls-files --error-unmatch "$MANIFEST" >/dev/null
git rev-parse -q --verify "refs/tags/${BZ_REF}" >/dev/null

echo
echo "=== verify BZ static markers in current tree ==="
grep -F 'APC_PHASE_14J_BZ_STATIC_UI_PATCH' "$HTML" >/dev/null
grep -F 'APC_PHASE_14J_BZ_STATIC_UI_PATCH' "$JS" >/dev/null
grep -F 'data-apc-static-ui-patch="14j-bz"' "$HTML" >/dev/null
grep -F 'apc-static-ui-phase' "$HTML" >/dev/null
grep -F 'STATIC_UI_PATCH_APPLIED=bounded_exact_static_copy_layout' "$MANIFEST" >/dev/null
grep -F 'PATCH_BOUNDARY=tracked_active_static_ui_source_only' "$MANIFEST" >/dev/null

echo "PASS: BZ static UI markers verified"

echo
echo "=== verify BZ patch stayed small and static by BZ tag ==="
git show --stat --oneline "$BZ_REF" -- "$HTML" "$JS" "$MANIFEST"
changed_names="$(git show --name-only --format='' "$BZ_REF" | sed '/^$/d' | sort)"
printf 'changed_names_at_BZ_tag:\n%s\n' "$changed_names"

for required in \
  "$HTML" \
  "$JS" \
  "$MANIFEST" \
  "docs/phase-14j-bz-bounded-exact-static-ui-copy-layout-patch.md" \
  "ops/smoke/check-phase-14j-bz-bounded-exact-static-ui-copy-layout-patch.sh"
do
  printf '%s\n' "$changed_names" | grep -Fx "$required" >/dev/null
  echo "PASS: expected BZ changed path present at BZ tag: $required"
done

if printf '%s\n' "$changed_names" | grep -E '(^|/)(edge_controller\.py|edge_modules/|edge_intent_router\.py|edge_router_|.*\.sqlite3|.*\.db)$' >/dev/null; then
  echo "FAIL: BZ changed runtime/backend/db-looking path unexpectedly"
  exit 1
fi

echo "PASS: BZ patch stayed in expected static UI/docs/smoke boundary"

echo
echo "=== syntax checks ==="
python3 -m py_compile edge_controller.py

if command -v node >/dev/null 2>&1; then
  node --check "$JS"
  if [ -f "cloudflare/edge-public-proxy/src/index.js" ]; then
    node --check cloudflare/edge-public-proxy/src/index.js
  fi
else
  echo "CHECK: node not available; skipped JS syntax check"
fi

echo
echo "=== read-only DB and env guard ==="
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller"

quick_check="$(sqlite3 "file:${DB}?mode=ro" 'PRAGMA quick_check;')"
worker_count="$(sqlite3 "file:${DB}?mode=ro" 'SELECT COUNT(*) FROM workers;')"
lane_enabled_worker_count="$(sqlite3 "file:${DB}?mode=ro" "SELECT COALESCE(SUM(CASE WHEN COALESCE(accepts_lane_jobs,0) NOT IN (0,'0','false','False','') THEN 1 ELSE 0 END),0) FROM workers;")"

printf 'quick_check=%s\n' "$quick_check"
printf 'worker_count=%s\n' "$worker_count"
printf 'lane_enabled_worker_count=%s\n' "$lane_enabled_worker_count"

test "$quick_check" = "ok"
test "$worker_count" = "0"
test "$lane_enabled_worker_count" = "0"

shell_flag="${EDGE_PERSISTENT_LANE_WORKERS_ENABLED:-}"
printf 'shell_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=%s\n' "${shell_flag:-<unset>}"
case "${shell_flag,,}" in
  ""|"0"|"false"|"no"|"off") echo "PASS: shell persistent lane worker flag absent/disabled" ;;
  *) echo "FAIL: shell persistent lane worker flag appears enabled"; exit 1 ;;
esac

service_env="$(systemctl show "$SERVICE" -p Environment --value 2>/dev/null || true)"
service_flag="$(printf '%s\n' "$service_env" | tr ' ' '\n' | grep -E '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=' || true)"
printf 'service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=%s\n' "${service_flag:-<unset>}"

if [ -z "$service_flag" ]; then
  echo "PASS: service persistent lane worker flag absent"
else
  service_value="${service_flag#*=}"
  case "${service_value,,}" in
    ""|"0"|"false"|"no"|"off") echo "PASS: service persistent lane worker flag disabled" ;;
    *) echo "FAIL: service persistent lane worker flag appears enabled"; exit 1 ;;
  esac
fi

echo
echo "PASS: BZ static UI patch post-verify passed"
