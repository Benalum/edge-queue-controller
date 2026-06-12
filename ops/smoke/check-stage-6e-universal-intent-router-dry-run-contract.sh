#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6E Universal Intent Router dry-run contract smoke ==="

fail=0

doc6e="docs/stage-6e-universal-intent-router-dry-run-contract.md"
classification="docs/generated/stage-6d-route-classification.tsv"
contract_json="docs/generated/stage-6e-router-contract.example.json"

for f in "$doc6e" "$classification" "$contract_json"; do
  if [ -s "$f" ]; then
    echo "OK: $f"
  else
    echo "FAIL: missing or empty $f"
    fail=1
  fi
done

python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-6e-router-contract.example.json").read_text())

for key in ["input", "context", "page_context", "router_options"]:
    assert key in data["request"], key

for key in ["ok", "dry_run", "dispatch_performed", "language", "intent", "target", "model_routing", "safety", "actions", "errors"]:
    assert key in data["response"], key

assert data["response"]["dry_run"] is True
assert data["response"]["dispatch_performed"] is False
assert data["response"]["safety"]["allowed_to_dispatch"] is False
assert data["response"]["intent"]["name"] == "study.next"

print("OK: contract json is valid and dry-run safe")
PY

for marker in \
  "This stage does not change runtime behavior" \
  "Router request contract" \
  "Router response contract" \
  "Canonical intent names" \
  "fast_intent" \
  "medium_conversation" \
  "large_reasoning" \
  "Dry-run router must not dispatch" \
  "Never dispatch directly" \
  "Language policy"
do
  if grep -q "$marker" "$doc6e"; then
    echo "OK: found marker: $marker"
  else
    echo "FAIL: missing marker: $marker"
    fail=1
  fi
done

for route in \
  "/api/study/intent/parse" \
  "/api/study/session/command" \
  "/api/companion/chat" \
  "/api/chat/queued"
do
  if grep -q "$route" "$classification"; then
    echo "OK: route present in classification: $route"
  else
    echo "FAIL: route missing from classification: $route"
    fail=1
  fi
done

if git diff --name-only | grep -E '(^edge_controller.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' >/dev/null; then
  echo "FAIL: runtime/systemd files modified"
  git diff --name-only | grep -E '(^edge_controller.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' || true
  fail=1
else
  echo "OK: no runtime/systemd file modifications detected"
fi

git status --short

if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 6E Universal Intent Router dry-run contract smoke passed"
else
  echo "FAIL: Stage 6E Universal Intent Router dry-run contract smoke failed"
fi

exit "$fail"
