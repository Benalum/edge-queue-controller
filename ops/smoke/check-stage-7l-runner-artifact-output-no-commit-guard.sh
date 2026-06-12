#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7L runner artifact output no-commit guard smoke ==="

fail=0

guard="docs/generated/stage-7l-runner-artifact-output-no-commit-guard.json"
doc="docs/stage-7l-runner-artifact-output-no-commit-guard.md"
runner="ops/compare/run-authenticated-shadow-comparison.py"
validator="ops/validate/validate-authenticated-shadow-comparison-artifact.py"
stage7k="docs/generated/stage-7k-runner-no-wire-runtime-isolation-guard.json"
ignored_output="ops/compare/output/stage7l-study.local-auth-shadow.json"
ignored_auth_output="docs/generated/authenticated-shadow-comparison-results/stage7l-companion.auth-shadow-comparison.json"

for f in \
  "$guard" \
  "$doc" \
  "$runner" \
  "$validator" \
  "$stage7k" \
  .gitignore \
  edge_intent_router.py \
  edge_controller.py
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate Stage 7L guard json ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-7l-runner-artifact-output-no-commit-guard.json").read_text())

assert data["stage"] == "7L"
assert data["runtime_behavior_change"] is False
assert data["phase"] == "authenticated_shadow_comparison_guardrails"

strategy = data["guard_strategy"]
assert strategy["use_gitignore"] is True
assert "ops/compare/output/" in strategy["ignored_output_locations"]
assert "docs/generated/authenticated-shadow-comparison-results/" in strategy["ignored_output_locations"]
assert "*.auth-shadow-comparison.json" in strategy["ignored_file_patterns"]
assert "*.authenticated-shadow-comparison.json" in strategy["ignored_file_patterns"]
assert "*.local-auth-shadow.json" in strategy["ignored_file_patterns"]

assert "docs/generated/stage-7g-study-authenticated-shadow-comparison-example-artifact.json" in strategy["tracked_examples_allowed"]
assert "docs/generated/stage-7g-companion-authenticated-shadow-comparison-example-artifact.json" in strategy["tracked_examples_allowed"]

runner = data["runner"]
assert runner["path"] == "ops/compare/run-authenticated-shadow-comparison.py"
assert runner["manual_ops_tool_only"] is True
assert runner["default_output_safe"] is True
assert runner["explicit_output_must_prefer_ignored_locations"] is True
assert runner["auth_values_may_be_printed"] is False
assert runner["auth_values_may_be_stored"] is False
assert runner["raw_authenticated_response_may_be_stored"] is False

for check in [
    "gitignore contains Stage 7L output rules",
    "runner can write a sanitized artifact into an ignored output path",
    "ignored output artifact validates with Stage 7E validator",
    "ignored output artifact does not appear in normal git status",
    "git check-ignore confirms ignored output path",
    "auth environment value is not printed or stored",
    "runner remains absent from blocked runtime locations"
]:
    assert check in data["required_checks"]

runtime = data["required_runtime_state"]
assert runtime["router_endpoint_disabled_by_default"] is True
assert runtime["expected_router_disabled_http_code"] == 404
assert runtime["dispatch_enabled"] is False
assert runtime["model_calls_enabled"] is False
assert runtime["runtime_wiring_changed"] is False

print("OK: Stage 7L guard JSON is valid")
PY

echo
echo "=== verify .gitignore contains Stage 7L rules ==="
for pattern in \
  "ops/compare/output/" \
  "docs/generated/authenticated-shadow-comparison-results/" \
  "*.auth-shadow-comparison.json" \
  "*.authenticated-shadow-comparison.json" \
  "*.local-auth-shadow.json"
do
  if grep -Fx "$pattern" .gitignore >/dev/null; then
    echo "OK: .gitignore contains $pattern"
  else
    echo "FAIL: .gitignore missing $pattern"
    fail=1
  fi
done

.venv/bin/python -m py_compile "$runner" "$validator" edge_intent_router.py edge_controller.py

echo
echo "=== runner should write sanitized ignored Study artifact ==="
rm -f "$ignored_output" /tmp/stage7l-study.out

.venv/bin/python "$runner" \
  --domain study \
  --case study_next \
  --output "$ignored_output" \
  > /tmp/stage7l-study.out 2>&1

cat /tmp/stage7l-study.out
python3 "$validator" "$ignored_output"

if git check-ignore -q "$ignored_output"; then
  echo "OK: git check-ignore confirms ignored Study output"
else
  echo "FAIL: Study output is not ignored"
  fail=1
fi

if [ -z "$(git status --short "$ignored_output")" ]; then
  echo "OK: ignored Study output does not appear in normal git status"
else
  echo "FAIL: ignored Study output appears in normal git status"
  git status --short "$ignored_output"
  fail=1
fi

echo
echo "=== runner should not print/store auth env value in ignored Companion artifact ==="
secret_cookie="session=stage7l_super_secret_cookie_value_1234567890"
rm -f "$ignored_auth_output" /tmp/stage7l-companion.out

EDGE_AUTH_SHADOW_COMPARE_COOKIE="$secret_cookie" \
.venv/bin/python "$runner" \
  --domain companion \
  --case companion_chat \
  --output "$ignored_auth_output" \
  > /tmp/stage7l-companion.out 2>&1

cat /tmp/stage7l-companion.out
python3 "$validator" "$ignored_auth_output"

if grep -R "stage7l_super_secret_cookie_value_1234567890" /tmp/stage7l-companion.out "$ignored_auth_output" >/dev/null 2>&1; then
  echo "FAIL: auth value leaked into output or artifact"
  fail=1
else
  echo "OK: auth value not printed or stored"
fi

if git check-ignore -q "$ignored_auth_output"; then
  echo "OK: git check-ignore confirms ignored Companion output"
else
  echo "FAIL: Companion output is not ignored"
  fail=1
fi

if [ -z "$(git status --short "$ignored_auth_output")" ]; then
  echo "OK: ignored Companion output does not appear in normal git status"
else
  echo "FAIL: ignored Companion output appears in normal git status"
  git status --short "$ignored_auth_output"
  fail=1
fi

echo
echo "=== tracked Stage 7G dry-run examples should remain tracked ==="
for tracked in \
  docs/generated/stage-7g-study-authenticated-shadow-comparison-example-artifact.json \
  docs/generated/stage-7g-companion-authenticated-shadow-comparison-example-artifact.json
do
  if git ls-files --error-unmatch "$tracked" >/dev/null 2>&1; then
    echo "OK: tracked example remains tracked: $tracked"
  else
    echo "FAIL: tracked example missing from git index: $tracked"
    fail=1
  fi
done

echo
echo "=== Stage 7L must not be wired into blocked runtime locations ==="
blocked_hits="$(
  grep -RInE "stage-7l|stage_7l|auth-shadow-comparison|local-auth-shadow|authenticated-shadow-comparison-results|ops/compare/output" \
    edge_controller.py \
    frontend \
    backend \
    public_gateway.py \
    ops/systemd 2>/dev/null || true
)"

if [ -n "$blocked_hits" ]; then
  echo "FAIL: Stage 7L output guard references found in blocked runtime locations"
  echo "$blocked_hits"
  fail=1
else
  echo "OK: Stage 7L output guard references not found in blocked runtime locations"
fi

echo
echo "=== runner references must remain absent from service/scheduler files ==="
systemd_hits="$(
  grep -RInE "run-authenticated-shadow-comparison|EDGE_AUTH_SHADOW_COMPARE|ops/compare/output|auth-shadow-comparison" \
    ops/systemd \
    /etc/systemd/system/edge-queue-controller.service.d 2>/dev/null || true
)"

if [ -n "$systemd_hits" ]; then
  echo "FAIL: runner/output references found in service/scheduler locations"
  echo "$systemd_hits"
  fail=1
else
  echo "OK: runner/output references not found in service/scheduler locations"
fi

echo
echo "=== router endpoint should remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage7l-router-disabled.json \
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
    cat /tmp/stage7l-router-disabled.json || true
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
  echo "PASS: Stage 7L runner artifact output no-commit guard smoke passed"
else
  echo "FAIL: Stage 7L runner artifact output no-commit guard smoke failed"
fi

exit "$fail"
