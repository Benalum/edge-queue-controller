#!/usr/bin/env bash
set -u

fail=0

echo "=== Phase 11N smoke: deterministic Study continue aliases ==="

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root" || fail=1

frontend_file="frontend/wrapper-ui/app.js"
backend_file="edge_controller.py"

echo
echo "=== repo root ==="
pwd

echo
echo "=== marker/static checks ==="
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

check_marker "frontend next question alias" '"next question"' "$frontend_file"
check_marker "frontend continue alias" '"continue"' "$frontend_file"
check_marker "frontend go on alias" '"go on"' "$frontend_file"
check_marker "frontend move on alias" '"move on"' "$frontend_file"
check_marker "backend session_status_text" "session_status_text = str(session_status or \"none\")" "$backend_file"
check_marker "backend paused continue resume guard" "Paused study session and user requested resume/continue." "$backend_file"
check_marker "backend active continue next guard" "Active study session and user requested next/continue." "$backend_file"

echo
echo "=== frontend JavaScript command detector behavior ==="
node_bin=""
if command -v node >/dev/null 2>&1; then
  node_bin="node"
elif command -v nodejs >/dev/null 2>&1; then
  node_bin="nodejs"
fi

if [ -z "$node_bin" ]; then
  echo "FAIL: node/nodejs not found for frontend behavior tests"
  fail=1
else
  python3 - <<'PY'
from pathlib import Path

runtime = Path("frontend/wrapper-ui/app.js").read_text()
start = runtime.index("function stage5p11iNormalizeStudyPhrase")
end = runtime.index("function stage5p11iSelectedDeckId", start)

test_js = runtime[start:end] + r'''

const cases = [
  ["next", true],
  ["next card", true],
  ["next question", true],
  ["continue", true],
  ["continue card", true],
  ["continue cards", true],
  ["go on", true],
  ["move on", true],
  ["five", false],
  ["twenty one", false]
];

let failed = 0;

for (const [message, expected] of cases) {
  const actual = stage5p11iLooksLikeStudyCommand(message);
  if (actual !== expected) {
    console.error("FAIL:", JSON.stringify({ message, expected, actual }));
    failed += 1;
  } else {
    console.log("PASS:", JSON.stringify({ message, expected }));
  }
}

if (failed) process.exit(1);
'''

Path("/tmp/phase11n-frontend-command-detector-test.js").write_text(test_js)
PY

  "$node_bin" /tmp/phase11n-frontend-command-detector-test.js || fail=1
fi

echo
echo "=== backend deterministic parser behavior via extracted function ==="
python3 - <<'PY' || fail=1
from pathlib import Path
import re

source = Path("edge_controller.py").read_text()

helper_start = source.index("def _study_normalize_intent_text")
parser_end = source.index("@app.post(\"/public/study/intent/parse\")", helper_start)

snippet = source[helper_start:parser_end]

ns = {}
exec(snippet, ns)

parse = ns["_study_parse_deterministic_intent"]

cases = [
    ("next", "active", "study_next_card", "next_card"),
    ("next card", "active", "study_next_card", "next_card"),
    ("next question", "active", "study_next_card", "next_card"),
    ("continue", "active", "study_next_card", "next_card"),
    ("go on", "active", "study_next_card", "next_card"),
    ("move on", "active", "study_next_card", "next_card"),
    ("continue", "reviewing_answer", "study_next_card", "next_card"),
    ("continue", "waiting_for_mark", "study_next_card", "next_card"),
    ("continue", "paused", "study_session_resume", "resume"),
    ("five", "active", "study_answer_attempt", "submit_answer"),
]

failed = 0

for message, status, expected_intent, expected_command in cases:
    parsed = parse(message, session_status=status)
    actual_intent = parsed.get("intent")
    actual_command = parsed.get("command")
    if actual_intent != expected_intent or actual_command != expected_command:
        print("FAIL:", {
            "message": message,
            "status": status,
            "expected_intent": expected_intent,
            "expected_command": expected_command,
            "actual_intent": actual_intent,
            "actual_command": actual_command,
            "parsed": parsed,
        })
        failed += 1
    else:
        print("PASS:", {
            "message": message,
            "status": status,
            "intent": actual_intent,
            "command": actual_command,
        })

if failed:
    raise SystemExit(1)
PY

echo
echo "=== exact patched contexts ==="
echo "--- frontend command detector ---"
nl -ba "$frontend_file" | sed -n '3665,3710p'

echo
echo "--- backend parser next/continue area ---"
parser_line="$(grep -nF "def _study_parse_deterministic_intent" "$backend_file" | head -n 1 | cut -d: -f1 || true)"
if [ -n "$parser_line" ]; then
  start=$((parser_line - 5))
  end=$((parser_line + 130))
  [ "$start" -lt 1 ] && start=1
  nl -ba "$backend_file" | sed -n "${start},${end}p"
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
if echo "$backend_scan_files" | xargs -r grep -nE 'os\.getenv\(["'\'']EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY|os\.environ\.get\(["'\'']EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY|Environment=.*EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY|EDGE_[A-Z0-9_]*ROUTER[A-Z0-9_]*DRY[A-Z0-9_]*=' >/tmp/phase11n-router-dry-env.txt 2>/dev/null; then
  echo "FAIL: backend router dry-run env marker found"
  cat /tmp/phase11n-router-dry-env.txt
  router_fail=1
else
  echo "PASS: no backend router dry-run env marker found"
fi

echo
echo "--- frontend router/rollout POST guard ---"
if echo "$frontend_scan_files" | xargs -r grep -nE 'fetch\([^)]*(router|rollout)|method:[[:space:]]*["'\'']POST["'\''][^;]*(router|rollout)|(router|rollout)[^;]*method:[[:space:]]*["'\'']POST["'\'']' >/tmp/phase11n-router-post.txt 2>/dev/null; then
  echo "FAIL: frontend router/rollout POST runtime marker found"
  cat /tmp/phase11n-router-post.txt
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
    | grep -vE '^[ ?MADRCU]{1,2} edge_controller\.py$' \
    | grep -vE '^[ ?MADRCU]{1,2} docs/phase-11n-deterministic-study-continue-aliases\.md$' \
    | grep -vE '^[ ?MADRCU]{1,2} ops/smoke/check-phase-11n-deterministic-study-continue-aliases\.sh$' \
    || true
)"

git status --short

if [ -n "$bad_status" ]; then
  echo
  echo "FAIL: unexpected changed files detected"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 11N runtime/doc/smoke files are changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 11N deterministic Study continue aliases smoke passed"
else
  echo "FAIL: Phase 11N deterministic Study continue aliases smoke failed"
fi

exit "$fail"
