#!/usr/bin/env bash
set -euo pipefail

SCRIPT="ops/scheduler/stage-16-e3s-scheduler-dry-run-artifact-no-db-writes.py"
DOC="docs/stage-16-e3s-scheduler-dry-run-artifact-no-db-writes.md"

echo "=== Stage 16 E3S smoke: static artifact safety ==="

test -x "$SCRIPT"
test -s "$DOC"

python3 -m py_compile "$SCRIPT"

grep -F "NO_DB_WRITE" "$SCRIPT"
grep -F "mode=ro&immutable=1" "$SCRIPT"
grep -F "PRAGMA query_only=ON" "$SCRIPT"
grep -F "HELPER_CALL=not_performed" "$SCRIPT"
grep -F "ADAPTER_CALL=not_performed" "$SCRIPT"
grep -F "OPERATOR_DISPATCH_CALL=not_performed" "$SCRIPT"
grep -F "MODEL_CALL=not_performed" "$SCRIPT"
grep -F "SCHEDULER_ACTIVATION=not_performed" "$SCRIPT"
grep -F "PERSISTENT_WORKER_ACTIVATION=not_performed" "$SCRIPT"
grep -F "WOULD_CLAIM" "$SCRIPT"

if grep -Eq 'requests.|urllib.request|http://|https://|curl |ollama |manual-complete|operator-dispatch-one-queued-job|pveso-one-shot|subprocess|os.system|sqlite3 .*INSERT|sqlite3 .*UPDATE|sqlite3 .*DELETE' "$SCRIPT"; then
echo "FORBIDDEN_RUNTIME_OR_WRITE_PATTERN_FOUND"
exit 1
fi

grep -F "Denied:" "$DOC"
grep -F "DB write" "$DOC"
grep -F "model endpoint call" "$DOC"
grep -F "Do not reuse job 27" "$DOC"

echo "E3S_STATIC_SMOKE_OK"
