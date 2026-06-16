#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-CC smoke: CB static UI route patch post-verify ==="
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
APP_JS="frontend/study-ui/app.js"
GATEWAY_JS="cloudflare/edge-public-proxy/src/index.js"
MANIFEST="docs/phase-14j-cb-static-ui-route-contract-patch-manifest.md"
CB_REF="controller-phase-14j-cb-second-bounded-static-ui-and-route-contract-patch-batch-2026-06-16"

for file in "$HTML" "$APP_JS" "$GATEWAY_JS" "$MANIFEST"; do
  test -f "$file"
  git ls-files --error-unmatch "$file" >/dev/null
done

git rev-parse -q --verify "refs/tags/${CB_REF}" >/dev/null

echo
echo "=== verify CB static markers in current tree ==="
grep -F "APC_PHASE_14J_BZ_STATIC_UI_PATCH" "$HTML" >/dev/null
grep -F "APC_PHASE_14J_BZ_STATIC_UI_PATCH" "$APP_JS" >/dev/null
grep -F "APC_PHASE_14J_CB_STATIC_UI_PATCH" "$APP_JS" >/dev/null
grep -F "APC_PHASE_14J_CB_STATIC_ROUTE_CONTRACT" "$GATEWAY_JS" >/dev/null
grep -F 'data-apc-static-ui-copy-layout="14j-cb"' "$HTML" >/dev/null
grep -F 'name="description"' "$HTML" >/dev/null
grep -F 'STATIC_UI_ROUTE_CONTRACT_PATCH_APPLIED=bounded_static_copy_layout_and_contract' "$MANIFEST" >/dev/null
grep -F 'PATCH_BOUNDARY=tracked_active_source_static_ui_route_contract_only' "$MANIFEST" >/dev/null

if grep -F '<html' "$HTML" | head -1 | grep -F 'lang=' >/dev/null; then
  echo "PASS: HTML language attribute present"
else
  echo "FAIL: HTML language attribute missing"
  exit 1
fi

echo "PASS: CB static UI and route-contract markers verified"

echo
echo "=== verify CB patch by CB tag ==="
git show --stat --oneline "$CB_REF" -- "$HTML" "$APP_JS" "$GATEWAY_JS" "$MANIFEST"

changed_names="$(git show --name-only --format='' "$CB_REF" | sed '/^$/d' | sort)"
printf 'changed_names_at_CB_tag:\n%s\n' "$changed_names"

for required in \
  "$HTML" \
  "$APP_JS" \
  "$GATEWAY_JS" \
  "$MANIFEST" \
  "docs/phase-14j-cb-second-bounded-static-ui-and-route-contract-patch-batch.md" \
  "ops/smoke/check-phase-14j-cb-second-bounded-static-ui-and-route-contract-patch-batch.sh" \
  "ops/smoke/check-phase-14j-ca-bz-static-ui-patch-post-verify.sh"
do
  printf '%s\n' "$changed_names" | grep -Fx "$required" >/dev/null
  echo "PASS: expected CB changed path present at CB tag: $required"
done

if printf '%s\n' "$changed_names" | grep -E '(^|/)(edge_controller\.py|edge_modules/|edge_intent_router\.py|edge_router_|.*\.sqlite3|.*\.db)$' >/dev/null; then
  echo "FAIL: CB changed runtime/backend/db-looking path unexpectedly"
  exit 1
fi

echo "PASS: CB patch stayed in expected static UI/route/docs/smoke boundary"

echo
echo "=== syntax checks ==="
python3 -m py_compile edge_controller.py

if command -v node >/dev/null 2>&1; then
  node --check "$APP_JS"
  node --check "$GATEWAY_JS"
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
echo "PASS: CB static UI route patch post-verify passed"
