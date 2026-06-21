#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/Desktop/edge-queue-controller}"
PHASE="stage-16-e3z-m-controlled-periodic-timer-activation-plan-no-apply"
DOC="docs/${PHASE}.md"
RUNNER="ops/ppb/ppb-sha256-runner.sh"

cd "$REPO"

echo "=== Stage 16 E3Z-M no-apply plan smoke ==="
echo "MUTATION_SCOPE=read_only_repo_file_validation_only"
echo "NO live infra mutation"
echo "NO DB write"
echo "NO service/timer mutation"
echo "NO helper/model call"

test -s "$DOC"
test -s "$RUNNER"
bash -n "$RUNNER"

grep -q 'Controlled Periodic Timer Activation Plan' "$DOC"
grep -q 'No Apply' "$DOC"
grep -q '/var/lib/edge-queue-controller/edge_queue.sqlite3' "$DOC"
grep -q 'job `34`' "$DOC"
grep -q 'hard no-rerun' "$DOC"
grep -q 'two fresh jobs' "$DOC"
grep -q 'qwen2.5:0.5b' "$DOC"
grep -q 'Frontend → Backend API → Durable Job Queue → Scheduler → Worker/Helper/Adapter → AI Model' "$DOC"
grep -q 'Stage 16 E3Z-N — insert two fresh controlled periodic timer proof jobs only' "$DOC"
grep -q 'ppb_sha256_run' "$DOC"
grep -q 'CHECKSUM_MISMATCH_REFUSING_TO_RUN' "$RUNNER"

if grep -Eq 'systemctl (start|stop|restart|reload|enable|disable|daemon-reload)|sqlite3 .*insert|ollama (run|generate|chat|pull)|curl .*api/(generate|chat|embed)' "$DOC"; then
  echo "NOTE: doc contains command words in explanatory rollback/approval context; no execution in smoke."
fi

echo "E3Z_M_NO_APPLY_PLAN_SMOKE_OK=1"
