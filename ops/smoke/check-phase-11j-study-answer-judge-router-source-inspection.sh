#!/usr/bin/env bash
set -u

fail=0

echo "=== Phase 11J smoke: Study answer judge router source inspection ==="

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root" || fail=1

runtime_file="frontend/wrapper-ui/app.js"

echo
echo "=== repo root ==="
pwd

echo
echo "=== verify runtime file exists ==="
if [ -f "$runtime_file" ]; then
  echo "PASS: found $runtime_file"
else
  echo "FAIL: missing $runtime_file"
  fail=1
fi

echo
echo "=== authoritative exact runtime marker checks ==="
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

check_marker "compare function" "function stage5p11jCompareAnswer" "$runtime_file"
check_marker "study answer route function" "async function stage5p11jRouteCompanionStudyAnswer" "$runtime_file"
check_marker "uncertain answer text" "I am not certain whether that matches the answer" "$runtime_file"
check_marker "expected answer text" "Expected answer" "$runtime_file"

echo
echo "=== exact source context ==="
if [ -f "$runtime_file" ]; then
  compare_line="$(grep -nF "function stage5p11jCompareAnswer" "$runtime_file" | head -n 1 | cut -d: -f1 || true)"
  route_line="$(grep -nF "async function stage5p11jRouteCompanionStudyAnswer" "$runtime_file" | head -n 1 | cut -d: -f1 || true)"

  if [ -n "$compare_line" ]; then
    start=$((compare_line - 20))
    end=$((compare_line + 70))
    [ "$start" -lt 1 ] && start=1
    echo "--- compare context: $runtime_file:$start-$end ---"
    nl -ba "$runtime_file" | sed -n "${start},${end}p"
  fi

  if [ -n "$route_line" ]; then
    start=$((route_line - 20))
    end=$((route_line + 70))
    [ "$start" -lt 1 ] && start=1
    echo "--- route context: $runtime_file:$start-$end ---"
    nl -ba "$runtime_file" | sed -n "${start},${end}p"
  fi
fi

echo
echo "=== archive pollution guard ==="
if find . -path './.cleanup-archive' -prune -o -type f \( -path './frontend/*' -o -path './edge_controller.py' -o -path './public_gateway.py' \) -print \
  | grep -F ".cleanup-archive" >/dev/null 2>&1; then
  echo "FAIL: runtime scan included .cleanup-archive"
  fail=1
else
  echo "PASS: runtime scan excludes .cleanup-archive"
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
if echo "$backend_scan_files" | xargs -r grep -nE 'os\.getenv\(["'\'']EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY|os\.environ\.get\(["'\'']EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY|Environment=.*EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY|EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY[A-Z0-9_]*=' >/tmp/phase11j-router-dry-env.txt 2>/dev/null; then
  echo "FAIL: backend router dry-run env marker found"
  cat /tmp/phase11j-router-dry-env.txt
  router_fail=1
else
  echo "PASS: no backend router dry-run env marker found"
fi

echo
echo "--- frontend router/rollout POST guard ---"
if echo "$frontend_scan_files" | xargs -r grep -nE 'fetch\([^)]*(router|rollout)|method:[[:space:]]*["'\'']POST["'\''][^;]*(router|rollout)|(router|rollout)[^;]*method:[[:space:]]*["'\'']POST["'\'']' >/tmp/phase11j-router-post.txt 2>/dev/null; then
  echo "FAIL: frontend router/rollout POST runtime marker found"
  cat /tmp/phase11j-router-post.txt
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
echo "=== confirm only docs/smoke files are changed ==="
bad_status="$(
  git status --short \
    | grep -vE '^[ ?MADRCU]{1,2} docs/phase-11j-study-answer-judge-router-source-inspection\.md$' \
    | grep -vE '^[ ?MADRCU]{1,2} ops/smoke/check-phase-11j-study-answer-judge-router-source-inspection\.sh$' \
    || true
)"

git status --short

if [ -n "$bad_status" ]; then
  echo
  echo "FAIL: non-Phase-11J docs/smoke changes detected"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 11J docs/smoke files are changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 11J source inspection smoke passed"
else
  echo "FAIL: Phase 11J source inspection smoke failed"
fi

exit "$fail"
