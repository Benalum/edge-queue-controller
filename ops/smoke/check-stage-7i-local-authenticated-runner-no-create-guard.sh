#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7I local authenticated runner no-create guard smoke ==="

fail=0

guard="docs/generated/stage-7i-local-authenticated-runner-no-create-guard.json"
doc="docs/stage-7i-local-authenticated-runner-no-create-guard.md"
stage7h="docs/generated/stage-7h-authenticated-shadow-comparison-runner-plan.json"
stage7h_doc="docs/stage-7h-authenticated-shadow-comparison-runner-plan.md"
stage7h_smoke="ops/smoke/check-stage-7h-authenticated-shadow-comparison-runner-plan.sh"
validator="ops/validate/validate-authenticated-shadow-comparison-artifact.py"
future_runner="ops/compare/run-authenticated-shadow-comparison.py"

for f in \
  "$guard" \
  "$doc" \
  "$stage7h" \
  "$stage7h_doc" \
  "$stage7h_smoke" \
  "$validator" \
  edge_intent_router.py \
  edge_controller.py
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate Stage 7I guard json ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-7i-local-authenticated-runner-no-create-guard.json").read_text())

assert data["stage"] == "7I"
assert data["runtime_behavior_change"] is False
assert data["phase"] == "authenticated_shadow_comparison_guardrails"

future = data["future_runner"]
assert future["planned_path"] == "ops/compare/run-authenticated-shadow-comparison.py"
assert future["must_not_exist_yet"] is True
assert future["created_in_this_stage"] is False
assert future["runtime_wired"] is False
assert future["http_endpoint_exposed"] is False
assert future["frontend_wired"] is False
assert future["backend_wired"] is False
assert future["gateway_wired"] is False
assert future["systemd_wired"] is False

for path in [
    "docs/generated/stage-7h-authenticated-shadow-comparison-runner-plan.json",
    "docs/stage-7h-authenticated-shadow-comparison-runner-plan.md",
    "ops/smoke/check-stage-7h-authenticated-shadow-comparison-runner-plan.sh",
    "docs/generated/stage-7i-local-authenticated-runner-no-create-guard.json",
    "docs/stage-7i-local-authenticated-runner-no-create-guard.md",
    "ops/smoke/check-stage-7i-local-authenticated-runner-no-create-guard.sh",
]:
    assert path in data["allowed_reference_locations"]

for path in [
    "edge_controller.py",
    "frontend/",
    "backend/",
    "public_gateway.py",
    "ops/systemd/",
]:
    assert path in data["blocked_runtime_locations"]

for pattern in [
    "ops/compare/run-authenticated-shadow-comparison.py",
    "run-authenticated-shadow-comparison",
    "EDGE_AUTH_SHADOW_COMPARE",
]:
    assert pattern in data["guarded_reference_patterns"]

runtime = data["required_runtime_state"]
assert runtime["router_endpoint_disabled_by_default"] is True
assert runtime["expected_router_disabled_http_code"] == 404
assert runtime["dispatch_enabled"] is False
assert runtime["model_calls_enabled"] is False
assert runtime["runtime_wiring_changed"] is False

print("OK: Stage 7I guard JSON is valid")
PY

echo
echo "=== future authenticated runner must not exist yet ==="
if [ -e "$future_runner" ]; then
  echo "FAIL: future runner exists before intentional creation: $future_runner"
  fail=1
else
  echo "OK: future runner does not exist"
fi

python3 -m py_compile "$validator" edge_intent_router.py edge_controller.py

echo
echo "=== guarded references must only appear in allowed docs/smokes ==="
python3 - <<'PY'
from pathlib import Path
import subprocess

allowed = {
    "docs/generated/stage-7h-authenticated-shadow-comparison-runner-plan.json",
    "docs/stage-7h-authenticated-shadow-comparison-runner-plan.md",
    "ops/smoke/check-stage-7h-authenticated-shadow-comparison-runner-plan.sh",
    "docs/generated/stage-7i-local-authenticated-runner-no-create-guard.json",
    "docs/stage-7i-local-authenticated-runner-no-create-guard.md",
    "ops/smoke/check-stage-7i-local-authenticated-runner-no-create-guard.sh",
}

patterns = [
    "ops/compare/run-authenticated-shadow-comparison.py",
    "run-authenticated-shadow-comparison",
    "EDGE_AUTH_SHADOW_COMPARE",
]

result = subprocess.run(
    ["git", "ls-files", "--cached", "--others", "--exclude-standard"],
    check=True,
    text=True,
    stdout=subprocess.PIPE,
)

files = [
    Path(line)
    for line in result.stdout.splitlines()
    if line
    and not line.startswith(".git/")
    and not line.startswith(".venv/")
    and not line.startswith("__pycache__/")
]

violations = []
for path in files:
    if not path.is_file():
        continue

    try:
        text = path.read_text(errors="replace")
    except Exception:
        continue

    for pattern in patterns:
        if pattern in text and str(path) not in allowed:
            violations.append((str(path), pattern))

if violations:
    print("FAIL: guarded references found outside allowed docs/smokes")
    for path, pattern in violations:
        print(f"{path}: {pattern}")
    raise SystemExit(1)

print("OK: guarded references only appear in allowed docs/smokes")
PY

echo
echo "=== no future runner references in blocked runtime locations ==="
blocked_hits="$(
  grep -RInE "ops/compare/run-authenticated-shadow-comparison.py|run-authenticated-shadow-comparison|EDGE_AUTH_SHADOW_COMPARE" \
    edge_controller.py \
    frontend \
    backend \
    public_gateway.py \
    ops/systemd 2>/dev/null || true
)"

if [ -n "$blocked_hits" ]; then
  echo "FAIL: future runner references found in blocked runtime locations"
  echo "$blocked_hits"
  fail=1
else
  echo "OK: future runner references not found in blocked runtime locations"
fi

echo
echo "=== router endpoint should remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage7i-router-disabled.json \
      -w "%{http_code}" \
      -X POST http://127.0.0.1:7070/api/router/dry-run \
      -H 'Content-Type: application/json' \
      --data '{"input":{"text":"hello","source":"companion","surface":"companion_chat"},"context":{"active_page":"companion"}}' || true
  )"

  echo "router_disabled_http_code=$code"

  if [ "$code" = "404" ]; then
    echo "OK: router endpoint remains disabled by default"
  else
    echo "FAIL: router endpoint should still be disabled by default"
    cat /tmp/stage7i-router-disabled.json || true
    fail=1
  fi
else
  echo "WARN: controller inactive; skipped router disabled check"
fi

echo
echo "=== no runtime/systemd files should be modified ==="
if git diff --name-only | grep -E '(^edge_controller.py$|^edge_intent_router.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)'; then
  echo "FAIL: runtime/systemd files modified"
  fail=1
else
  echo "OK: no runtime/systemd file modifications detected"
fi

git status --short

if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 7I local authenticated runner no-create guard smoke passed"
else
  echo "FAIL: Stage 7I local authenticated runner no-create guard smoke failed"
fi

exit "$fail"
