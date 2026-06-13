#!/usr/bin/env bash
set -u

fail=0
DOC="docs/phase-11x-live-optional-queue-lane-claim-endpoint-activation.md"

echo "=== Phase 11X smoke: live optional queue_lane claim endpoint activation ==="
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== git baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== source/doc marker checks ==="
grep -R -Fq "STAGE_5P11W_OPTIONAL_QUEUE_LANE_CLAIM_BEGIN" edge_modules/laptop_queue.py edge_controller.py && echo "PASS: Phase 11W source marker found" || fail=1
grep -R -Fq "queue_lane_filter" edge_modules/laptop_queue.py && echo "PASS: queue_lane filter source found" || fail=1
grep -R -Fq "queue_lane=request.queue_lane" edge_controller.py && echo "PASS: live endpoint source passes queue_lane" || fail=1
grep -Fq "Phase 11X Live Optional Queue Lane Claim Endpoint Activation" "$DOC" && echo "PASS: Phase 11X doc title found" || fail=1
grep -Fq "live HTTP claim with queue_lane=model-small claimed the model-small job" "$DOC" && echo "PASS: lane proof doc marker found" || fail=1
grep -Fq "Current CT101 managed worker behavior remains backward compatible" "$DOC" && echo "PASS: CT101 compatibility doc marker found" || fail=1

echo
echo "=== syntax check ==="
python3 -m py_compile edge_modules/laptop_queue.py edge_controller.py && echo "PASS: py_compile ok" || fail=1

echo
echo "=== live controller health ==="
curl -sS --max-time 8 -o /tmp/phase11x-smoke-health.json -w "health_code=%{http_code} time=%{time_total}\n" http://127.0.0.1:7070/health || fail=1
python3 -c "import json; d=json.load(open(\"/tmp/phase11x-smoke-health.json\")); assert d.get(\"ok\") is True; print(\"PASS: controller health ok\")" || fail=1

echo
echo "=== live controller process freshness ==="
main_pid="$(systemctl show edge-queue-controller -p MainPID --value)"
module_mtime="$(stat -c %Y edge_controller.py)"
proc_start="$(python3 -c "import os,sys,time; pid=sys.argv[1]; clk=os.sysconf(os.sysconf_names[\"SC_CLK_TCK\"]); parts=open(f\"/proc/{pid}/stat\").read().split(); up=float(open(\"/proc/uptime\").read().split()[0]); print(int(time.time()-up+int(parts[21])/clk))" "$main_pid")"
echo "main_pid=$main_pid"
echo "module_mtime=$module_mtime"
echo "proc_start=$proc_start"
if [ "$main_pid" = "0" ] || [ -z "$main_pid" ]; then echo "FAIL: controller main PID missing"; fail=1; elif [ "$proc_start" -lt "$module_mtime" ]; then echo "FAIL: controller process is older than Phase 11W source"; fail=1; else echo "PASS: controller process is newer than Phase 11W source"; fi

echo
echo "=== live system status JSON check ==="
curl -sS --max-time 10 http://127.0.0.1:7070/system/status | python3 -m json.tool >/tmp/phase11x-smoke-system-status.json && echo "PASS: /system/status JSON ok" || fail=1

echo
echo "=== router rollout parked guard ==="
if systemctl show edge-queue-controller -p Environment --value | tr " " "\n" | grep -E "ROUTER.*DRY_RUN|PERSISTENT.*ROLLOUT.*ENABLED=1"; then echo "FAIL: unexpected router rollout env found"; fail=1; else echo "PASS: no active router rollout env found"; fi

echo
echo "=== changed files guard ==="
bad_status="$(git status --short | grep -vE "^[?][?] docs/phase-11x-live-optional-queue-lane-claim-endpoint-activation\.md$" | grep -vE "^[?][?] ops/smoke/check-phase-11x-live-optional-queue-lane-claim-endpoint-activation\.sh$" || true)"
git status --short
if [ -n "$bad_status" ]; then echo "FAIL: unexpected changed files"; echo "$bad_status"; fail=1; else echo "PASS: only Phase 11X doc/smoke files changed"; fi

echo
if [ "$fail" = "0" ]; then echo "PASS: Phase 11X live optional queue_lane claim endpoint smoke passed"; else echo "FAIL: Phase 11X live optional queue_lane claim endpoint smoke failed"; fi

[ "$fail" = "0" ]
