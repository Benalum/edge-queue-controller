#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7M runner authenticated execution manual runbook smoke ==="

fail=0

contract="docs/generated/stage-7m-runner-authenticated-execution-manual-runbook.json"
doc="docs/stage-7m-runner-authenticated-execution-manual-runbook.md"
runner="ops/compare/run-authenticated-shadow-comparison.py"
validator="ops/validate/validate-authenticated-shadow-comparison-artifact.py"
stage7l="docs/generated/stage-7l-runner-artifact-output-no-commit-guard.json"

for f in \
  "$contract" \
  "$doc" \
  "$runner" \
  "$validator" \
  "$stage7l" \
  .gitignore \
  edge_intent_router.py \
  edge_controller.py
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate Stage 7M runbook contract json ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-7m-runner-authenticated-execution-manual-runbook.json").read_text())

assert data["stage"] == "7M"
assert data["runtime_behavior_change"] is False
assert data["phase"] == "authenticated_shadow_comparison_guardrails"

scope = data["runbook_scope"]
assert scope["creates_runner"] is False
assert scope["runs_authenticated_comparison"] is False
assert scope["documents_manual_steps_only"] is True
assert scope["runtime_wired"] is False
assert scope["http_endpoint_exposed"] is False
assert scope["frontend_wired"] is False
assert scope["backend_wired"] is False
assert scope["gateway_wired"] is False
assert scope["systemd_wired"] is False

assert "ops/compare/run-authenticated-shadow-comparison.py" in data["required_tools"]
assert "ops/validate/validate-authenticated-shadow-comparison-artifact.py" in data["required_tools"]

for path in [
    "ops/compare/output/",
    "docs/generated/authenticated-shadow-comparison-results/",
]:
    assert path in data["safe_output_locations"]

for pattern in [
    "*.local-auth-shadow.json",
    "*.auth-shadow-comparison.json",
    "*.authenticated-shadow-comparison.json",
]:
    assert pattern in data["safe_output_patterns"]

for step in [
    "confirm working tree status before starting",
    "authenticate locally outside the repository",
    "set non-secret base URL",
    "read authentication value into a shell variable without echoing it",
    "export exactly one runtime-only auth environment variable",
    "run one Study comparison into an ignored output path",
    "run one Companion comparison into an ignored output path",
    "validate artifacts with the Stage 7E validator",
    "confirm output artifacts are ignored by git",
    "unset authentication environment variables",
    "confirm no secrets appear in git status or tracked files",
]:
    assert step in data["manual_steps"]

checks = data["required_safety_checks"]
assert checks["runbook_contains_no_secret_like_values"] is True
assert checks["authenticated_execution_not_run_by_smoke"] is True
assert checks["output_paths_are_ignored"] is True
assert checks["runner_remains_manual_ops_only"] is True
assert checks["runner_not_wired_into_runtime"] is True
assert checks["router_endpoint_disabled_by_default"] is True

runtime = data["required_runtime_state"]
assert runtime["router_endpoint_disabled_by_default"] is True
assert runtime["expected_router_disabled_http_code"] == 404
assert runtime["dispatch_enabled"] is False
assert runtime["model_calls_enabled"] is False
assert runtime["runtime_wiring_changed"] is False

print("OK: Stage 7M runbook contract JSON is valid")
PY

echo
echo "=== verify required commands appear in runbook doc ==="
for pattern in \
  "git status --short" \
  "read -rsp" \
  "export EDGE_AUTH_SHADOW_COMPARE_BASE_URL" \
  "export EDGE_AUTH_SHADOW_COMPARE_COOKIE" \
  "export EDGE_AUTH_SHADOW_COMPARE_BEARER" \
  "ops/compare/run-authenticated-shadow-comparison.py" \
  "YES_EXISTING_ROUTE_MAY_CHANGE_STATE" \
  "ops/validate/validate-authenticated-shadow-comparison-artifact.py" \
  "git check-ignore" \
  "unset EDGE_AUTH_SHADOW_COMPARE_COOKIE EDGE_AUTH_SHADOW_COMPARE_BEARER"
do
  if grep -F "$pattern" "$doc" >/dev/null; then
    echo "OK: runbook contains $pattern"
  else
    echo "FAIL: runbook missing $pattern"
    fail=1
  fi
done

echo
echo "=== verify output paths are ignored ==="
for path in \
  ops/compare/output/study-next.manual.local-auth-shadow.json \
  ops/compare/output/companion-chat.manual.local-auth-shadow.json \
  docs/generated/authenticated-shadow-comparison-results/example.auth-shadow-comparison.json
do
  if git check-ignore -q "$path"; then
    echo "OK: ignored output path confirmed: $path"
  else
    echo "FAIL: output path is not ignored: $path"
    fail=1
  fi
done

.venv/bin/python -m py_compile "$runner" "$validator" edge_intent_router.py edge_controller.py

echo
echo "=== smoke must not run authenticated execution ==="
auth_exec_hits="$(
  grep -nF -- "--execute-authenticated" "$0" \
    | grep -v 'grep -nF -- "--execute-authenticated"' \
    || true
)"

if [ -n "$auth_exec_hits" ]; then
  echo "FAIL: Stage 7M smoke should not execute authenticated comparisons"
  echo "$auth_exec_hits"
  fail=1
else
  echo "OK: Stage 7M smoke does not execute authenticated comparisons"
fi

echo
echo "=== offline runner still works and output remains ignored ==="
ignored_output="ops/compare/output/stage7m-offline-check.local-auth-shadow.json"
rm -f "$ignored_output" /tmp/stage7m-offline.out

.venv/bin/python "$runner" \
  --domain study \
  --case study_next \
  --output "$ignored_output" \
  > /tmp/stage7m-offline.out 2>&1

cat /tmp/stage7m-offline.out
python3 "$validator" "$ignored_output"

if git check-ignore -q "$ignored_output"; then
  echo "OK: offline check output is ignored"
else
  echo "FAIL: offline check output is not ignored"
  fail=1
fi

echo
echo "=== scan Stage 7M files for secret-like values ==="
python3 - <<'PY'
import re
from pathlib import Path

files = [
    Path("docs/generated/stage-7m-runner-authenticated-execution-manual-runbook.json"),
    Path("docs/stage-7m-runner-authenticated-execution-manual-runbook.md"),
]

patterns = {
    "private_key_block": re.compile(r"BEGIN [A-Z ]*PRIVATE KEY"),
    "openai_like_secret": re.compile(r"\bsk-[A-Za-z0-9_-]{20,}\b"),
    "github_pat": re.compile(r"\bgh[pousr]_[A-Za-z0-9_]{20,}\b"),
    "tailscale_key": re.compile(r"\btskey-[A-Za-z0-9_-]{20,}\b"),
    "aws_access_key": re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    "jwt_like_value": re.compile(r"\beyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b"),
    "bearer_value": re.compile(r"Authorization:\s*Bearer\s+\S+", re.IGNORECASE),
}

hits = []
for path in files:
    text = path.read_text(errors="replace")
    for name, pattern in patterns.items():
        if pattern.search(text):
            hits.append((str(path), name))

if hits:
    print("FAIL: secret-like values detected")
    for path, name in hits:
        print(f"{path}: {name}")
    raise SystemExit(1)

print("OK: no secret-like values detected in Stage 7M files")
PY

echo
echo "=== Stage 7M must not be wired into blocked runtime locations ==="
blocked_hits="$(
  grep -RInE "stage-7m|stage_7m|runner-authenticated-execution-manual-runbook|study-next.manual.local-auth-shadow|companion-chat.manual.local-auth-shadow" \
    edge_controller.py \
    frontend \
    backend \
    public_gateway.py \
    ops/systemd 2>/dev/null || true
)"

if [ -n "$blocked_hits" ]; then
  echo "FAIL: Stage 7M runbook references found in blocked runtime locations"
  echo "$blocked_hits"
  fail=1
else
  echo "OK: Stage 7M runbook references not found in blocked runtime locations"
fi

echo
echo "=== runner references must remain absent from service/scheduler files ==="
systemd_hits="$(
  grep -RInE "run-authenticated-shadow-comparison|EDGE_AUTH_SHADOW_COMPARE|local-auth-shadow|auth-shadow-comparison" \
    ops/systemd \
    /etc/systemd/system/edge-queue-controller.service.d 2>/dev/null || true
)"

if [ -n "$systemd_hits" ]; then
  echo "FAIL: runner/runbook references found in service/scheduler locations"
  echo "$systemd_hits"
  fail=1
else
  echo "OK: runner/runbook references not found in service/scheduler locations"
fi

echo
echo "=== router endpoint should remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage7m-router-disabled.json \
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
    cat /tmp/stage7m-router-disabled.json || true
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
  echo "PASS: Stage 7M runner authenticated execution manual runbook smoke passed"
else
  echo "FAIL: Stage 7M runner authenticated execution manual runbook smoke failed"
fi

exit "$fail"
