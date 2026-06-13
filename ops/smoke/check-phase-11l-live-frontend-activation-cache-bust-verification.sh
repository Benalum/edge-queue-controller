#!/usr/bin/env bash
set -u

fail=0

echo "=== Phase 11L smoke: live frontend activation / cache-bust verification ==="

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root" || fail=1

marker="STAGE_5P11K_DETERMINISTIC_NUMBER_WORD_NORMALIZER_BEGIN"

echo
echo "=== repo root ==="
pwd

echo
echo "=== git baseline ==="
git log --oneline -3
git tag --points-at HEAD

echo
echo "=== local repo marker ==="
if grep -Fq "$marker" frontend/wrapper-ui/app.js; then
  echo "PASS: local repo app.js contains Phase 11K marker"
  grep -nF "$marker" frontend/wrapper-ui/app.js | sed -n '1,5p'
else
  echo "FAIL: local repo app.js missing Phase 11K marker"
  fail=1
fi

echo
echo "=== root app.js reference ==="
app_ref="$(
  grep -oE '/app\.js\?v=[^"'"'"']+|/app\.js|app\.js\?v=[^"'"'"']+' frontend/wrapper-ui/index.html \
    | tail -n 1 \
    || true
)"

if [ -n "$app_ref" ]; then
  echo "PASS: found app.js reference: $app_ref"
else
  echo "FAIL: could not find app.js reference in frontend/wrapper-ui/index.html"
  fail=1
fi

public_app_path="/app.js?v=2026061208l"
if [ -n "$app_ref" ]; then
  case "$app_ref" in
    /*) public_app_path="$app_ref" ;;
    *) public_app_path="/$app_ref" ;;
  esac
fi

echo
echo "=== local static app.js marker probe ==="
curl -sS --max-time 10 -D /tmp/phase11l-local-app-headers.txt -o /tmp/phase11l-local-app-body.txt \
  "http://127.0.0.1:8787/app.js" || fail=1

sed -n '1,20p' /tmp/phase11l-local-app-headers.txt
echo "body bytes: $(wc -c < /tmp/phase11l-local-app-body.txt 2>/dev/null || echo 0)"

if grep -Fq "$marker" /tmp/phase11l-local-app-body.txt; then
  echo "PASS: local static /app.js contains Phase 11K marker"
else
  echo "FAIL: local static /app.js missing Phase 11K marker"
  fail=1
fi

echo
echo "=== public plain app.js marker probe ==="
curl -sS --max-time 15 -D /tmp/phase11l-public-app-headers.txt -o /tmp/phase11l-public-app-body.txt \
  "https://alexhartel.com/app.js" || fail=1

sed -n '1,24p' /tmp/phase11l-public-app-headers.txt
echo "body bytes: $(wc -c < /tmp/phase11l-public-app-body.txt 2>/dev/null || echo 0)"

if grep -Fq "$marker" /tmp/phase11l-public-app-body.txt; then
  echo "PASS: public /app.js contains Phase 11K marker"
else
  echo "FAIL: public /app.js missing Phase 11K marker"
  fail=1
fi

echo
echo "=== public exact referenced app.js marker probe ==="
echo "probing https://alexhartel.com${public_app_path}"

curl -sS --max-time 15 -D /tmp/phase11l-public-app-query-headers.txt -o /tmp/phase11l-public-app-query-body.txt \
  "https://alexhartel.com${public_app_path}" || fail=1

sed -n '1,24p' /tmp/phase11l-public-app-query-headers.txt
echo "body bytes: $(wc -c < /tmp/phase11l-public-app-query-body.txt 2>/dev/null || echo 0)"

if grep -Fq "$marker" /tmp/phase11l-public-app-query-body.txt; then
  echo "PASS: public referenced app.js contains Phase 11K marker"
else
  echo "FAIL: public referenced app.js missing Phase 11K marker"
  fail=1
fi

echo
echo "=== public root reference probe ==="
curl -sS --max-time 15 -D /tmp/phase11l-public-root-headers.txt -o /tmp/phase11l-public-root-body.txt \
  "https://alexhartel.com/" || fail=1

sed -n '1,24p' /tmp/phase11l-public-root-headers.txt
echo "body bytes: $(wc -c < /tmp/phase11l-public-root-body.txt 2>/dev/null || echo 0)"

if grep -E 'app\.js(\?v=|")' /tmp/phase11l-public-root-body.txt | sed -n '1,10p'; then
  echo "PASS: public root references app.js"
else
  echo "FAIL: public root did not show app.js reference"
  fail=1
fi

echo
echo "=== confirm router rollout remains parked ==="

router_fail=0

backend_scan_files="$(
  find . \
    -path './.cleanup-archive' -prune -o \
    -type f \( \
      -path './edge_controller.py' -o \
      -path './public_gateway.py' \
    \) -print
)"

frontend_scan_files="$(
  find . \
    -path './.cleanup-archive' -prune -o \
    -type f \( \
      -path './frontend/wrapper-ui/app.js' -o \
      -path './frontend/wrapper-ui/index.html' \
    \) -print
)"

echo "$backend_scan_files" | sed 's#^\./#backend scan: #'
echo "$frontend_scan_files" | sed 's#^\./#frontend scan: #'

echo
echo "--- backend dry-run env guard ---"
if echo "$backend_scan_files" | xargs -r grep -nE 'os\.getenv\(["'"'"']EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY|os\.environ\.get\(["'"'"']EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY|Environment=.*EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY|EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY[A-Z0-9_]*=' >/tmp/phase11l-router-dry-env.txt 2>/dev/null; then
  echo "FAIL: backend router dry-run env marker found"
  cat /tmp/phase11l-router-dry-env.txt
  router_fail=1
else
  echo "PASS: no backend router dry-run env marker found"
fi

echo
echo "--- frontend router/rollout POST guard ---"
if echo "$frontend_scan_files" | xargs -r grep -nE 'fetch\([^)]*(router|rollout)|method:[[:space:]]*["'"'"']POST["'"'"'][^;]*(router|rollout)|(router|rollout)[^;]*method:[[:space:]]*["'"'"']POST["'"'"']' >/tmp/phase11l-router-post.txt 2>/dev/null; then
  echo "FAIL: frontend router/rollout POST runtime marker found"
  cat /tmp/phase11l-router-post.txt
  router_fail=1
else
  echo "PASS: no frontend router/rollout POST runtime marker found"
fi

echo
echo "--- backend rollout/router mutation route guard ---"
mutation_hits="$(
  echo "$backend_scan_files" \
    | xargs -r grep -nE '@.*\.(post|put|patch|delete)\([^)]*(router|rollout)|route\([^)]*(router|rollout)[^)]*methods=[^)]*["'"'"'](POST|PUT|PATCH|DELETE)["'"'"']|methods=[^)]*["'"'"'](POST|PUT|PATCH|DELETE)["'"'"'][^)]*(router|rollout)' 2>/dev/null \
    | grep -vE '@app\.post\(["'"'"']/api/router/dry-run["'"'"']\)|@app\.post\(["'"'"']/system/router/dry-run["'"'"']\)' \
    || true
)"

if [ -n "$mutation_hits" ]; then
  echo "FAIL: non-dry-run rollout/router mutation runtime marker found"
  echo "$mutation_hits"
  router_fail=1
else
  echo "PASS: no non-dry-run rollout/router mutation runtime marker found"
fi

if [ "$router_fail" != "0" ]; then
  fail=1
fi

echo
echo "=== confirm docs/smoke changes only ==="
bad_status="$(
  git status --short \
    | grep -vE '^[ ?MADRCU]{1,2} docs/phase-11l-live-frontend-activation-cache-bust-verification\.md$' \
    | grep -vE '^[ ?MADRCU]{1,2} ops/smoke/check-phase-11l-live-frontend-activation-cache-bust-verification\.sh$' \
    || true
)"

git status --short

if [ -n "$bad_status" ]; then
  echo
  echo "FAIL: unexpected changed files detected"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 11L docs/smoke files are changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 11L live frontend activation smoke passed"
else
  echo "FAIL: Phase 11L live frontend activation smoke failed"
fi

exit "$fail"
