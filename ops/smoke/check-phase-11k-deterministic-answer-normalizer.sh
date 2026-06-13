#!/usr/bin/env bash
set -u

fail=0

echo "=== Phase 11K smoke: deterministic answer normalizer ==="

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
echo "=== marker checks ==="
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

check_marker "Phase 11K begin marker" "STAGE_5P11K_DETERMINISTIC_NUMBER_WORD_NORMALIZER_BEGIN" "$runtime_file"
check_marker "number word parser" "function stage5p11kParseNumberWords" "$runtime_file"
check_marker "integer number word parser" "function stage5p11kParseIntegerNumberWords" "$runtime_file"
check_marker "numeric answer parser still present" "function stage5p11jParseNumericAnswer" "$runtime_file"
check_marker "compare function still present" "function stage5p11jCompareAnswer" "$runtime_file"
check_marker "study answer route still present" "async function stage5p11jRouteCompanionStudyAnswer" "$runtime_file"

echo
echo "=== JavaScript behavior tests ==="
node_bin=""
if command -v node >/dev/null 2>&1; then
  node_bin="node"
elif command -v nodejs >/dev/null 2>&1; then
  node_bin="nodejs"
fi

if [ -z "$node_bin" ]; then
  echo "FAIL: node/nodejs not found for JavaScript behavior tests"
  fail=1
else
  python3 - <<'PY'
from pathlib import Path

runtime = Path("frontend/wrapper-ui/app.js").read_text()
start = runtime.index("function stage5p11jNormalizeAnswer")
end = runtime.index("function stage5p11jLooksLikeAnswerAttempt", start)

test_js = runtime[start:end] + r'''

const cases = [
  ["five", "5", "correct"],
  ["Five!", "5", "correct"],
  ["twenty one", "21", "correct"],
  ["twenty-one", "21", "correct"],
  ["negative five", "-5", "correct"],
  ["minus five", "-5", "correct"],
  ["five point five", "5.5", "correct"],
  ["one half", "0.5", "uncertain"],
  ["six", "5", "wrong"],
  ["five dollars", "5", "uncertain"],
  ["1/2", "0.5", "correct"],
  ["5.000", "5", "correct"]
];

let failed = 0;

for (const [user, expected, verdict] of cases) {
  const actual = stage5p11jCompareAnswer(user, expected);
  if (actual !== verdict) {
    console.error("FAIL:", JSON.stringify({ user, expected, verdict, actual }));
    failed += 1;
  } else {
    console.log("PASS:", JSON.stringify({ user, expected, verdict }));
  }
}

if (failed) {
  process.exit(1);
}
'''

Path("/tmp/phase11k-answer-normalizer-test.js").write_text(test_js)
PY

  "$node_bin" /tmp/phase11k-answer-normalizer-test.js || fail=1
fi

echo
echo "=== exact patched source context ==="
if [ -f "$runtime_file" ]; then
  start_line="$(grep -nF "STAGE_5P11K_DETERMINISTIC_NUMBER_WORD_NORMALIZER_BEGIN" "$runtime_file" | head -n 1 | cut -d: -f1 || true)"
  end_line="$(grep -nF "STAGE_5P11K_DETERMINISTIC_NUMBER_WORD_NORMALIZER_END" "$runtime_file" | head -n 1 | cut -d: -f1 || true)"
  if [ -n "$start_line" ] && [ -n "$end_line" ]; then
    start=$((start_line - 10))
    end=$((end_line + 30))
    [ "$start" -lt 1 ] && start=1
    nl -ba "$runtime_file" | sed -n "${start},${end}p"
  fi
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
if echo "$backend_scan_files" | xargs -r grep -nE 'os\.getenv\(["'\'']EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY|os\.environ\.get\(["'\'']EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY|Environment=.*EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY|EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY[A-Z0-9_]*=' >/tmp/phase11k-router-dry-env.txt 2>/dev/null; then
  echo "FAIL: backend router dry-run env marker found"
  cat /tmp/phase11k-router-dry-env.txt
  router_fail=1
else
  echo "PASS: no backend router dry-run env marker found"
fi

echo
echo "--- frontend router/rollout POST guard ---"
if echo "$frontend_scan_files" | xargs -r grep -nE 'fetch\([^)]*(router|rollout)|method:[[:space:]]*["'\'']POST["'\''][^;]*(router|rollout)|(router|rollout)[^;]*method:[[:space:]]*["'\'']POST["'\'']' >/tmp/phase11k-router-post.txt 2>/dev/null; then
  echo "FAIL: frontend router/rollout POST runtime marker found"
  cat /tmp/phase11k-router-post.txt
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
echo "=== confirm expected changed files only ==="
bad_status="$(
  git status --short \
    | grep -vE '^[ ?MADRCU]{1,2} frontend/wrapper-ui/app\.js$' \
    | grep -vE '^[ ?MADRCU]{1,2} docs/phase-11k-deterministic-answer-normalizer\.md$' \
    | grep -vE '^[ ?MADRCU]{1,2} ops/smoke/check-phase-11k-deterministic-answer-normalizer\.sh$' \
    || true
)"

git status --short

if [ -n "$bad_status" ]; then
  echo
  echo "FAIL: unexpected changed files detected"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 11K runtime/doc/smoke files are changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 11K deterministic answer normalizer smoke passed"
else
  echo "FAIL: Phase 11K deterministic answer normalizer smoke failed"
fi

exit "$fail"
