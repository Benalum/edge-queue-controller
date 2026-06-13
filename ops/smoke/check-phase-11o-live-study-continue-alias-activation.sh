#!/usr/bin/env bash
set -u

fail=0

echo "=== Phase 11O smoke: live Study continue alias activation ==="

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root" || fail=1

frontend_file="frontend/wrapper-ui/app.js"
backend_file="edge_controller.py"

echo
echo "=== repo root ==="
pwd

echo
echo "=== git baseline ==="
git log --oneline -4
git tag --points-at HEAD

echo
echo "=== local source markers ==="
check_marker() {
  label="$1"
  marker="$2"
  file="$3"

  if [ -f "$file" ] && grep -Fq "$marker" "$file"; then
    echo "PASS: $label"
    grep -nF "$marker" "$file" | sed -n '1,5p'
  else
    echo "FAIL: missing $label"
    echo "marker: $marker"
    fail=1
  fi
}

check_marker "frontend continue alias" '"continue"' "$frontend_file"
check_marker "frontend go on alias" '"go on"' "$frontend_file"
check_marker "frontend move on alias" '"move on"' "$frontend_file"
check_marker "backend active continue reason" "Active study session and user requested next/continue." "$backend_file"
check_marker "backend paused continue reason" "Paused study session and user requested resume/continue." "$backend_file"

echo
echo "=== local frontend static activation ==="
curl -sS --max-time 10 -D /tmp/phase11o-local-app-headers.txt -o /tmp/phase11o-local-app.js \
  http://127.0.0.1:8787/app.js || fail=1

sed -n '1,20p' /tmp/phase11o-local-app-headers.txt
echo "body bytes: $(wc -c < /tmp/phase11o-local-app.js 2>/dev/null || echo 0)"

for marker in '"continue"' '"go on"' '"move on"'; do
  if grep -Fq "$marker" /tmp/phase11o-local-app.js; then
    echo "PASS: local app.js contains $marker"
  else
    echo "FAIL: local app.js missing $marker"
    fail=1
  fi
done

echo
echo "=== public frontend static activation ==="
curl -sS --max-time 15 -D /tmp/phase11o-public-app-headers.txt -o /tmp/phase11o-public-app.js \
  https://alexhartel.com/app.js?v=2026061208l || fail=1

sed -n '1,24p' /tmp/phase11o-public-app-headers.txt
echo "body bytes: $(wc -c < /tmp/phase11o-public-app.js 2>/dev/null || echo 0)"

for marker in '"continue"' '"go on"' '"move on"'; do
  if grep -Fq "$marker" /tmp/phase11o-public-app.js; then
    echo "PASS: public app.js contains $marker"
  else
    echo "FAIL: public app.js missing $marker"
    fail=1
  fi
done

echo
echo "=== backend service active/health ==="
systemctl show edge-queue-controller \
  -p ActiveState \
  -p SubState \
  -p MainPID \
  -p ExecMainStartTimestamp \
  -p WorkingDirectory \
  --no-pager || true

active_state="$(systemctl show edge-queue-controller -p ActiveState --value 2>/dev/null || true)"
sub_state="$(systemctl show edge-queue-controller -p SubState --value 2>/dev/null || true)"

if [ "$active_state" = "active" ] && [ "$sub_state" = "running" ]; then
  echo "PASS: edge-queue-controller is active/running"
else
  echo "FAIL: edge-queue-controller is not active/running"
  fail=1
fi

health_code="$(curl -sS --max-time 10 -D /tmp/phase11o-health-headers.txt -o /tmp/phase11o-health-body.txt -w '%{http_code}' \
  http://127.0.0.1:7070/health 2>/dev/null || true)"

sed -n '1,20p' /tmp/phase11o-health-headers.txt
cat /tmp/phase11o-health-body.txt 2>/dev/null || true
echo

if [ "$health_code" = "200" ]; then
  echo "PASS: backend health returned 200"
else
  echo "FAIL: backend health code was $health_code"
  fail=1
fi

echo
echo "=== backend process freshness ==="
main_pid="$(systemctl show edge-queue-controller -p MainPID --value 2>/dev/null || true)"
source_epoch="$(stat -c %Y "$backend_file")"
source_time="$(stat -c %y "$backend_file")"
proc_start_epoch=0
proc_start_text=""

echo "main_pid=$main_pid"
echo "edge_controller.py=$source_time"
echo "source_epoch=$source_epoch"

if [ -n "$main_pid" ] && [ "$main_pid" != "0" ]; then
  proc_start_text="$(ps -p "$main_pid" -o lstart= | sed 's/^[[:space:]]*//')"
  proc_start_epoch="$(date -d "$proc_start_text" +%s 2>/dev/null || echo 0)"
  echo "process_start=$proc_start_text"
  echo "process_start_epoch=$proc_start_epoch"

  if [ "$proc_start_epoch" -ge "$source_epoch" ]; then
    echo "PASS: backend process is newer than or equal to edge_controller.py"
  else
    echo "FAIL: backend process is older than edge_controller.py"
    fail=1
  fi
else
  echo "FAIL: no running backend MainPID"
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
if echo "$backend_scan_files" | xargs -r grep -nE 'os\.getenv\(["'\'']EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY|os\.environ\.get\(["'\'']EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY|Environment=.*EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY|EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY[A-Z0-9_]*=' >/tmp/phase11o-router-dry-env.txt 2>/dev/null; then
  echo "FAIL: backend router dry-run env marker found"
  cat /tmp/phase11o-router-dry-env.txt
  router_fail=1
else
  echo "PASS: no backend router dry-run env marker found"
fi

echo
echo "--- frontend router/rollout POST guard ---"
if echo "$frontend_scan_files" | xargs -r grep -nE 'fetch\([^)]*(router|rollout)|method:[[:space:]]*["'\'']POST["'\''][^;]*(router|rollout)|(router|rollout)[^;]*method:[[:space:]]*["'\'']POST["'\'']' >/tmp/phase11o-router-post.txt 2>/dev/null; then
  echo "FAIL: frontend router/rollout POST runtime marker found"
  cat /tmp/phase11o-router-post.txt
  router_fail=1
else
  echo "PASS: no frontend router/rollout POST runtime marker found"
fi

echo
echo "--- backend rollout/router mutation route guard ---"
mutation_hits="$(
  echo "$backend_scan_files" \
    | xargs -r grep -nE '@.*\.(post|put|patch|delete)\([^)]*(router|rollout)|route\([^)]*(router|rollout)[^)]*methods=[^)]*["'\''](POST|PUT|PATCH|DELETE)["'\'']|methods=[^)]*["'\''](POST|PUT|PATCH|DELETE)["'\''][^)]*(router|rollout)' 2>/dev/null \
    | grep -vE '@app\.post\(["'\'']/api/router/dry-run["'\'']\)|@app\.post\(["'\'']/system/router/dry-run["'\'']\)' \
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
    | grep -vE '^[ ?MADRCU]{1,2} docs/phase-11o-live-study-continue-alias-activation\.md$' \
    | grep -vE '^[ ?MADRCU]{1,2} ops/smoke/check-phase-11o-live-study-continue-alias-activation\.sh$' \
    || true
)"

git status --short

if [ -n "$bad_status" ]; then
  echo
  echo "FAIL: unexpected changed files detected"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 11O docs/smoke files are changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 11O live Study continue alias activation smoke passed"
else
  echo "FAIL: Phase 11O live Study continue alias activation smoke failed"
fi

exit "$fail"
