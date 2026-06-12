#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6B Universal Intent Router input surface audit smoke ==="

fail=0

doc6a="docs/stage-6a-universal-intent-router-foundation-plan.md"
doc6b="docs/stage-6b-universal-intent-router-input-surface-audit.md"

echo
echo "=== required docs ==="
for f in "$doc6a" "$doc6b"; do
  if [ -s "$f" ]; then
    echo "OK: $f"
  else
    echo "FAIL: missing or empty $f"
    fail=1
  fi
done

echo
echo "=== required Stage 6B markers ==="
for marker in \
  "Universal Intent Router Input Surface Audit" \
  "This stage does not change runtime behavior" \
  "Fast intent model" \
  "Medium conversation model" \
  "Preferred language" \
  "Early migration candidates" \
  "Bad early candidates"
do
  if grep -q "$marker" "$doc6b"; then
    echo "OK: found marker: $marker"
  else
    echo "FAIL: missing marker: $marker"
    fail=1
  fi
done

echo
echo "=== router contract markers ==="
for marker in \
  "Receive input" \
  "Load authenticated user context" \
  "Detect language" \
  "Detect intent" \
  "Dispatch to existing service"
do
  if grep -q "$marker" "$doc6b"; then
    echo "OK: found contract marker: $marker"
  else
    echo "FAIL: missing contract marker: $marker"
    fail=1
  fi
done

echo
echo "=== runtime code should not be modified for this planning stage ==="
if git diff --name-only | grep -E '(^edge_controller.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' >/dev/null; then
  echo "FAIL: runtime or systemd files are modified:"
  git diff --name-only | grep -E '(^edge_controller.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' || true
  fail=1
else
  echo "OK: no runtime/systemd file modifications detected"
fi

echo
echo "=== git status ==="
git status --short

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 6B Universal Intent Router input surface audit smoke passed"
else
  echo "FAIL: Stage 6B Universal Intent Router input surface audit smoke failed"
fi

exit "$fail"
