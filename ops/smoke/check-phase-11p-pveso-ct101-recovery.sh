#!/usr/bin/env bash
set -u

fail=0

echo "=== Phase 11P smoke: pveso / CT101 recovery ==="

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root" || fail=1

echo
echo "=== git baseline ==="
git log --oneline -5
git tag --points-at HEAD

echo
echo "=== controller health ==="
controller_code="$(curl -sS --max-time 10 -o /tmp/phase11p-controller-health.json -w '%{http_code}' http://127.0.0.1:7070/health 2>/dev/null || true)"
cat /tmp/phase11p-controller-health.json 2>/dev/null || true
echo

if [ "$controller_code" = "200" ]; then
  echo "PASS: controller health returned 200"
else
  echo "FAIL: controller health code was $controller_code"
  fail=1
fi

echo
echo "=== pveso Tailscale ping ==="
if tailscale ping --timeout=5s --c 1 100.88.194.19; then
  echo "PASS: pveso Tailscale ping works"
else
  echo "FAIL: pveso Tailscale ping failed"
  fail=1
fi

echo
echo "=== pveso SSH / CT101 status ==="
timeout 20 ssh \
  -o BatchMode=yes \
  -o ConnectTimeout=8 \
  -o StrictHostKeyChecking=accept-new \
  root@100.88.194.19 \
  'echo PVE_OK; hostname; cat /proc/loadavg; pct status 101' \
  2>&1 | tee /tmp/phase11p-pveso-ct101-status.txt

if grep -q "PVE_OK" /tmp/phase11p-pveso-ct101-status.txt; then
  echo "PASS: pveso SSH works"
else
  echo "FAIL: pveso SSH failed"
  fail=1
fi

if grep -q "status: running" /tmp/phase11p-pveso-ct101-status.txt; then
  echo "PASS: CT101 is running"
else
  echo "FAIL: CT101 is not confirmed running"
  fail=1
fi

echo
echo "=== CT101 direct Tailscale health ==="
if tailscale ping --timeout=5s --c 1 100.88.245.33; then
  echo "PASS: CT101 Tailscale ping works"
else
  echo "FAIL: CT101 Tailscale ping failed"
  fail=1
fi

ct101_code="$(curl -sS --max-time 10 -D /tmp/phase11p-ct101-health-headers.txt -o /tmp/phase11p-ct101-health-body.txt -w '%{http_code}' \
  http://100.88.245.33:8088/health 2>/dev/null || true)"

sed -n '1,30p' /tmp/phase11p-ct101-health-headers.txt 2>/dev/null || true
cat /tmp/phase11p-ct101-health-body.txt 2>/dev/null || true
echo

if [ "$ct101_code" = "200" ]; then
  echo "PASS: CT101 API health returned 200"
else
  echo "FAIL: CT101 API health code was $ct101_code"
  fail=1
fi

echo
echo "=== system status normalized checks ==="
curl -sS --max-time 15 http://127.0.0.1:7070/system/status > /tmp/phase11p-system-status.json || fail=1

jq '{overall_state, platform: .normalized.platform}' /tmp/phase11p-system-status.json || true

overall_state="$(jq -r '.overall_state // ""' /tmp/phase11p-system-status.json 2>/dev/null || true)"
ct101_state="$(jq -r '.normalized.platform[]? | select(.id=="ct101-laptop-queue-worker") | .state' /tmp/phase11p-system-status.json 2>/dev/null || true)"
queue_state="$(jq -r '.normalized.platform[]? | select(.id=="queue") | .state' /tmp/phase11p-system-status.json 2>/dev/null || true)"
workers_state="$(jq -r '.normalized.platform[]? | select(.id=="workers") | .state' /tmp/phase11p-system-status.json 2>/dev/null || true)"

echo "overall_state=$overall_state"
echo "ct101_state=$ct101_state"
echo "queue_state=$queue_state"
echo "workers_state=$workers_state"

if [ "$overall_state" = "online" ]; then
  echo "PASS: overall_state is online"
else
  echo "FAIL: overall_state is $overall_state"
  fail=1
fi

if [ "$ct101_state" = "online" ]; then
  echo "PASS: CT101 worker platform state is online"
else
  echo "FAIL: CT101 worker platform state is $ct101_state"
  fail=1
fi

if [ "$queue_state" = "online" ]; then
  echo "PASS: queue platform state is online"
else
  echo "FAIL: queue platform state is $queue_state"
  fail=1
fi

if [ "$workers_state" = "online" ]; then
  echo "PASS: workers platform state is online"
else
  echo "FAIL: workers platform state is $workers_state"
  fail=1
fi

echo
echo "=== confirm docs/smoke changes only ==="
bad_status="$(
  git status --short \
    | grep -vE '^[ ?MADRCU]{1,2} docs/phase-11p-pveso-ct101-recovery\.md$' \
    | grep -vE '^[ ?MADRCU]{1,2} ops/smoke/check-phase-11p-pveso-ct101-recovery\.sh$' \
    || true
)"

git status --short

if [ -n "$bad_status" ]; then
  echo
  echo "FAIL: unexpected changed files detected"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 11P docs/smoke files are changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 11P pveso / CT101 recovery smoke passed"
else
  echo "FAIL: Phase 11P pveso / CT101 recovery smoke failed"
fi

exit "$fail"
