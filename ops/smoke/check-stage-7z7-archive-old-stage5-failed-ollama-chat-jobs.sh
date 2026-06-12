#!/usr/bin/env bash
set -u

echo "=== Stage 7Z-7 smoke: old Stage 5 failed ollama_chat jobs archived ==="

fail=0
DOC="docs/stage-7z7-archive-old-stage5-failed-ollama-chat-jobs.md"

if [ ! -f "$DOC" ]; then
  echo "FAIL: missing $DOC"
  fail=1
else
  echo "OK: found $DOC"
fi

if grep -q "Archive Old Stage 5 Failed Ollama Chat Jobs" "$DOC"; then
  echo "OK: doc title marker found"
else
  echo "FAIL: doc title marker missing"
  fail=1
fi

if grep -q "ollama_chat_archived" "$DOC"; then
  echo "OK: doc mentions ollama_chat_archived"
else
  echo "FAIL: doc should mention ollama_chat_archived"
  fail=1
fi

if grep -q "status = 'archived'" "$DOC" && grep -q "not allowed" "$DOC"; then
  echo "OK: doc records archived status constraint"
else
  echo "FAIL: doc should record archived status constraint"
  fail=1
fi

echo
echo "=== verify app_jobs counts ==="
.venv/bin/python - <<'PY' | tee /tmp/stage7z7-app-jobs-counts.txt
from edge_modules.chat_queue_persistence import _psql_at

try:
    out = _psql_at("""
    SELECT job_type || E'\t' || status || E'\t' || COUNT(*)::text
    FROM app_jobs
    WHERE job_type IN ('ollama_chat', 'ollama_chat_archived')
    GROUP BY job_type, status
    ORDER BY job_type, status;
    """).strip()
    print(out if out else "(no rows)")
except Exception:
    print("ERROR: failed to read app_jobs counts safely")
PY

grep -q $'ollama_chat\tcomplete\t38' /tmp/stage7z7-app-jobs-counts.txt || fail=1
grep -q $'ollama_chat_archived\tfailed\t5' /tmp/stage7z7-app-jobs-counts.txt || fail=1

if grep -q $'ollama_chat\tfailed' /tmp/stage7z7-app-jobs-counts.txt; then
  echo "FAIL: active ollama_chat should not have failed rows"
  fail=1
else
  echo "OK: active ollama_chat has no failed rows"
fi

echo
echo "=== verify active failed count is zero ==="
.venv/bin/python - <<'PY' | tee /tmp/stage7z7-active-failed-count.txt
from edge_modules.chat_queue_persistence import _psql_at

try:
    active_failed = _psql_at("""
    SELECT COUNT(*)::text
    FROM app_jobs
    WHERE job_type = 'ollama_chat'
      AND status = 'failed';
    """).strip()

    archived_failed = _psql_at("""
    SELECT COUNT(*)::text
    FROM app_jobs
    WHERE job_type = 'ollama_chat_archived'
      AND status = 'failed'
      AND error_text LIKE '%Stage 7Z-7 archived old Stage 5 test failure%';
    """).strip()

    print(f"active_ollama_chat_failed={active_failed}")
    print(f"archived_stage7z7_failed={archived_failed}")
except Exception:
    print("ERROR: failed to verify archive counts safely")
PY

grep -q "active_ollama_chat_failed=0" /tmp/stage7z7-active-failed-count.txt || fail=1
grep -q "archived_stage7z7_failed=5" /tmp/stage7z7-active-failed-count.txt || fail=1

echo
echo "=== verify System queue is clean ==="
curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage7z7-system-status.json
jq '{
  platform: .normalized.platform,
  queue: (.services[]? | select(.id=="queue")),
  ct101_worker: (.services[]? | select(.id=="ct101-laptop-queue-worker"))
}' /tmp/stage7z7-system-status.json

failed_count="$(jq -r '.services[]? | select(.id=="queue") | .queue.failed' /tmp/stage7z7-system-status.json)"
queued_count="$(jq -r '.services[]? | select(.id=="queue") | .queue.queued' /tmp/stage7z7-system-status.json)"
running_count="$(jq -r '.services[]? | select(.id=="queue") | .queue.running' /tmp/stage7z7-system-status.json)"

echo "queue_failed=$failed_count"
echo "queue_queued=$queued_count"
echo "queue_running=$running_count"

if [ "$failed_count" != "0" ] || [ "$queued_count" != "0" ] || [ "$running_count" != "0" ]; then
  echo "FAIL: System queue should be failed 0, queued 0, running 0"
  fail=1
fi

echo
echo "=== verify platform remains online ==="
for id in backend-api frontend-wrapper queue workers ct101-laptop-queue-worker power-automation; do
  state="$(jq -r --arg id "$id" '.normalized.platform[] | select(.id==$id) | .state' /tmp/stage7z7-system-status.json)"
  echo "$id=$state"
  if [ "$state" != "online" ]; then
    echo "FAIL: $id should be online"
    fail=1
  fi
done

echo
echo "=== verify worker registry/remediation remain clean ==="
curl -sS --max-time 20 http://127.0.0.1:7070/workers/registry \
  | tee /tmp/stage7z7-workers-registry.json \
  | jq '.summary'

registry_total="$(jq -r '.summary.total // empty' /tmp/stage7z7-workers-registry.json)"
registry_unhealthy="$(jq -r '.summary.unhealthy // empty' /tmp/stage7z7-workers-registry.json)"

if [ "$registry_total" != "0" ] || [ "$registry_unhealthy" != "0" ]; then
  echo "FAIL: legacy worker registry should remain clean"
  fail=1
fi

curl -sS --max-time 20 -X POST http://127.0.0.1:7070/workers/remediation/tick \
  | tee /tmp/stage7z7-remediation.json \
  | jq '{ok, dry_run, worker_count, actions}'

worker_count="$(jq -r '.worker_count // empty' /tmp/stage7z7-remediation.json)"
if [ "$worker_count" != "0" ]; then
  echo "FAIL: remediation should see zero legacy workers"
  fail=1
fi

echo
echo "=== verify health and timer safety ==="
curl -sS --max-time 10 http://127.0.0.1:7070/health | jq .
echo "legacy_enabled=$(systemctl is-enabled edge-queue-scheduler-tick.timer || true)"
echo "legacy_active=$(systemctl is-active edge-queue-scheduler-tick.timer || true)"
echo "power_auto_active=$(systemctl is-active edge-queue-power-auto-tick.timer || true)"
echo "remediation_active=$(systemctl is-active edge-queue-remediation-tick.timer || true)"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 7Z-7 old Stage 5 failed jobs archived and queue is clean"
else
  echo "FAIL: Stage 7Z-7 smoke found an issue"
fi

echo
echo "=== final repo status ==="
git status --short
